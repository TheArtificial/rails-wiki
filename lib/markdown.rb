require 'redcarpet'

class Gollum::Filter::Markdown < Gollum::Filter

  # basic redcarpet render
  def extract(data)
    Redcarpet::Markdown.new(Redcarpet::Render::SmartyHTML.new(
        no_styles: true,
        with_toc_data: true,
        hard_wrap: true
      ), {
      no_intra_emphasis: true,
      tables: true,
      autolink: true,
      footnotes: true
    }).render(data)
  end

  # passthrough
  def process(data)
    data
  end

end
