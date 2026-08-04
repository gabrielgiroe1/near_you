# frozen_string_literal: true

class ProviderCardComponent < ViewComponent::Base
  def initialize(provider:, current_user: nil)
    @provider = provider
    @current_user = current_user
  end

  private

  attr_reader :provider, :current_user

  def gallery_images
    @gallery_images ||= provider.images.select { |attachment| attachment.blob.image? }
  end

  def visible_images
    gallery_images.first(6)
  end

  def extra_images_count
    count = gallery_images.size - 6
    count.positive? ? count : 0
  end

  def has_gallery?
    gallery_images.any?
  end

  def display_rating
    return nil unless provider.rating&.positive? && review_count > 0

    sprintf("%.2f", provider.rating)
  end

  def review_count
    provider.reviews.size
  end

  def review_count_text
    count = review_count
    "#{count} #{count == 1 ? 'evaluare' : 'evaluari'}"
  end

  def new_provider?
    review_count < 3
  end

  def available_today?
    provider.next_available_day == Date.current
  end

  def availability_text
    provider.next_available_day_text
  end

  def availability_color
    available_today? ? "text-green-600" : "text-gray-600"
  end
end
