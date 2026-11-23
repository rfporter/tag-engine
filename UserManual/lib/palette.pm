package palette;
# Reads the Functions palette definition from a VIPM build file (.vipb).
# Returns a list of palettes: { index, name, parent, items => [ { type, name, short, path, sub, row, col } ] }
# Items are sorted by palette position (row, then column).
use strict; use warnings;

sub read_palettes {
    my ($vipb) = @_;
    open my $h, '<', $vipb or die "Cannot read $vipb: $!\n";
    local $/; my $x = <$h>; close $h;
    my ($def) = $x =~ m{<Library_Palette_Definition>(.*?)</Library_Palette_Definition>}s
        or die "No <Library_Palette_Definition> in $vipb\n";
    my @pal; my $i = 0;
    while ($def =~ m{<Functions_Palette_Data>(.*?)</Functions_Palette_Data>}sg) {
        my $p = $1;
        my %pal = (index => $i++, parent => tag($p, 'Parent_Palette_Index'), name => tag($p, 'Name'), items => []);
        while ($p =~ m{<Items_Data>(.*?)</Items_Data>}sg) {
            my $it = $1;
            push @{ $pal{items} }, {
                type => tag($it, 'Type'),
                name => tag($it, 'NameSub_Menu_Name'),
                short => tag($it, 'Short_Name') // '',
                path => tag($it, 'Path'),
                sub  => tag($it, 'Sub_Palette_Index'),
                row  => tag($it, 'Row') // 0,
                col  => tag($it, 'Column') // 0,
            };
        }
        @{ $pal{items} } = sort { $a->{row} <=> $b->{row} || $a->{col} <=> $b->{col} } @{ $pal{items} };
        push @pal, \%pal;
    }
    return @pal;
}

sub tag {
    my ($s, $t) = @_;
    return '' if $s =~ m{<$t/>};
    my ($v) = $s =~ m{<$t>(.*?)</$t>}s;
    return undef unless defined $v;
    $v =~ s/&lt;/</g; $v =~ s/&gt;/>/g; $v =~ s/&quot;/"/g; $v =~ s/&apos;/'/g; $v =~ s/&amp;/&/g;
    return $v;
}

1;
