# require 'active_model'

module Wiki
class Wiki
  # a gollum wiki facade

  # unloadable

  def gollum_wiki
    return @gollum_wiki
  end

  def initialize(params={})
    @gollum_wiki = params[:gollum_wiki]
    @upstream = params[:upstream]
    @history_url = params[:history_url] || "#not-on-github/"
  end

  def history_url
    @history_url
  end

  def refresh
    @gollum_wiki.clear_cache
  end

  def search(query)
    results = @gollum_wiki.search(query)
    pages = results.sort_by{ |h| h[:count] }.map{ |h| Page.new(wiki: self, path: h[:name]) }
  end

  def search_tags(tag, options={})
    regex = /\A---\s*$.*^tags:\s*\[.*\b(#{Regexp.escape(tag)})\b.*\].*^---\s*$/m
    search_regex(regex, options)
  end

  def changelog(path=nil, max=100)
    log = []
    # this is more gollum proper, but we can't set the path
    # commits = @gollum_wiki.latest_changes(max_count: max)
    ref = @gollum_wiki.ref # probably 'master'
    commits = @gollum_wiki.repo.log(ref, path, {max_count: max})
    commits.each do |c|
      c.stats.files.each do |f|
        path = f[0]
        if File.extname(path) == '.md'
          Rails.logger.debug "--- adding to log: #{path} "
          path.chomp!('.md')
          log << {path: path, page: Page.new(wiki: self, path: path), commit: c}
        end
      end
    end
    return log
  end

  def create_page(path)
    page = Page.new(wiki: self, path: path)
    if page.new_page?
      if page.parent_path.blank?
        # page is at root
        if path.starts_with?('_')
          raise Exception.new("Root page names cannot begin with \"_\"")
        else
          return page
        end
      else
        # page should have parents
        parent_page = Page.new(wiki: self, path: page.parent_path)
        if parent_page.new_page?
          raise Exception.new("Cannot create orphan page at #{path}")
        else
          return page
        end
      end
    else
      raise Exception.new("Page already exists at #{path}")
    end
  end

  def find_page(path)
    page = Page.new(wiki: self, path: path)
    if page.new_page?
      Rails.logger.info("rails-wiki: new page #{path}")
      if page.parent_path.blank?
        # page is at root
        if path.starts_with?('_')
          raise Exception.new("Root page names cannot begin with \"_\"")
        else
          return page
        end
      else
        # page should have parents
        parent_page = Page.new(wiki: self, path: page.parent_path)
        if parent_page.new_page?
          Rails.logger.info("rails-wiki: parent is also new #{page.parent_path}")
          return nil
        else
          return page
        end
      end
    else
      return page
    end
  end

  def find_attachment(path, extension)
    # ::Wiki::Attachment.new(wiki: self, path: path+extension)
    # try_on_disk must be false, or the gollum_file will not populate its blob and thus have no mime_type
    gollum_file = @gollum_wiki.file(path+extension, @gollum_wiki.ref, false)
    return Attachment.new(wiki: self, gollum_file: gollum_file)
  end

  def base_path
    # up a directory from the .git repo
    File.join(@gollum_wiki.repo.path, '..')
  end

  def home_page
    Page.new(wiki: self, path: @gollum_wiki.index_page)
  end

  def top_pages
    @gollum_wiki.pages
      .select{|gp| (File.dirname(gp.url_path) == '.') && (gp.url_path != @gollum_wiki.index_page) }
      .sort_by{|gp| gp.name }
      .map{|gp| Page.new(wiki: self, gollum_page: gp)}
  end

  def all_pages
    @gollum_wiki.pages.map{|gp| Page.new(wiki: self, gollum_page: gp)}
  end

  def pages_under_path(parent_path='')
    child_pages = @gollum_wiki.pages.select { |p| File.dirname(p.path) == parent_path }
    return child_pages.map{|gp| Page.new(wiki: self, gollum_page: gp)}
  end

  def files_under_path(parent_path='')
    child_files = @gollum_wiki.files.select { |f| File.dirname(f.path) == parent_path }
    return child_files.map{|f| Attachment.new(wiki: self, gollum_file: f)}
  end

  def search_regex(regex, options)
    ref = options[:ref] ? options[:ref] : "HEAD"
    tree = @gollum_wiki.repo.git.lookup(@gollum_wiki.repo.git.sha_from_ref(ref)).tree
    # tree = @gollum_wiki.repo.git.lookup(tree[options[:path]][:oid]) if options[:path]
    results = []
    tree.walk_blobs(:postorder) do |root, entry|
      blob = @gollum_wiki.repo.git.lookup(entry[:oid])
      if blob.content.match(regex)
        path = options[:path] ? File.join(options[:path], root, entry[:name]) : "#{root}#{entry[:name]}"
        results << Page.new(wiki: self, path: path)
      end
    end
    results
  end

  def find_gollum_page(path)
    # TODO: use @wiki.paged(dir, name, ...)
    all_pages = @gollum_wiki.pages
    all_pages.find { |p| p.url_path == path }
  end

  def find_gollum_file(path)
    all_files = @gollum_wiki.files
    all_files.find { |p| p.path == path }
  end

  def push_repo
    if @upstream
      output = `cd #{@gollum_wiki.path} && git push #{@upstream} master 2>&1`
      if $?.success?
        puts "Pushed: #{output}"
      else
        puts "Unable to push: #{output}"
        raise Exception.new("Git push in #{@gollum_wiki.path} failed with status #{$?.exitstatus}: #{output}")
      end
    end
  end

  def pull_repo
    if @upstream
      output = `cd #{@gollum_wiki.path} && git pull #{@upstream} master 2>&1`
      if $?.success?
        puts "Pulled: #{output}"
      else
        puts "Unable to pull: #{output}"
        raise Exception.new("Git pull in #{@gollum_wiki.path} failed with status #{$?.exitstatus}: #{output}")
      end
    end
  end

end
end
