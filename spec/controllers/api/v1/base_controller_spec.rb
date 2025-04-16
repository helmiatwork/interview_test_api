require 'rails_helper'

RSpec.describe Api::V1::BaseController, type: :controller do
  controller(Api::V1::BaseController) do
    # Dummy actions to trigger the rescue_from behavior
    def index
      raise ActiveRecord::RecordNotFound
    end

    def create
      raise ActiveRecord::RecordInvalid.new(User.new)
    end
  end

  describe 'rescue_from ActiveRecord::RecordNotFound' do
    it 'returns a 404 status and appropriate error message' do
      get :index
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq('Record not found')
    end
  end

  describe 'rescue_from ActiveRecord::RecordInvalid' do
    it 'returns a 422 status and appropriate error message' do
      post :create
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to be_an(Array)
    end
  end
end
