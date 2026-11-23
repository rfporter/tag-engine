package lvrsrc;
# Minimal reader for LabVIEW resource files (.vi, .vim, .ctl).
# Returns the VI description, which LabVIEW stores uncompressed in the STRG block.
use strict; use warnings;
use Encode qw(decode);

sub read_description {
    my ($path) = @_;
    my $blk = read_block($path, 'STRG');
    # Block data: u32 block size, then u32 string length, then the string.
    return '' unless defined $blk && length($blk) >= 8;
    my $len = unpack('N', substr($blk, 4, 4));
    my $s = substr($blk, 8, $len);
    $s = decode('cp1252', $s);
    $s =~ s/\r\n?/\n/g;
    $s =~ s/\s+\z//;
    return $s;
}

# Returns the raw data of the first section of the named block, or undef.
sub read_block {
    my ($path, $want) = @_;
    open my $h, '<:raw', $path or die "Cannot read $path: $!\n";
    local $/; my $f = <$h>; close $h;
    die "$path is not a LabVIEW resource file\n" unless substr($f, 0, 4) eq 'RSRC';
    my ($info_off, $info_size, $data_off, $data_size) = unpack('N4', substr($f, 16, 16));
    # Block-info list header follows the copy of the file header at $info_off.
    my $lh = $info_off + 32;
    my ($blockinfo_off) = unpack('N', substr($f, $lh + 12, 4));
    my $bi = $info_off + $blockinfo_off;
    my $nblocks = unpack('N', substr($f, $bi, 4)) + 1;
    for my $b (0 .. $nblocks - 1) {
        my $e = $bi + 4 + $b * 12;
        my ($ident, $nsec, $sec_off) = unpack('a4 N N', substr($f, $e, 12));
        next unless $ident eq $want;
        my $s = $bi + $sec_off;                    # first section start
        my (undef, undef, undef, $doff) = unpack('N4', substr($f, $s, 16));
        my $d = $data_off + $doff;
        my $size = unpack('N', substr($f, $d, 4));
        return substr($f, $d, 4 + $size);
    }
    return undef;
}

1;
