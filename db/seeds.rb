# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Set Example records
# Clear existing records to start fresh
return unless Rails.env.development?

# Destroy all records in DB
User.destroy_all
Job.destroy_all
User.__elasticsearch__.delete_index!
Job.__elasticsearch__.delete_index!

User.__elasticsearch__.create_index!
Job.__elasticsearch__.create_index!

# Create 10 users with associated jobs
10.times do |i|
  user = User.find_or_create_by!(email: "user#{i + 1}@example.com") do |u|
    u.name = "User #{i + 1}"
    u.phone = "123-456-789#{i + 1}"
  end

  Job.create!(
    title: "Job Title #{i + 1}",
    description: "This is a job description for job number #{i + 1}.",
    user: user,
    status: Job::STATUSES.sample
  )
end

puts "10 users with jobs have been created!"

# Reindex models
User.import(force: true)
Job.import(force: true)

puts "Elasticsearch indexing complete!"
