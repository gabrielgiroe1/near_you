User.destroy_all
Provider.destroy_all

users = [
  { name: "provider1", email: 'provider1@gmail.com', password: 'password', role: 'provider' },
  { name: "provider2", email: 'provider2@gmail.com', password: 'password', role: 'provider' },
  { name: "provider3", email: 'provider3@gmail.com', password: 'password', role: 'provider' },
  { name: "user1", email: 'user1@gmail.com', password: 'password', role: 'user' },
  { name: "user2", email: 'user2@gmail.com', password: 'password', role: 'user' }
]

users.each_with_index do |user_data, index|
  user = User.create!(user_data)
  if user.provider?
    Provider.create!(
      name: user_data[:name],
      user: user,
      service_type: ["Electrician", "Plumber", "Gardener", "Masseur"].sample,
      experience: rand(1..10),
      hourly_rate: rand(50..150),
      bio: "Experienced #{user_data[:email].split('@').first} available for various services.",
      rating: rand(3.0..5.0).round(1),
      location: ["Bucharest", "Cluj-Napoca", "Timisoara", "Iasi"].sample
    )
  end
end

puts "Seeding completed! Created #{User.count} users and #{Provider.count} providers."
