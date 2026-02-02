# frozen_string_literal: true

class SearchModalComponent < ViewComponent::Base
  def initialize(service_types:, categories:, popular_services:, current_search: nil)
    @service_types = service_types
    @categories = categories
    @popular_services = popular_services
    @current_search = current_search
  end

  attr_reader :service_types, :categories, :popular_services, :current_search
end
