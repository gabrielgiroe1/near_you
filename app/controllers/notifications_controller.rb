class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.newest_first
  end

  def read
    @notification = current_user.notifications.find(params[:id])
    @notification.update(read_at: Time.current)

    redirect_to @notification.event.url
  end
end
