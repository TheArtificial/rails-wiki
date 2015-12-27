class Gollum::Filter::Frontmatter < Gollum::Filter

  # replaces the library's weird syntax with traditional YAML frontmatter
  def extract(data)

    data.gsub(/\A---\s*$(.*)^---\s*$\n?/m) do
      yaml = $1
      hash = YAML.load(yaml)
      @markup.metadata ||= {}
      if Hash === hash
        @markup.metadata.update(hash)
      end

      '' #replace with nothing
    end
  end

  # passthrough
  def process(data)
    data
  end

end
