# app/models/concerns/job_indexable.rb
module JobIndexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    settings do
      mappings dynamic: false do
        indexes :title,       type: :text
        indexes :description, type: :text
        indexes :status,      type: :keyword
        indexes :user_id,     type: :integer
        indexes :created_at,  type: :date
        indexes :updated_at,  type: :date
        # Optional: you can also index user data directly here if needed
        indexes :user, type: :object do
          indexes :id,      type: :integer
          indexes :name,    type: :text
          indexes :email,   type: :keyword
          indexes :phone,   type: :keyword
          indexes :created_at, type: :date
          indexes :updated_at, type: :date
        end
      end
    end

    # Define which attributes to store in the index using the JobSerializer
    def as_indexed_json(options = {})
      # Serialize job data and merge the associated user data into the job document
      self.as_json(only: [:id, :title, :description, :status, :user_id, :created_at, :updated_at])
          .merge(user: user.as_json(only: [:id, :name, :email, :phone, :created_at, :updated_at]))
    end
  end

  class_methods do
    def index_job(job)
      job.__elasticsearch__.index_document
    end

    def delete_job_from_index(job)
      job.__elasticsearch__.delete_document
    end
  end
end
