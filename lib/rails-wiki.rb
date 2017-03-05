require 'wiki/engine'
require 'wiki/exceptions'
require 'gollum-lib'
require 'frontmatter'
require 'wiki_links'
require 'markdown'

module Wiki

  # class << self
    mattr_accessor :local_directory
    mattr_accessor :remote_url
    mattr_accessor :history_url
  # end

  def self.setup
    yield self
  end

end
