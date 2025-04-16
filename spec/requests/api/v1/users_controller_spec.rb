require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :request do
  let!(:user) { create(:user) }

  def json
    JSON.parse(response.body)
  end

  context "API Request" do
    describe 'GET /api/v1/users' do
      context "when Elasticsearch is up" do
        it 'returns a list of users and does not hit the database' do
          # Mock Elasticsearch User.search
          allow(User).to receive(:search).and_return(
            double('result', results: double('results', records: [user]))
          )
          get '/api/v1/users'

          # Test the response
          expect(response).to have_http_status(:ok)
          expect(json).to be_an(Array)
          expect(json.first["id"]).to eq(user.id)
        end
      end

      context "when Elasticsearch is down" do
        before do
          # Simulate an Elasticsearch failure
          allow(User).to receive(:search).and_raise(StandardError.new("Elasticsearch is down"))
        end

        it "falls back to fetching users from the database" do
          # Expect the database query to be triggered when Elasticsearch is down
          expect(User).to receive(:includes).with(:jobs).and_call_original
          expect(User).to receive(:all).and_call_original

          get '/api/v1/users'

          expect(response).to have_http_status(:ok)
          expect(json).to be_an(Array)
          expect(json.first["id"]).to eq(user.id)
        end
      end
    end

    describe 'GET /api/v1/users/:id' do
      it 'returns the user' do
        get "/api/v1/users/#{user.id}"
        expect(response).to have_http_status(:ok)
        expect(json["id"]).to eq(user.id)
      end
    end

    describe 'POST /api/v1/users' do
      context "given valid params" do
        let(:valid_params) do
          {
            user: {
              name: "John Doe",
              email: "john@example.com",
              phone: "123456789"
            }
          }
        end

        it 'creates a user' do
          post '/api/v1/users', params: valid_params
          expect(response).to have_http_status(:created)
          expect(json["name"]).to eq("John Doe")
        end
      end

      context "given invalid params" do
        let(:invalid_user_params) { { user: { name: '', email: '', phone: '' } } }

        it 'returns errors when user creation fails due to invalid parameters' do
          post '/api/v1/users', params: invalid_user_params

          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body['errors']).to include("Name can't be blank")
          expect(body['errors']).to include("Email can't be blank")
          expect(body['errors']).to include("Phone can't be blank")
        end
      end
    end

    describe 'PUT /api/v1/users/:id' do
      context "given valid params" do
        it 'updates the user' do
          put "/api/v1/users/#{user.id}", params: { user: { name: "Updated" } }
          expect(response).to have_http_status(:ok)
          expect(json["name"]).to eq("Updated")
        end
      end

      context "given invalid params" do
        let!(:existing_user) { create(:user, name: 'Existing User', email: 'existing@example.com', phone: '123456789') }

        it 'returns errors when user update fails due to invalid parameters' do
          put "/api/v1/users/#{existing_user.id}", params: { user: { name: '', email: '', phone: '' } }

          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body['errors']).to include("Name can't be blank")
          expect(body['errors']).to include("Email can't be blank")
          expect(body['errors']).to include("Phone can't be blank")
        end
      end
    end

    describe 'DELETE /api/v1/users/:id' do
      it 'deletes the user' do
        delete "/api/v1/users/#{user.id}"
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  context "Test for cache" do
    let(:valid_attributes) { { name: 'John Doe', email: 'john@example.com', phone: '1234567890' } }

    describe 'GET /api/v1/users/:id' do
      context 'when user is cached' do
        before do
          write_cache(user)
        end

        it 'returns the user from the cache' do
          expect(User).not_to receive(:find)
          get "/api/v1/users/#{user.id}"
          expect(response).to have_http_status(:ok)
          expect(json['id']).to eq(user.id)
        end
      end

      context 'when user is not cached' do
        it 'fetches user from DB and stores it in the cache' do
          delete_cache(user)

          expect(Rails.cache).to receive(:fetch).with(user.id.to_s, namespace: 'user', expires_in: 60.minutes).and_call_original

          get "/api/v1/users/#{user.id}"
          expect(response).to have_http_status(:ok)

          # Verify cache is now present
          expect(Rails.cache.read(user.id.to_s, namespace: 'user')).to be_present
        end
      end
    end

    describe 'POST /api/v1/users' do
      it 'creates a new user and caches it' do
        post '/api/v1/users', params: { user: valid_attributes }

        created_user = User.find_by(email: 'john@example.com')
        expect(created_user).not_to be_nil
        expect(Rails.cache.read(created_user.id.to_s, namespace: 'user')).to be_present
        expect(response).to have_http_status(:created)
      end
    end

    describe 'PUT /api/v1/users/:id' do
      it 'updates the user and updates the cache' do
        put "/api/v1/users/#{user.id}", params: { user: { name: 'Updated Name' } }

        cached_user = Rails.cache.read(user.id.to_s, namespace: 'user')
        expect(cached_user.name).to eq('Updated Name')
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'DELETE /api/v1/users/:id' do
      before do
        write_cache(user)
      end

      it 'removes the user from the cache' do
        expect(Rails.cache.read(user.id.to_s, namespace: 'user')).to be_present

        delete "/api/v1/users/#{user.id}"

        expect(Rails.cache.read(user.id.to_s, namespace: 'user')).to be_nil
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
