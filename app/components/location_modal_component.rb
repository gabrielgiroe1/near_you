# frozen_string_literal: true

class LocationModalComponent < ViewComponent::Base
  attr_reader :cities, :current_location

  def initialize(cities:, current_location: nil)
    @cities = cities
    @current_location = current_location
  end
end
