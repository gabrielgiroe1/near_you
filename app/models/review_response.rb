class ReviewResponse < ApplicationRecord
  belongs_to :review
  belongs_to :provider

  before_save :filter_content
  validates :content, presence: true, length: { minimum: 10, maximum: 500 }

  private

  def filter_content
    self.content = LanguageFilter.combined_filter.sanitize(content)
  end
end
