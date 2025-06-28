# frozen_string_literal: true

class NavbarComponent < ViewComponent::Base
  include Devise::Controllers::Helpers

  def current_user
    controller.current_user
  end

  def user_signed_in?
    controller.user_signed_in?
  end
end
