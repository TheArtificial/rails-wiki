module Wiki
  # inherit from host app for current_user and auth_required
  class ApplicationController < ::ApplicationController

    before_filter :auth_required

    layout 'layouts/wiki'

    def root
      @home = Rails.configuration.wiki.home_page
      redirect_to @home
    end

    def display
      ext = File.extname(request.path_info).downcase
      if ext.blank? || ext == ".html"
        @page = Rails.configuration.wiki.find_page(params[:path])
        if @page.nil?
          raise PageError.new("Cannot create orphan page", params[:path])
        elsif @page.new_page?
          redirect_to controller: :pages, action: :new
        else
          render 'wiki/pages/show'
        end
      else
        @attachment = Rails.configuration.wiki.find_attachment(params[:path], ext)
        if @attachment.blank?
          raise ActionController::RoutingError.new('Attachment Not Found')
        else
          send_file @attachment.filesystem_path, type: @attachment.mime_type, disposition: 'inline'
        end
      end
    end

  end
end
