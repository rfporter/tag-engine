# frozen_string_literal: true

require 'rexml/document'

# Readers for the XML files LabVIEW and VIPM write: .vipb, .lvproj, .lvlib, .lvclass.
module LvFiles
  module_function

  def xml(path)
    REXML::Document.new(File.read(path, mode: 'rb:BOM|UTF-8'))
  end

  # LabVIEW member URLs are relative to the owner file, as if it were a folder.
  def resolve_url(owner, url)
    File.expand_path(url, owner)
  end

  # Version of a build specification in a .lvproj, e.g. "2.2.0.2". Unset parts count as 0.
  def build_version(lvproj, spec_type = 'Source Distribution')
    spec = xml(lvproj).elements["//Item[@Type='#{spec_type}']"] or return '0.0.0.0'
    parts = %w[major minor patch build].map do |p|
      spec.elements["Property[@Name='Bld_version.#{p}']"]&.text.to_i
    end
    parts.join('.')
  end

  # The functions palette of a VIPM build file (.vipb).
  class Vipb
    Palette = Struct.new(:index, :name, :parent, :items)
    Item = Struct.new(:type, :name, :short, :path, :sub, :row, :col) do
      def subpalette? = type == 'Sub Palette'
      def builtin? = name.start_with?('BUILT_IN_FUNC_')
      def title = builtin? ? short : name.sub(/\.(vi|vim|ctl)\z/i, '')
    end

    attr_reader :path, :product, :source_folder, :palettes

    def initialize(path)
      @path = File.expand_path(path)
      doc = LvFiles.xml(@path)
      dir = File.dirname(@path)
      @product = doc.elements['//Product_Name']&.text || File.basename(@path, '.vipb')
      src = doc.elements['//Library_Source_Folder']&.text or raise "No Library_Source_Folder in #{@path}"
      @source_folder = File.expand_path(src.tr('\\', '/'), dir)
      @palettes = read_palettes(doc, dir)
    end

    def top = @palettes.find { |p| p.parent == -1 }

    def subpalette(item) = @palettes[item.sub]

    private

    def read_palettes(doc, dir)
      defn = doc.elements['//Library_Palette_Definition'] or raise "No palette definition in #{@path}"
      defn.get_elements('Functions_Palette_Data').each_with_index.map do |p, i|
        items = p.get_elements('Items_Data').map do |it|
          path = it.elements['Path']&.text
          Item.new(it.elements['Type']&.text, it.elements['NameSub_Menu_Name']&.text.to_s,
                   it.elements['Short_Name']&.text.to_s,
                   path && File.expand_path(path.tr('\\', '/'), dir),
                   it.elements['Sub_Palette_Index']&.text.to_i,
                   it.elements['.//Row']&.text.to_i, it.elements['.//Column']&.text.to_i)
        end
        Palette.new(i, p.elements['Name']&.text.to_s, p.elements['Parent_Palette_Index']&.text.to_i,
                    items.sort_by { |it| [it.row, it.col] })
      end
    end
  end

  # Maps each VI in a folder to the chain of libraries and classes that own it.
  class Owners
    def initialize(dir)
      @member_of = {}
      Dir.glob('**/*.{lvlib,lvclass}', base: dir).each do |rel|
        owner = File.join(dir, rel)
        LvFiles.xml(owner).each_element("//Item[@URL]") do |item|
          next unless %w[VI LVClass Library].include?(item.attributes['Type'])

          url = item.attributes['URL']
          next if url.start_with?('/')   # <vilib> and other absolute links

          @member_of[key(LvFiles.resolve_url(owner, url))] = owner
        end
      end
    end

    # e.g. ["Tag Engine.lvlib"] or ["Tag Engine Core.lvlib", "Tag Core.lvclass"]
    def chain(path)
      chain = []
      owner = @member_of[key(path)]
      while owner
        chain.unshift(File.basename(owner))
        owner = @member_of[key(owner)]
      end
      chain
    end

    private

    def key(path) = File.expand_path(path).downcase
  end

  Property = Struct.new(:name, :read, :write)

  # Property definitions of a class: name, read and write accessor paths.
  def class_properties(lvclass)
    xml(lvclass).get_elements("//Item[@Type='Property Definition']").map do |pd|
      vis = pd.get_elements("Item[@Type='VI']")
      find = ->(prefix) do
        vi = vis.find { |v| v.attributes['Name'].start_with?(prefix) }
        vi && resolve_url(lvclass, vi.attributes['URL'])
      end
      Property.new(pd.attributes['Name'], find.('Read '), find.('Write '))
    end
  end
end
