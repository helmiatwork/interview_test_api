# spec/factories/jobs.rb
FactoryBot.define do
  factory :job do
    user
    title { Faker::Job.title }
    description { Faker::Lorem.paragraph }
    status { Job::STATUSES.sample }
  end
end
