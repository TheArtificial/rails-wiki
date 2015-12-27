class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def auth_required
    redirect_to '/auth/google' unless !!current_user
  end

  protected

  def current_user
    @current_user ||= User.new()
  end

end
