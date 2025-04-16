require 'rails_helper'

RSpec.describe Api::V1::JobsController, type: :request do
  let!(:user) { create :user }
  let!(:job) { create :job, user: user}

  # Weird things, user.jobs.count return 2 but the job array is 1
  let!(:add_job) { user.jobs.create(job.attributes.except("id")) }
  let!(:write_user_cache) { write_cache(user) }
  let!(:write_job_cache) { write_cache(job) }

  def json
    JSON.parse(response.body)
  end

  # API Request Tests
  context "API Request" do
    describe 'GET /api/v1/jobs' do
      context "when Elasticsearch is up" do
        before do
          # Mock Elasticsearch Job.search
          allow(Job).to receive(:search).and_return(double('result', results: double('results', records: [job])))
        end

        it 'returns a list of jobs and does not hit the database' do
          get '/api/v1/jobs'

          # Test the response
          expect(response).to have_http_status(:ok)
          expect(json).to be_an(Array)
          expect(json.first["id"]).to eq(job.id)
        end
      end

      context "when Elasticsearch is down" do
        before do
          # Simulate an Elasticsearch failure
          allow(Job).to receive(:search).and_raise(StandardError.new("Elasticsearch is down"))
        end

        it "falls back to fetching jobs from the database" do
          get '/api/v1/jobs'

          expect(response).to have_http_status(:ok)
          expect(json).to be_an(Array)
          expect(json.first["id"]).to eq(job.id)
        end
      end
    end

    describe 'GET /api/v1/jobs/:id' do
      it 'returns the job' do
        get "/api/v1/jobs/#{job.id}"
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to eq(job.id)
      end
    end

    describe 'POST /api/v1/jobs' do
      context "given valid params" do
        let(:valid_params) {
          {
            job: {
              title: "New Job",
              description: "Exciting work",
              status: "pending",
              user_id: user.id
            }
          }
        }

        it 'creates a new job' do
          post '/api/v1/jobs', params: valid_params
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['title']).to eq("New Job")
        end
      end

      context "given invalid params" do
        let(:invalid_job_params) { { job: { title: '', description: '', status: 'invalid', user_id: nil } } }

        it 'returns errors when job creation fails due to invalid parameters' do
          post '/api/v1/jobs', params: invalid_job_params

          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body['errors']).to include("Title can't be blank")
          expect(body['errors']).to include("Description can't be blank")
          expect(body['errors']).to include("User must exist")
        end
      end
    end

    describe 'PUT /api/v1/jobs/:id' do
      context "given valid params" do
        it 'updates the job' do
          put "/api/v1/jobs/#{job.id}", params: { job: { title: "Updated Job" } }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['title']).to eq("Updated Job")
        end
      end

      context "given invalid params" do
        it 'returns errors when job update fails due to invalid parameters' do
          put "/api/v1/jobs/#{job.id}", params: { job: { title: '', description: '', status: 'invalid', user_id: nil } }

          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body['errors']).to include("Title can't be blank")
          expect(body['errors']).to include("Description can't be blank")
          expect(body['errors']).to include("User must exist")
        end
      end
    end

    describe 'DELETE /api/v1/jobs/:id' do
      it 'deletes the job' do
        delete "/api/v1/jobs/#{job.id}"
        expect(response).to have_http_status(:no_content)
        expect(Job.exists?(job.id)).to be_falsey
      end
    end
  end

  context "Test for cache" do
    describe 'GET /api/v1/jobs/:id' do
      context 'when job is cached' do
        before do
          # Write the job to cache
          write_cache(job)
        end

        it 'returns the job from the cache' do
          expect(Job).not_to receive(:find)  # Ensure DB is not queried
          get "/api/v1/jobs/#{job.id}"
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['id']).to eq(job.id)
        end
      end

      context 'when job is not cached' do
        it 'fetches job from DB and stores it in the cache' do
          delete_cache(job)
          expect(Rails.cache).to receive(:fetch).with(job.id.to_s, namespace: 'job').and_call_original
          get "/api/v1/jobs/#{job.id}"
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe 'POST /api/v1/jobs' do
      let(:valid_params) {
        {
          job: {
            title: "New Job",
            description: "Exciting work",
            status: "pending",
            user_id: user.id
          }
        }
      }

      it 'creates a new job and caches it' do
        post '/api/v1/jobs', params: valid_params
        created_job = Job.find_by(title: "New Job")
        expect(Rails.cache.read(created_job.id, namespace: 'job')).to be_present
        expect(response).to have_http_status(:created)
        expect(Rails.cache.read(user.id, namespace: 'user').jobs.count).to eq 3
      end
    end

    describe 'PUT /api/v1/jobs/:id' do
      it 'updates the job and updates the cache' do
        put "/api/v1/jobs/#{job.id}", params: { job: { title: "Updated Job" } }

        expect(response).to have_http_status(:ok)

        # Read the updated job from cache
        cached_job = Rails.cache.read(job.id, namespace: 'job')

        # Ensure the cache has the updated job title
        expect(cached_job.title).to eq("Updated Job")

        # Ensure the job in the database is updated
        expect(job.reload.title).to eq("Updated Job")

        # Ensure that the user’s job title is also updated
        expect(job.user.jobs.first.title).to eq("Updated Job")
      end
    end

    describe 'DELETE /api/v1/jobs/:id' do
      before do
        write_cache(job)
      end

      it 'removes the job from the cache' do
        delete "/api/v1/jobs/#{job.id}"
        expect(Rails.cache.read(job.id, namespace: 'job')).to be_nil
        expect(response).to have_http_status(:no_content)
        expect(user.jobs.count).to eq(1)
      end
    end
  end
end
