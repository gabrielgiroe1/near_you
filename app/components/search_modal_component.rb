# frozen_string_literal: true

class SearchModalComponent < ViewComponent::Base
  attr_reader :service_types, :categories, :popular_services, :current_search, :cities, :current_location

  def initialize(service_types:, categories:, popular_services:, current_search: nil, cities: [], current_location: nil)
    @service_types = service_types
    @categories = categories
    @popular_services = popular_services
    @current_search = current_search
    @cities = cities
    @current_location = current_location
  end
end
