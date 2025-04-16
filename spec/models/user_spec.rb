require 'rails_helper'

RSpec.describe User, type: :model do
  context 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(name: 'John Doe', email: 'john@example.com', phone: '123456789')
      expect(user).to be_valid
    end

    it 'is invalid without a name' do
      user = User.new(email: 'john@example.com', phone: '123456789')
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without an email' do
      user = User.new(name: 'John Doe', phone: '123456789')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid without a phone' do
      user = User.new(name: 'John Doe', email: 'john@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:phone]).to include("can't be blank")
    end

    it 'is invalid with a duplicate email' do
      User.create!(name: 'Jane', email: 'jane@example.com', phone: '111222333')
      user = User.new(name: 'Another', email: 'jane@example.com', phone: '444555666')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it 'is invalid with incorrect email format' do
      user = User.new(name: 'John Doe', email: 'invalid_email', phone: '123456789')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end
  end
end
