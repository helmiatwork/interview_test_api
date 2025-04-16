require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  let(:user) { create(:user, :with_job) }

  let(:serialized_user) do
    ActiveModelSerializers::SerializableResource.new(user).as_json
  end

  describe 'attributes' do
    %i[id name email phone created_at updated_at].each do |attr|
      it "includes the #{attr} attribute" do
        expect(serialized_user).to have_key(attr)
      end
    end
  end

  describe 'associations' do
    it 'includes associated jobs' do
      expect(serialized_user).to have_key(:jobs)
    end
  end
end
