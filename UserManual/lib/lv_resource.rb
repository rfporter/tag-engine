# frozen_string_literal: true

# Reads data from LabVIEW resource files (.vi, .vim, .ctl) without LabVIEW.
module LvResource
  module_function

  # The VI description. LabVIEW stores it uncompressed in the STRG block:
  # u32 block size, u32 string length, then the string (Windows-1252).
  def description(path)
    data = block(path, 'STRG')
    return '' unless data && data.bytesize >= 8

    len = data.byteslice(4, 4).unpack1('N')
    text = data.byteslice(8, len).force_encoding('Windows-1252').encode('UTF-8')
    text.gsub(/\r\n?/, "\n").rstrip
  end

  # The raw data (size prefix included) of the first section of the named block, or nil.
  def block(path, ident)
    f = File.binread(path)
    raise "#{path} is not a LabVIEW resource file" unless f.start_with?('RSRC')

    info_off, _info_size, data_off, _data_size = f.byteslice(16, 16).unpack('N4')
    # The block-info list header follows a copy of the file header at info_off.
    blockinfo_off = f.byteslice(info_off + 32 + 12, 4).unpack1('N')
    bi = info_off + blockinfo_off
    count = f.byteslice(bi, 4).unpack1('N') + 1
    count.times do |i|
      name, _sections, sec_off = f.byteslice(bi + 4 + i * 12, 12).unpack('a4NN')
      next unless name == ident

      doff = f.byteslice(bi + sec_off + 12, 4).unpack1('N')   # 4th field of the section start
      start = data_off + doff
      size = f.byteslice(start, 4).unpack1('N')
      return f.byteslice(start, 4 + size)
    end
    nil
  end
end
