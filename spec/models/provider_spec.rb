require 'rails_helper'

RSpec.describe Provider, type: :model do
  describe '.categories' do
    it 'returns a hash of categories' do
      categories = described_class.categories
      expect(categories).to be_a(Hash)
      expect(categories.keys).to include('Health & Wellness')
      expect(categories['Health & Wellness']).to include('Masseur')
    end
  end
end
