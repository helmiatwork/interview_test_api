module Api
  module V1
    class JobsController < BaseController
      before_action :set_job, only: [:show, :update, :destroy]

      # GET /api/v1/jobs
      def index
        if params[:user_id]
          @jobs = Job.where(user_id: params[:user_idd])
        else
          @jobs = Job.all
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
          render json: @job, status: :created
        else
          render json: { errors: @job.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/jobs/1
      def update
        if @job.update(job_params)
          render json: @job
        else
          render json: { errors: @job.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/jobs/1
      def destroy
        @job.destroy
        head :no_content
      end

      private

      def set_job
        @job = Job.find(params[:id])
      end

      def job_params
        params.require(:job).permit(:title, :description, :status, :user_id)
      end
    end
  end
end
