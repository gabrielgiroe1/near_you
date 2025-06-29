class AddIndexToAppointmentsStripePaymentIntentId < ActiveRecord::Migration[8.0]
  def change
    add_index :appointments, :stripe_payment_intent_id
  end
end
