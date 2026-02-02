# frozen_string_literal: true

class SearchBarComponent < ViewComponent::Base
  def initialize(search: nil, location: nil)
    @search = search
    @location = location
  end

  attr_reader :search, :location

  def service_types
    Provider.service_types.values
  end

  def categories
    Provider.categories
  end

  def cities
    [
      "Bucuresti", "Cluj-Napoca", "Timisoara", "Iasi", "Constanta",
      "Craiova", "Brasov", "Galati", "Ploiesti", "Oradea",
      "Sibiu", "Bacau", "Arad", "Pitesti", "Buzau"
    ]
  end

  def popular_services
    [
      "Hairstylist", "Masseur", "Personal Trainer", "Plumber",
      "Electrician", "House Cleaner", "Photographer", "Tutor"
    ]
  end
end
