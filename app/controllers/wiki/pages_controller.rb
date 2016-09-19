class Wiki::PagesController < Wiki::ApplicationController

  layout 'layouts/wiki'

  def index
    select = params[:select]
    query = params[:query]
    if query
      @query = query
      @pages = Rails.configuration.wiki.search(query)
    else
      @pages = Rails.configuration.wiki.all_pages
    end
  end

  def log
    @updates = Rails.configuration.wiki.recent_updates(limit: 50)
    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def new
    Rails.configuration.wiki.pull_repo
    @page = Rails.configuration.wiki.find_page(params[:path])
    render :edit
  end

  def create
    @page = Rails.configuration.wiki.create_page(params[:path])
    @page.update(page_params)
    if @page.save(current_user)
      flash[:notice] = "Created new page #{@page.name}"
      redirect_to @page
    else
      flash.now[:error] = "Error creating #{@page.name}"
      render :edit
    end
  end

  def edit
    Rails.configuration.wiki.pull_repo
    @page = Rails.configuration.wiki.find_page(params[:path])
  end

  def update
    @page = Rails.configuration.wiki.find_page(params[:path])
    @page.update(page_params)
    if @page.save(current_user)
      flash[:notice] = "Saved changes to #{@page.name}"
      redirect_to @page
    else
      flash.now[:error] = "Error saving #{@page.name}"
      render :edit
    end
  end

  def destroy
    return_path = root_path
    # ext = File.extname(request.path_info).downcase
    # if ext.blank? || ext == "html"
      if page = Rails.configuration.wiki.find_page(params[:path])
        page_path = page.path
        parent_path = page.parent_path
        if parent_path.empty?
          return_path = root_path
        else
          return_path = page_path(parent_path)
        end
        page.destroy!(current_user)
        # TODO: recurse pages and attachments

      # else
      #   file = Rails.configuration.wiki.find_file(params[:path] + '.' + params[:format])
      #   return_path = page_path(file.parent_path)
      #   file.destroy!(current_user)
      # end

      # TODO: look for first *valid* parent
      flash[:notice] = "Removed #{page_path}"
      redirect_to return_path
    else
      flash[:error] = "Unable to find #{params[:path]}"
      redirect_to return_path
    end
  end

private

  def page_params
    params.require(:page).permit(:name, :content, uploaded_files: [])
  end

end
