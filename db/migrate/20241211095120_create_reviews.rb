class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.references :appointment, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :content, null: false
      t.timestamps
    end
  end
end
