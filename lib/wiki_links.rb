class Gollum::Filter::WikiLinks < Gollum::Filter
  # include RailsWiki::Engine.routes.url_helpers
  # include ActionView::Helpers::UrlHelper

  # process [[page/path]] into proper links
  def extract(data)
    this_page = Rails.configuration.wiki.find_page(@markup.page.url_path)

    data.gsub(/\[\[(.+?)\]\]/) do
      path = $1.gsub(/\s/, '-')
      begin
        page = this_page.relative_page(path)

        if page.new_page?
          "[<a href=\"#{Wiki::Engine.routes.url_helpers.new_page_path(page)}\" class=\"wikilink new\">create #{path}</a>]"
        else
          "<a href=\"#{Wiki::Engine.routes.url_helpers.page_path(page)}\" class=\"wikilink new\">#{page.title}</a>"
        end
      rescue Wiki::PageError => e
        "[[<a href=\"#{Wiki::Engine.routes.url_helpers.new_page_path(path)}\" class=\"wikilink error\" title=\"#{e.message}\">#{path}</a>]]"
      end
    end
  end

  # passthrough
  def process(data)
    data
  end

end
