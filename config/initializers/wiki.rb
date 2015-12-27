require 'logger'

local_dir = Rails.root.join(Wiki.local_directory).to_s
repo_url = Wiki.remote_url
upstream = nil

FileUtils.mkdir_p(local_dir) unless File.directory?(local_dir)

if repo_url.present?
  output = `git clone #{repo_url} #{local_dir} 2>&1`
  if $?.success?
    Rails.logger.info "Cloned #{repo_url} to #{local_dir}: #{output}"
  else
    Rails.logger.error "Unable to clone #{repo_url} to #{local_dir}: #{output}"
  end
  puts "Cloned wiki repo: #{output}"
  # Rugged will use these for commits, (with the committer values as author)
  `git config --global user.name 'The Artificial intranet'`
  `git config --global user.email 'robots@theartificial.nl'`

  upstream = 'origin'
else
  Rails.logger.info "Initializing #{local_dir}"
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
