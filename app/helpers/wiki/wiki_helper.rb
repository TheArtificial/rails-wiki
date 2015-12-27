module Wiki
  module WikiHelper
    def wiki_changes(max=10)
      changes = Rails.configuration.wiki.changelog.first(max)
      "<ol>#{render partial: "wiki/change", collection: changes}</ol>".html_safe
    end
  end
end
