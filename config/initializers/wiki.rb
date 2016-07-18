require 'logger'

local_dir = Rails.root.join(Wiki.local_directory).to_s
repo_url = Wiki.remote_url
upstream = nil

FileUtils.mkdir_p(local_dir) unless File.directory?(local_dir)

if repo_url.present?
  upstream = 'origin'
  if File.exist?(local_dir)
    output = `cd #{local_dir} && git pull #{upstream} master 2>&1`
    if $?.success?
      Rails.logger.info "Pulled #{repo_url} to #{local_dir}: #{output}"
    else
      Rails.logger.error "Unable to pull #{repo_url} to #{local_dir}: #{output}"
    end
  else
    output = `git clone #{repo_url} #{local_dir} 2>&1`
    if $?.success?
      Rails.logger.info "Cloned #{repo_url} to #{local_dir}: #{output}"
    else
      Rails.logger.error "Unable to clone #{repo_url} to #{local_dir}: #{output}"
    end
    # puts "Cloned wiki repo: #{output}"
  end
else
  Rails.logger.warn "Initializing #{local_dir} for local use [WITH NO UPSTREAM BACKUP]"
  system "git init #{local_dir}"
end

gollum = Gollum::Wiki.new(local_dir, {
  base_path: '/wiki/view',
  index_page: 'home',
  filter_chain: [:Frontmatter, :TOC, :Sanitize, :Tags, :Markdown] # frontmatter and markdown are bespoke
})
puts "Setting wiki to #{local_dir}, git: #{gollum.repo.git}"
wiki = Wiki::Wiki.new(gollum_wiki: gollum, upstream: upstream, history_url: Wiki.history_url)

Rails.configuration.wiki = wiki
