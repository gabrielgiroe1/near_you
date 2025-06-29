class AddStripeFieldsToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :stripe_payment_intent_id, :string
    add_column :appointments, :refunded_at, :datetime
    add_column :appointments, :stripe_refund_id, :string
  end
end
