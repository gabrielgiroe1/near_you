# frozen_string_literal: true

class FooterComponent < ViewComponent::Base
  def initialize(class_name: nil)
    @class_name = class_name
  end

  private

  attr_reader :class_name

  def container_classes
    [
      "w-full",
      class_name
    ].compact.join(" ")
  end
end
