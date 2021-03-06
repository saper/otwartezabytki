# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :page_pl_path

  def current_user!

    unless user_signed_in?
      user = User.create!
      warden.set_user user
      sign_in user, :bypass => true

      unless request.referer && (request.referer.match(/otwartezabytki/) || request.referer.match(/centrumcyfrowe/))
        redirect_to root_path unless Rails.env.test?
      end
    end

    current_user
  end

  def page_pl_path(path)
    "/strony/#{path}"
  end
end
