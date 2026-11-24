# frozen_string_literal: true

# Builds the Tag Engine user manual from the project folder.
#
# Run with the Ruby that AsciiDoc for LabVIEW installs (it has Asciidoctor and Asciidoctor PDF):
#
#   "%LOCALAPPDATA%\Asciidoc For LabVIEW\RubyInstance\bin\ruby.exe" UserManual\build-manual.rb
#
# or with UserManual\build-manual.cmd, which finds that Ruby. Options: --help.
#
# The palette comes from Tag Engine.vipb; the VIs are read from the project folder, so no
# Source Distribution build is needed. Run it after the Antidoc project docs, whose connector
# pane images (Antidoc-Output/Images) the palette reference uses.

require 'optparse'
require 'fileutils'
require 'date'
require 'asciidoctor'
require_relative 'lib/lv_files'
require_relative 'lib/palette_reference'

root = File.expand_path('..', __dir__)
opts = {
  vipb: File.join(root, 'Tag Engine.vipb'),
  lvproj: File.join(root, 'Tag Engine.lvproj'),
  images: File.join(root, 'Antidoc-Output', 'Images'),
  main: File.join(__dir__, 'src', 'Tag Engine User Manual.adoc'),
  render: 'pdf'
}
OptionParser.new do |o|
  o.banner = 'Usage: build-manual.rb [options]'
  o.on('--render FORMAT', %w[pdf html none], 'pdf (default), html, or none (check only)') { |v| opts[:render] = v }
  o.on('--out DIR', 'Output folder (default: UserManual)') { |v| opts[:out] = v }
  o.on('--version X.Y.Z.W', 'Version on the cover (default: the Source Distribution build version)') { |v| opts[:version] = v }
  o.on('--vipb PATH', 'VIPM build file with the palette') { |v| opts[:vipb] = v }
  o.on('--lvproj PATH', 'Project with the Source Distribution build spec') { |v| opts[:lvproj] = v }
  o.on('--images DIR', 'Antidoc images folder with the connector pane images') { |v| opts[:images] = v }
end.parse!

vipb = LvFiles::Vipb.new(opts[:vipb])
abort "Connector pane images not found: #{opts[:images]}\nGenerate the Antidoc project docs first." unless Dir.exist?(opts[:images])
version = opts[:version] || LvFiles.build_version(opts[:lvproj])
out = File.expand_path(opts[:out] || __dir__)

puts "Project: #{root}", "Output:  #{out}", "Version: #{version}"

logger = Asciidoctor::Logger.new($stderr)
logger.level = Logger::WARN
Asciidoctor::LoggerManager.logger = logger
Asciidoctor::Extensions.register { include_processor PaletteReferenceInclude }

attributes = {
  'revnumber' => version,
  'version-label' => 'Version',
  'revdate' => Date.today.iso8601,
  'vipb' => vipb.path,
  'project-dir' => root,
  'connector-pane-images' => File.expand_path(opts[:images]),
  'attribute-missing' => 'warn'
}

case opts[:render]
when 'none'
  Asciidoctor.load_file(opts[:main], safe: :unsafe, attributes: attributes)
  puts 'Checked (nothing rendered).'
when 'pdf'
  require 'asciidoctor-pdf'
  Asciidoctor.convert_file(opts[:main], backend: 'pdf', safe: :unsafe, to_dir: out, mkdirs: true,
                                        attributes: attributes)
  puts "Wrote #{File.join(out, File.basename(opts[:main], '.adoc') + '.pdf')}"
when 'html'
  Asciidoctor.convert_file(opts[:main], backend: 'html5', safe: :unsafe, to_dir: out, mkdirs: true,
                                        attributes: attributes.merge('data-uri' => ''))
  puts "Wrote #{File.join(out, File.basename(opts[:main], '.adoc') + '.html')}"
end

if logger.max_severity && logger.max_severity >= Logger::WARN
  warn 'Finished with warnings (see above).'
  exit 1
end
