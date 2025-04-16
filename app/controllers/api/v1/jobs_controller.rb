module Api
  module V1
    class JobsController < BaseController
      before_action :set_job, only: [:show, :update, :destroy]

      # GET /api/v1/jobs
      def index
        begin
          if params[:user_id]
            query = Job.search(
              query: {
                match: {
                  user_id: params[:user_id]
                }
              }
            )
          else
            query = Job.search(query: { match_all: {} })
          end

          @jobs = query.results.records.map { |record| record._source }
        rescue StandardError => e
          # If Elasticsearch is down or any error occurs, fallback to fetching from the DB
          Rails.logger.error("Elasticsearch error: #{e.message}")
          @jobs = Job.includes(:user).all
        end

        render json: @jobs
      end

      # GET /api/v1/jobs/1
      def show
        render json: @job
      end

      # POST /api/v1/jobs
      def create
        @job = Job.new(job_params)

        if @job.save
          # Write the newly created job to the cache
          write_cache(@job)
          render json: @job, status: :created
        else
          render json: { errors: @job.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/jobs/1
      def update
        if @job.update(job_params)
          # Automatically overwrite the old cache with the updated job data
          write_cache(@job)

          render json: @job
        else
          render json: { errors: @job.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/jobs/1
      def destroy
        # Remove the job from the cache first, before the object is gone
        delete_cache(@job)

        @job.destroy

        head :no_content
      end

      private

      def set_job
        # Fetch the job from the cache (or database if not found in cache)
        @job = fetch_cache(params[:id], klass: Job)

        # If the job is not found, return a 404 Not Found
        render json: { errors: ['Job not found'] }, status: :not_found unless @job
      end

      def job_params
        params.require(:job).permit(:title, :description, :status, :user_id)
      end
    end
  end
end
