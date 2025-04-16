module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [:show, :update, :destroy]

      # GET /api/v1/users
      def index
        begin
          # Try to fetch users from Elasticsearch
          @users = User.search(query: { match_all: {}}).results.records.map { |record| record._source }
        rescue StandardError => e
          # If Elasticsearch is down or any error occurs, fallback to fetching users from the database
          Rails.logger.error("Elasticsearch error: #{e.message}")
          @users = User.includes(:jobs).all
        end

        render json: @users
      end

      # GET /api/v1/users/1
      def show
        render json: @user
      end

      # POST /api/v1/users
      def create
        @user = User.new(user_params)

        if @user.save
          # Write the newly created user to the cache
          write_cache(@user)
          render json: @user, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        render json: { errors: ['Email has already been taken'] }, status: :unprocessable_entity
      end

      # PATCH/PUT /api/v1/users/1
      def update
        if @user.update(user_params)
          # Automatically overwrite the old cache with the updated user data
          write_cache(@user)

          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/1
      def destroy
        # Remove the user from the cache before it is destroyed
        delete_cache(@user)

        # Now delete the user from the database
        @user.destroy

        # Respond with no content
        head :no_content
      end

      private

      def set_user
        # Fetch user from cache or database
        @user = fetch_cache(params[:id], klass: User)

        # If user not found, return 404
        render json: { errors: ['User not found'] }, status: :not_found unless @user
      end

      def user_params
        params.require(:user).permit(:name, :email, :phone)
      end
    end
  end
end
