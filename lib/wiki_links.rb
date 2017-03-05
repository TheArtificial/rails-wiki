class Gollum::Filter::WikiLinks < Gollum::Filter
  # include RailsWiki::Engine.routes.url_helpers
  # include ActionView::Helpers::UrlHelper

  # replace [/path] with [/prefix/path]
  def extract(data)
    wiki = Rails.configuration.wiki
    this_page = Rails.configuration.wiki.find_page(@markup.page.url_path)
    context_path = this_page.path

    data.gsub(/\[(.+?)\][^\(]/) do
      path = $1
      if path.starts_with?('/')
        resolved_path = path[1..-1]
      else
        resolved_path = context_path + '/' + path
      end
      page = wiki.find_page(resolved_path)
      if page.nil? || page.new_page?
        "[<a href=\"#{Wiki::Engine.routes.url_helpers.new_page_path(resolved_path)}\">create #{path}</a>]"
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
