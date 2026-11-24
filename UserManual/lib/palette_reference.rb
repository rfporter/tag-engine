# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/extensions'
require_relative 'lv_files'
require_relative 'lv_resource'

# Generates the palette reference: one chapter per palette of a .vipb, with an overview
# table and one section per item. VI text is wrapped in pass:c[] so AsciiDoc never treats
# it as markup.
#
# The palette names VIs by their path in the Source Distribution build. The build keeps the
# project's folder layout, so each VI is read from the same relative path in the project
# folder, and the manual can be generated before the build.
class PaletteReference
  include Asciidoctor::Logging

  def initialize(vipb_path, project_dir, images_dir)
    @vipb = LvFiles::Vipb.new(vipb_path)
    @project = File.expand_path(project_dir)
    @images = images_dir
    @owners = LvFiles::Owners.new(@project)
    @vis_by_name = Dir.glob('**/*.{vi,vim,ctl}', base: @project)
                      .reject { |rel| rel.start_with?('Antidoc-Output/') }
                      .group_by { |rel| File.basename(rel).downcase }
    @project_paths = {}
  end

  def lines
    out = []
    out.concat(chapter(@vipb.top, "#{@vipb.product} Palette", top: true))
    @vipb.top.items.select(&:subpalette?).each do |it|
      out.concat(chapter(@vipb.subpalette(it), "#{it.name} Palette"))
    end
    out
  end

  private

  def chapter(palette, title, top: false)
    l = ["[[#{anchor('palette', title)}]]", "== #{title}", '']
    l << if top
           "The *#{@vipb.product}* palette is in menu:Functions[Addons > #{@vipb.product}]. " \
             'It holds the VIs most applications need. The subpalettes hold the rest.'
         else
           "The *#{title}* is a subpalette of the #{@vipb.product} palette."
         end
    l << ''
    l.concat(overview(palette, title))
    palette.items.reject(&:subpalette?).each do |it|
      l.concat(it.builtin? ? property_node(title, it) : vi_section(title, it))
    end
    l
  end

  def overview(palette, title)
    l = ['[cols="1,2",options="header"]', '|===', '|Item |Summary', '']
    palette.items.each do |it|
      if it.subpalette?
        sub = @vipb.subpalette(it)
        names = sub.items.reject(&:subpalette?).map(&:title).join(', ')
        l << "|<<#{anchor('palette', "#{it.name} Palette")},#{it.name}>> (subpalette)" << "|#{cell(names)}"
      elsif it.builtin?
        l << "|<<#{anchor('vi', title, it.title)},#{it.title}>>" << '|Reads and writes Tag properties through a Tag reference.'
      else
        l << "|<<#{anchor('vi', title, it.name)},#{it.title}>>" << "|#{cell(first_sentence(description(it)))}"
      end
      l << ''
    end
    l << '|===' << ''
  end

  def vi_section(title, it)
    path = project_path(it)
    chain = path ? @owners.chain(path) : []
    l = ["[[#{anchor('vi', title, it.name)}]]", "=== #{it.title}", '']
    image = File.join(@images, (chain + [it.name]).join('-') + '.png')
    if File.exist?(image)
      l << "image::#{image}[#{it.title}]" << ''
    else
      logger.warn "palette reference: no connector pane image for #{it.name} (#{image}). " \
                  'Generate the Antidoc project docs first.'
    end
    l.concat(paragraphs(description(it)))
    qualified = (chain + [it.name]).join(':')
    rel = path ? path.delete_prefix("#{@project}/") : it.name
    l << "[.small]#_#{pass(qualified)}_ (#{pass(rel)})#" << ''
  end

  # The project file for a palette item: the same path relative to the Source Distribution
  # folder, or else the only VI in the project with that name.
  def project_path(it)
    @project_paths.fetch(it.path) do
      rel = it.path.delete_prefix("#{@vipb.source_folder}/")
      path = File.join(@project, rel)
      unless File.exist?(path)
        matches = @vis_by_name[it.name.downcase] || []
        path = matches.size == 1 ? File.join(@project, matches.first) : nil
        logger.warn "palette reference: #{it.name} not found in #{@project}" if matches.empty?
        logger.warn "palette reference: #{it.name} is ambiguous: #{matches.join(', ')}" if matches.size > 1
      end
      @project_paths[it.path] = path
    end
  end

  # LabVIEW's Property Node on the palette: list the Tag class properties.
  def property_node(title, it)
    l = ["[[#{anchor('vi', title, it.title)}]]", "=== #{it.title}", '',
         "LabVIEW's Property Node, placed on this palette for use with Tags. Wire a Tag reference " \
         '(from New Tag or Get Tag) to it to read or write these Tag properties directly:', '']
    cls = File.join(@project, 'Tag', 'Tag.lvclass')
    unless File.exist?(cls)
      logger.warn "palette reference: #{cls} not found"
      return l
    end
    l.push('[cols="2,1,1,5",options="header"]', '|===', '|Property |Read |Write |Description', '')
    LvFiles.class_properties(cls).each do |p|
      text = [p.read, p.write].compact.map { |vi| first_sentence(LvResource.description(vi)) }.find { |s| !s.empty? }
      l << "|#{p.name} |#{p.read ? 'Yes' : ''} |#{p.write ? 'Yes' : ''} |#{cell(text.to_s)}"
    end
    l << '|===' << ''
  end

  # A VI description as AsciiDoc: "- item" lines become lists, lines that each end a sentence
  # keep their line breaks, and lines wrapped mid-sentence are joined.
  def paragraphs(desc)
    if desc.empty?
      logger.warn 'palette reference: a palette VI has no description'
      return ['_No description._', '']
    end
    out = []
    desc.split(/\n\s*\n/).each do |para|
      text = []
      list = []
      flush_text = lambda do
        next if text.empty?

        sentences = text.all? { |t| t =~ /[.:!?)]\s*\z/ }
        out << (text.size > 1 && sentences ? text.map { |t| pass(t) }.join(" +\n") : pass(text.join(' '))) << ''
        text = []
      end
      flush_list = lambda do
        next if list.empty?

        out.concat(list.map { |t| "* #{pass(t)}" }) << ''
        list = []
      end
      para.each_line(chomp: true) do |line|
        if (m = line.match(/\A\s*[-*]\s+(.*)\z/))
          flush_text.call
          list << m[1]
        else
          flush_list.call
          text << line.strip
        end
      end
      flush_text.call
      flush_list.call
    end
    out
  end

  def description(it)
    path = project_path(it)
    path ? LvResource.description(path) : ''
  end

  def first_sentence(desc)
    para = desc.split(/\n\s*\n/).first.to_s.gsub(/\s*\n\s*/, ' ')
    para[/\A.*?[.!?](?=\s|\z)/] || para
  end

  # Text passed through with only <, > and & escaped.
  def pass(text) = text.empty? ? '' : "pass:c[#{text.gsub(']', '\]')}]"

  # Table cell text: the table parser splits on | before inline macros run.
  def cell(text) = pass(text).gsub('|', '\|')

  def anchor(*parts) = parts.join(' ').downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
end

# include::palette:<path to .vipb>[] inserts the palette reference.
class PaletteReferenceInclude < Asciidoctor::Extensions::IncludeProcessor
  def handles?(*args) = args.last.to_s.start_with?('palette:')

  def process(doc, reader, target, attributes)
    vipb = target.delete_prefix('palette:')
    images = doc.attr('connector-pane-images') or raise 'Set the connector-pane-images attribute'
    project = doc.attr('project-dir') || File.dirname(vipb)
    lines = PaletteReference.new(vipb, project, images).lines
    reader.push_include(lines, vipb, target, 1, attributes)
  end
end
