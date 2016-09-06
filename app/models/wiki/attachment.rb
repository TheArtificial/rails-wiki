require 'active_model'

module Wiki
class Attachment

  include ActiveModel::AttributeMethods
  include ActiveModel::Conversion
  include ActiveModel::Dirty
  extend ActiveModel::Naming

  define_attribute_methods :name, :content

  attr_accessor :wiki, :name, :content, :path, :format
  alias :id :path

  def name=(value)
    name_will_change!
    @name=value unless value.nil?
  end

  def content=(value)
    content_will_change!
    @content=value unless value.nil?
  end

  def to_s
    self.path
  end

  def path
    @path
  end

  def update(hash)
    self.name = hash[:name]
    self.content = hash[:content]

    return true
  end

  def initialize(params={})
    wiki = params[:wiki]
    gollum_file = params[:gollum_file]
    path = params[:path]

    if wiki
      @wiki = wiki
    end
    if gollum_file
      self.gollum_file = gollum_file
    elsif path
      safepath = path.downcase.gsub(' ','-')
      @path = safepath
      new_file = @wiki.find_gollum_file(safepath)
      if new_file
        self.gollum_file = new_file
      end
    end
  end

  def gollum_file=(file)
    @gollum_file = file
    @name = file.name
    @format = File.extname(file.name).split('.').last.to_sym
    # filename = ::Attachment.basename(fullname, ext)
    @path = file.url_path + file.name
  end

  def gollum_file
    @gollum_file
  end

  def filesystem_path
    return File.join(@wiki.base_path, @path)
  end

  def mime_type
    @gollum_file.mime_type
  end

  def to_param
    @path
  end

  def parent_path
    parent_path = File.dirname(@path)
    (parent_path == '.') ? '' : parent_path + '/'
  end

  def destroy!(user)
    commit_options = {name: user.name, email: user.email, message: "removed #{@path}"}
    Rails.logger.debug("removing #{@path}")

    committer = Gollum::Committer.new(@wiki.gollum_wiki, commit_options)
    committer.delete(@path)

    committer.after_commit do |index, _sha|
      dir = File.dirname(@path)
      dir = '' if dir == '.'

      @wiki.gollum_wiki.clear_cache
      committer.update_working_dir(dir, parent_path, @format)
    end

    @wiki.pull_repo
    committer.commit
    @wiki.push_repo
  end

  def persisted?
    # TODO: make this a real dirty flag
    true
  end

end
end
