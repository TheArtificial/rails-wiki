module Wiki
  module WikiHelper
    def wiki_updates(options)
      # path: parent path
      # limit: max updates
      render partial: 'wiki/updates', locals: {updates: Rails.configuration.wiki.recent_updates(options)}
    end
  end
end
