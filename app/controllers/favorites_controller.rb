class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider, only: [:create, :destroy]

  def index
    @pagy, @favorites = pagy(current_user.favorites.includes(:provider).order(created_at: :desc))
  end

  def create
    @favorite = current_user.favorites.find_or_initialize_by(provider: @provider)
    if @favorite.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to provider_path(@provider) }
      end
    else
      redirect_to provider_path(@provider), alert: "Unable to favorite this provider."
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by(provider: @provider)
    if @favorite&.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to provider_path(@provider) }
      end
    else
      redirect_to provider_path(@provider), alert: "Unable to unfavorite this provider."
    end
  end

  private

  def set_provider
    @provider = Provider.find(params[:provider_id])
  end
end
