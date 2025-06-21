class CreateReviewResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :review_responses do |t|
      t.references :review, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.text :content, null: false
      t.timestamps
    end
  end
end
