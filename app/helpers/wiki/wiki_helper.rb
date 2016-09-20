module Wiki
  module WikiHelper
    def wiki_updates(options)
      # path: parent path
      # limit: max updates
      render partial: 'wiki/updates', locals: {updates: Rails.configuration.wiki.recent_updates(options), options: options}
    end

    def wiki_link(path)
      page = Rails.configuration.wiki.find_page(path)
      if page.new_page?
        return path
      else
        return link_to page.name, wiki.page_path(page)
      end
    end
  end
end
