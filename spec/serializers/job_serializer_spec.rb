# spec/serializers/job_serializer_spec.rb
require 'rails_helper'

RSpec.describe JobSerializer, type: :serializer do
  let(:user) { create :user }
  let(:job) { create :job, user: user }
  let(:serialized_job) { ActiveModelSerializers::SerializableResource.new(job).as_json }

  describe 'attributes' do
    %i[id title description status user_id created_at updated_at].each do |attr|
      it "includes the #{attr} attribute" do
        expect(serialized_job).to have_key(attr)
      end
    end
  end

  describe 'associations' do
    it 'includes the user association' do
      expect(serialized_job[:user]).to include(
        id: user.id,
        name: user.name,
        email: user.email
      )
    end
  end
end
