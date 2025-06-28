# frozen_string_literal: true

class ServiceCardComponent < ViewComponent::Base
  def initialize(icon:, title:, description: nil, link: "#", show_arrow: true)
    @icon = icon
    @title = title
    @description = description
    @link = link
    @show_arrow = show_arrow
  end

  private

  attr_reader :icon, :title, :description, :link, :show_arrow
end
