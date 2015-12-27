require 'wiki/engine'
require 'gollum-lib'
require 'frontmatter'
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
