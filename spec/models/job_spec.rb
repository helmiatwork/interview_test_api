require 'rails_helper'

RSpec.describe Job, type: :model do
  let(:user) { create :user }

  context 'validations' do
    it 'is valid with valid attributes' do
      job = Job.new(
        title: 'Test Job',
        description: 'A great job',
        status: 'pending',
        user: user
      )
      expect(job).to be_valid
    end

    it 'is invalid without a title' do
      job = Job.new(description: 'desc', status: 'pending', user: user)
      expect(job).not_to be_valid
      expect(job.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without a description' do
      job = Job.new(title: 'title', status: 'pending', user: user)
      expect(job).not_to be_valid
      expect(job.errors[:description]).to include("can't be blank")
    end

    it 'is invalid without a status' do
      job = Job.new(title: 'title', description: 'desc', user: user)
      expect(job).not_to be_valid
      expect(job.errors[:status]).to include("can't be blank")
    end

    it 'is invalid with a wrong status' do
      job = Job.new(title: 'title', description: 'desc', status: 'wrong_status', user: user)
      expect(job).not_to be_valid
      expect(job.errors[:status]).to include("is not included in the list")
    end
  end

  context 'associations' do
    it 'requires a user' do
      job = Job.new(title: 'title', description: 'desc', status: 'pending')
      expect(job).not_to be_valid
      expect(job.errors[:user]).to include("must exist")
    end
  end
end
