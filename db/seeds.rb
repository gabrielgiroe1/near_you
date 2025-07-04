User.destroy_all
Provider.destroy_all

# Create regular users
5.times do |i|
  User.create!(
    name: "user#{i + 1}",
    email: "user#{i + 1}@gmail.com",
    password: 'password',
    role: 'user'
  )
end

# Create providers for each service type (3 providers per type)
locations = ["Bucharest", "Cluj-Napoca", "Timisoara", "Iasi", "Constanta", "Brasov", "Ploiesti", "Galati"]
provider_counter = 1

Provider.service_types.keys.each do |service_type|
  service_name = Provider.service_types[service_type]

  3.times do |i|
    # Create user for provider
    user = User.create!(
      name: "provider#{provider_counter}",
      email: "provider#{provider_counter}@gmail.com",
      password: 'password',
      role: 'provider'
    )

    # Create provider profile
    Provider.create!(
      name: "provider#{provider_counter}",
      user: user,
      service_type: service_type,
      experience: rand(1..15),
      hourly_rate: case service_name
                     when "Masseur", "Personal Trainer", "Nutritionist", "Yoga Instructor" then rand(60..120)
                     when "Chiropractor", "Physical Therapist" then rand(80..150)
                     when "Hairstylist", "Makeup Artist", "Nail Technician" then rand(40..100)
                     when "Eyelash Technician", "Facial Expert", "Tanning Specialist" then rand(50..90)
                     when "Barber" then rand(30..70)
                     when "Electrician", "Plumber" then rand(70..130)
                     when "Gardener", "House Cleaner", "Window Cleaner" then rand(35..80)
                     when "Handyman", "Painter" then rand(50..100)
                     when "Tutor", "Language Coach" then rand(40..90)
                     when "Music Teacher", "Art Instructor" then rand(45..85)
                     when "Coding Instructor" then rand(80..150)
                     when "Photographer", "Videographer" then rand(100..200)
                     when "Event Decorator", "Florist" then rand(60..120)
                     when "DJ", "Entertainer" then rand(80..180)
                     when "Caterer" then rand(50..100)
                     when "Translator" then rand(40..80)
                     when "Pet Groomer" then rand(35..75)
                     when "Tailor" then rand(40..90)
                     else rand(40..100)
                   end,
      bio: "Professional #{service_name.downcase} providing quality services",
      rating: 5.0,
      location: locations.sample
    )

    provider_counter += 1
  end
end

puts "Seeding completed! Created #{User.count} users and #{Provider.count} providers."
puts "Service types covered: #{Provider.pluck(:service_type).uniq.sort.join(', ')}"
