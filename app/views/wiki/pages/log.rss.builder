#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Recent Updates"
    # xml.author "Name"
    xml.description "Recently changed pages"
    xml.link root_url
    # xml.language "en"

    @updates.each do |update|
      path = update[:path]
      page = update[:page]
      commit = update[:commit]
      date = update[:date]
      author_name = update[:author_name]
      author_email = update[:author_email]
      message = update[:message]
      desc = "#{author_name} #{message}"
      xml.item do
        xml.title page.path
        xml.author "#{author_email} (#{author_name})"
        xml.pubDate date.rfc822
        if page.present?
          if page.new_page?
            xml.link page_url(page.parent_path)
          else
            xml.link page_url(page)
          end
        end
        xml.guid page_url(path)
        xml.description "<p>" + desc + "</p>"
      end
    end
  end
end
