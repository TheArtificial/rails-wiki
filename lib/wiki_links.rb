class Gollum::Filter::WikiLinks < Gollum::Filter
  # include RailsWiki::Engine.routes.url_helpers
  # include ActionView::Helpers::UrlHelper

  # replace [/path] with [/prefix/path]
  def extract(data)
    this_page = Rails.configuration.wiki.find_page(@markup.page.url_path)

    data.gsub(/\[(.+?)\][^\(]/) do
      path = $1.gsub(/\s/, '-')
      page = this_page.relative_page(path)

      if page.nil? || page.new_page?
        "[<a href=\"#{Wiki::Engine.routes.url_helpers.new_page_path(page)}\">create #{path}</a>]"
      else
        "<a href=\"#{Wiki::Engine.routes.url_helpers.page_path(page)}\">#{page.title}</a>"
      end
    end
  end

  # passthrough
  def process(data)
    data
  end

end
