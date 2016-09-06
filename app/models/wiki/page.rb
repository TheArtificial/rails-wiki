require 'active_model'

module Wiki
class Page
  # a gollum page facade

  @@format = :markdown

#  include ActiveModel::Model
  include ActiveModel::AttributeMethods
  include ActiveModel::Conversion
  include ActiveModel::Dirty
  extend ActiveModel::Naming

  define_attribute_methods :name, :content

  attr_accessor :wiki, :name, :content, :path, :uploaded_files
  alias :id :path

  def name=(value)
    name_will_change!
    @name=value unless value.nil?
  end

  def content=(value)
    content_will_change!
    @content=value unless value.nil?
  end

  def to_param
    @path
  end

  def path
    @path
  end

  def update(hash)
    self.name = hash[:name]
    self.content = hash[:content]
    @uploaded_files = hash[:uploaded_files]

    return true
  end

  def initialize(params={})
    wiki = params[:wiki]
    gollum_page = params[:gollum_page]
    path = params[:path]

    if wiki
      @wiki = wiki
    end
    if gollum_page
      self.gollum_page = gollum_page
    elsif path
      safepath = path.downcase.gsub(' ','-')
      @path = safepath
      new_page = @wiki.find_gollum_page(safepath)
      if new_page
        self.gollum_page = new_page
      else
        @name = safepath.split('/').last.gsub('-',' ')
        @blank = true
      end
    end
  end

  def gollum_page=(new_gp)
    @gollum_page = new_gp
    @name = new_gp.name
    @path = new_gp.url_path
    @content = new_gp.raw_data
  end

  def gollum_page
    @gollum_page
  end

  def new_page?
    @blank && true
  end

  # may be out of sync with @content!
  def html
    @gollum_page.formatted_data unless @blank
  end

  def metadata
    @gollum_page.metadata
  end

  # def to_param
  #   @gollum_page.url_path unless @blank
  # end

  def author
    @gollum_page.versions.first.author.name unless @blank
  end
  def authored_date
    @gollum_page.versions.first.authored_date unless @blank
  end

  def history_url
    # @@format is :markdown, so let's presume
    @wiki.history_url + @path + '.md'
  end

  def parents
    parents = []
    ancestors = @path.split('/')
    for i in 1..(ancestors.length - 1) do
      parent_name = ancestors.take(i).join('/')
      parents << @wiki.find_page(parent_name)
    end
    return parents
  end

  def parent_path
    parent_path = File.dirname(@path)
    (parent_path == '.') ? '' : parent_path # + '/'
  end

  def children
    @wiki.pages_under_path(@path)
  end

  def attachments
    return @wiki.files_under_path(@path)
  end

  def save(user)
    if @blank
      commit = {name: user.name, email: user.email, message: "created #{@path}"}
      Rails.logger.debug("creating #{@path}")

      @wiki.pull_repo
      @wiki.gollum_wiki.write_page(@name, @@format, @content, commit, self.parent_path)

      @gollum_page = @wiki.find_gollum_page(@path)
      @blank = false
    else
      commit = {name: user.name, email: user.email, message: "updated #{@path}"}
      Rails.logger.debug("saving #{@path}")

      @wiki.pull_repo
      @wiki.gollum_wiki.update_page(@gollum_page, @name, @@format, @content, commit)
    end

    if @uploaded_files.present?
      Rails.logger.debug("found #{@uploaded_files.length} new files for #{@path}")
      head = @wiki.gollum_wiki.repo.head

      # NOTE: may raise Gollum::DuplicatePageError
      commit_options = {
        message: "added #{@uploaded_files.length} attachments to #{@path}",
        name: user.name,
        email: user.email
      }
      committer = Gollum::Committer.new(@wiki.gollum_wiki, commit_options)

      self.uploaded_files.each do |uploaded|
        # TODO: maybe this should be creating then saving new files
        fullname = uploaded.original_filename
        ext = File.extname(fullname)
        format = ext.split('.').last
        filename = File.basename(fullname, ext)
        contents = uploaded.read
        fsdir = File.join(@wiki.gollum_wiki.path, @path)
        pathname = File.join(@path, fullname)

        if !FileTest::directory?(fsdir)
          Dir::mkdir(fsdir)
        end
        fspath = File.join(fsdir, fullname)
        File.open(fspath, 'wb') do |file|
          file.write(contents)
          Rails.logger.debug("uploaded #{format} to #{fspath}")
        end

        committer.index.add(pathname, contents)
        # committer.add_to_index(@path, filename, format, contents)
        # # committer.add_to_index(@path, filename, format, "file")
        committer.after_commit do |committer, sha|
          @wiki.gollum_wiki.clear_cache
          committer.update_working_dir(@path, filename, format)
        end
      end
      committer.commit
    end

    @wiki.push_repo
    changes_applied
  end

  def destroy!(user)
    commit = {name: user.name, email: user.email, message: "removed #{@path}"}
    Rails.logger.debug("removing #{@path}")
    @wiki.gollum_wiki.delete_page(@gollum_page, commit)
    @wiki.push_repo
  end

  def inspect
    "Wiki::Page '#{@path}' (#{@gollum_page})"
  end

  def persisted?
    # TODO: make this a real dirty flag
    ! self.new_page?
  end

end
end
