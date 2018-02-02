# require 'active_model'

module Wiki
class Wiki
  # a gollum wiki facade

  unloadable

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
    results = @gollum_wiki.search(query.force_encoding("UTF-8")) # rugged adapter insists
    pages = results.sort_by{ |h| h[:count] }.map{ |h| Page.new(wiki: self, path: h[:name]) }
  end

  def search_tags(tag, options={})
    regex = /\A---\s*$.*^tags:\s*\[.*\b(#{Regexp.escape(tag)})\b.*\].*^---\s*$/m
    search_regex(regex, options)
  end

  # one entry for each commit/file
  def recent_changes(parent_path=nil, max=100, offset=0)
    log = []
    # this is more gollum proper, but we can't set the path
    # commits = @gollum_wiki.latest_changes(max_count: max)
    ref = @gollum_wiki.ref # probably 'master'
    commits = @gollum_wiki.repo.log(ref, parent_path, {limit: max, offset: offset})
    commits.each do |c|
      c.stats.files.each do |f|
        path = f[0]
        if parent_path && ! path.starts_with?(parent_path)
          # we don't want this one
        elsif File.extname(path) == '.md'
          path.chomp!('.md')
          log << {path: path, commit: c}
        end
      end
    end
    # if we're out of commits, return nil rather than []
    return commits.empty? ? nil : log
  end

  # one entry for each file
  def recent_updates(options)
    default_options = {
      path: nil,
      limit: 10
    }
    options = default_options.merge(options)
    limit = [options[:limit], 1].max
    paging_window = limit * 2

    updates_hash = {}
    offset = 0
    until updates_hash.count >= limit
      changes = recent_changes(options[:path], paging_window, offset)
      break if changes.nil? # we ran out of commits first
      group_changes_into_updates(changes, updates_hash)
      offset += paging_window
    end
    return updates_hash.values.take(limit)
  end

  def group_changes_into_updates(changes, updates_hash)
    changes.each do |change|
      path = change[:path]
      if updates_hash.key?(path)
        # ignore, we already have a (newer) commit for this path
        updates_hash[path][:count] += 1
      else
        # *now* we'll bother making a Page and adding to our hash
        page = Page.new(wiki: self, path: change[:path])
        commit = change[:commit]
        author_name = commit.author.name
        author_email = commit.author.email
        message = commit.message
        stats = commit.stats
        date = commit.authored_date

        updates_hash[path] = {path: path, page: page, author_name: author_name, author_email: author_email, message: message, stats: stats, date: date, count: 1}
      end
    end
  end

  def create_page(path)
    page = Page.new(wiki: self, path: normalize_path(path))
    if page.new_page?
      if page.parent_path.blank?
        # page is at root
        if path.starts_with?('_')
          raise PageError.new("Root page names cannot begin with \"_\"", path)
        else
          return page
        end
      else
        # page should have parents
        parent_page = Page.new(wiki: self, path: page.parent_path)
        if parent_page.new_page?
          raise PageError.new("Cannot create a page with no parent", path)
        else
          return page
        end
      end
    else
      raise PageError.new("Page already exists", path)
    end
  end

  def find_page(path)
    page = Page.new(wiki: self, path: normalize_path(path))
    if page.new_page?
      Rails.logger.info("rails-wiki: new page #{path}")
      if page.parent_path.blank?
        # page is at root
        if path.starts_with?('_')
          raise PageError.new("Root page names cannot begin with \"_\"", path)
        else
          return page
        end
      else
        # page should have parents
        parent_page = Page.new(wiki: self, path: page.parent_path)
        if parent_page.new_page?
          raise PageError.new("Cannot create child of missing page \"#{page.parent_path}\"", path)
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
        return output
      else
        puts "Unable to push: #{output}"
        raise GitError.new("Git push in #{@gollum_wiki.path} failed with status #{$?.exitstatus}: #{output}")
      end
    else
      return "No upstream"
    end
  end

  def pull_repo
    if @upstream
      output = `cd #{@gollum_wiki.path} && git pull #{@upstream} master 2>&1`
      if $?.success?
        puts "Pulled: #{output}"
        refresh
        return output
      else
        puts "Unable to pull: #{output}"
        raise GitError.new("Git pull in #{@gollum_wiki.path} failed with status #{$?.exitstatus}: #{output}")
      end
    else
      return "No upstream"
    end
  end

private

  RULE_2A = /\/\.\/|\/\.$/
  RULE_2B_2C = /\/([^\/]*)\/\.\.\/|\/([^\/]*)\/\.\.$/
  RULE_2D = /^\.\.?\/?/
  RULE_PREFIXED_PARENT = /^\/\.\.?\/|^(\/\.\.?)+\/?$/

  # Resolves paths to their simplest form.
  # Shamelessly lifted from https://github.com/sporkmonger/addressable
  def normalize_path(path)
    normalized_path = path.dup
    begin
      mod = nil
      mod ||= normalized_path.gsub!(RULE_2A, '/')

      pair = normalized_path.match(RULE_2B_2C)
      parent, current = pair[1], pair[2] if pair
      if pair && ((parent != '.' && parent != '..') ||
          (current != '.' && current != '..'))
        mod ||= normalized_path.gsub!(
          Regexp.new(
            "/#{Regexp.escape(parent.to_s)}/\\.\\./|" +
            "(/#{Regexp.escape(current.to_s)}/\\.\\.$)"
          ), '/'
        )
      end

      mod ||= normalized_path.gsub!(RULE_2D, '')
      # Non-standard, removes prefixed dotted segments from path.
      mod ||= normalized_path.gsub!(RULE_PREFIXED_PARENT, '/')
    end until mod.nil?

    return normalized_path
  end

end
end
