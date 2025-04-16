# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }

    trait :with_job do
      after(:create) do |user|
        create(:job, user: user)
      end
    end
  end
end
