class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider
  before_action :set_review, only: [:update, :destroy]
  before_action :authorize_review_owner, only: [:update, :destroy]

  # POST /providers/:provider_id/reviews
  def create
    @review = @provider.reviews.build(review_params)
    @review.user = current_user
    @review.appointment = current_user.appointments.where(provider: @provider, status: :confirmed).last

    if @review.appointment.nil?
      redirect_to provider_path(@provider), alert: "You must have a completed appointment with this provider to leave a review."
      return
    end

    if @review.save
      update_provider_rating
      NewReviewNotifier.with(review: @review).deliver(@provider.user)
      redirect_to provider_path(@provider), notice: "Review submitted successfully!"
    else
      redirect_to provider_path(@provider), alert: @review.errors.full_messages.to_sentence
    end
  end

  def update
    if @review.update(review_params)
      respond_to do |format|
        format.html { redirect_to provider_path(@provider), notice: "Review updated successfully!" }
        format.js   # This will look for update.js.erb
      end
    else
      respond_to do |format|
        format.html { redirect_to provider_path(@provider), alert: @review.errors.full_messages.join(", ") }
        format.js   # Handle errors in JavaScript
      end
    end
  end

  # DELETE /providers/:provider_id/reviews/:id
  def destroy
    @review.destroy
    update_provider_rating
    redirect_to provider_path(@provider), notice: "Review deleted successfully!"
  end

  private

  # Ensure the provider exists
  def set_provider
    @provider = Provider.find(params[:provider_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Provider not found."
  end

  # Find the review for edit, update, and destroy actions
  def set_review
    @review = @provider.reviews.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to provider_path(@provider), alert: "Review not found."
  end

  # Ensure only the review owner can edit, update, or delete
  def authorize_review_owner
    unless @review.user == current_user
      redirect_to provider_path(@provider), alert: "You are not authorized to perform this action."
    end
  end

  # Allowlist review parameters
  def review_params
    params.require(:review).permit(:rating, :content)
  end

  # Update provider rating after a review is created, updated, or destroyed
  def update_provider_rating
    @provider.recalculate_average_rating!
  end
end
