#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Recent Updates"
    # xml.author "Name"
    xml.description "Recently changed pages"
    xml.link root_url
    # xml.language "en"

    @changes_by_path.each do |change_path|
      path = change_path[0]
      first_commit = change_path[1].first
      page = first_commit[:page]
      commit = first_commit[:commit]
      desc = "#{commit.author.name} #{commit.message}"
      xml.item do
        xml.title page.path
        xml.author "#{commit.author.email} (#{commit.author.name})"
        xml.pubDate commit.authored_date.rfc822
        if page.present?
          if page.new_page?
            xml.link page_url(page.parent_path)
          else
            xml.link page_url(page)
          end
        end
        xml.guid page_url(page.path)
        xml.description "<p>" + desc + "</p>"
      end
    end
  end
end
