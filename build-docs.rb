# frozen_string_literal: true

# Builds all Tag Engine documentation, in order:
#   1. the Antidoc project docs (Antidoc-Output/, HTML and PDF) through G-CLI,
#   2. the user manual (UserManual/Tag Engine User Manual.pdf), which uses the connector pane
#      images from step 1.
#
#   "%LOCALAPPDATA%\Asciidoc For LabVIEW\RubyInstance\bin\ruby.exe" build-docs.rb [options]
#
# or build-docs.cmd, which finds that Ruby. Options: --help.
#
# Needs LabVIEW 2020 with Antidoc, its CLI add-on and AsciiDoc for LabVIEW, and G-CLI.
# Close Tag Engine.lvproj in LabVIEW first: Antidoc reads an open project from memory.

require 'optparse'
require 'date'
require 'rbconfig'
require_relative 'UserManual/lib/lv_files'

$stdout.sync = true
ROOT = __dir__
opts = { lv_ver: '2020', formats: %w[html pdf], antidoc: true, manual: true }
OptionParser.new do |o|
  o.banner = 'Usage: build-docs.rb [options]'
  o.on('--only-antidoc', 'Build only the Antidoc project docs') { opts[:manual] = false }
  o.on('--only-manual', 'Build only the user manual') { opts[:antidoc] = false }
  o.on('--formats LIST', Array, 'Antidoc formats, e.g. html,pdf (default: both)') { |v| opts[:formats] = v }
  o.on('--lv-ver VERSION', 'LabVIEW version for G-CLI (default: 2020)') { |v| opts[:lv_ver] = v }
end.parse!

def win(path) = File.expand_path(path, ROOT).tr('/', '\\')

def gcli
  path = ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).map { |d| File.join(d, 'g-cli.exe') }.find { |f| File.exist?(f) }
  path || 'C:/Program Files/G-CLI/bin/g-cli.exe'
end

# Antidoc renders with the Asciidoctor of AsciiDoc for LabVIEW, which it runs by name from that
# Ruby's folder. cmd only finds it there if NoDefaultCurrentDirectoryInExePath is unset in the
# LabVIEW that G-CLI starts.
CLEAN_ENV = { 'NoDefaultCurrentDirectoryInExePath' => nil }.freeze

def check_antidoc_ini
  ini = File.join(Dir.home, 'Documents', 'LabVIEW Data', 'Antidoc', 'Antidoc.ini')
  text = File.exist?(ini) ? File.read(ini) : ''
  missing = %w[version-label author revremark!].reject { |k| text.include?("#{k}=") }
  return if missing.empty?

  warn "Warning: #{ini} lacks #{missing.join(', ')}; the cover will show Antidoc's defaults. See CLAUDE.md."
end

def antidoc(format, version, lv_ver)
  args = [gcli, '--lv-ver', lv_ver, 'antidoc', '--',
          '-addon', 'lvproj', '-pp', win('Tag Engine.lvproj'), '-t', 'Tag Engine', '-a', 'Ryan Porter',
          '-configpath', win('antidoc.config'), '-out', win('Antidoc-Output'),
          '-commit', version, '-commitdate', Date.today.iso8601, '-render', format, '-close']
  puts "== Antidoc #{format}"
  output = +''
  IO.popen(CLEAN_ENV, args, err: %i[child out]) do |io|
    io.each_line do |line|
      print line
      output << line
    end
  end
  # G-CLI can finish with status 0 after an Antidoc error, so check the output too.
  failed = !$?.success? || output.match?(/Error At Exit|Error \d+ occurred/) || !output.include?('Rendering done')
  abort "Antidoc #{format} failed." if failed
end

version = LvFiles.build_version(File.join(ROOT, 'Tag Engine.lvproj'))
puts "Version: #{version}"

if opts[:antidoc]
  check_antidoc_ini
  opts[:formats].each { |f| antidoc(f, version, opts[:lv_ver]) }
end

if opts[:manual]
  puts '== User manual'
  ruby = File.join(ENV.fetch('LOCALAPPDATA', ''), 'Asciidoc For LabVIEW', 'RubyInstance', 'bin', 'ruby.exe')
  ruby = RbConfig.ruby unless File.exist?(ruby)
  system(ruby, File.join(ROOT, 'UserManual', 'build-manual.rb'), '--version', version) or abort 'User manual failed.'
end

puts 'Docs built.'
