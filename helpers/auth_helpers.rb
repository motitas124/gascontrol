module AuthHelpers
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !current_user.nil?
  end

  def require_login
    redirect '/login' unless logged_in?
  end

  def h(text)
    Rack::Utils.escape_html(text.to_s)
  end
end
