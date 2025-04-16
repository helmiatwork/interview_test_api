module UserIndexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    settings do
      mappings dynamic: false do
        # User fields
        indexes :name,       type: :text
        indexes :email,      type: :keyword
        indexes :phone,      type: :keyword
        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        # Jobs as a nested field
        indexes :jobs, type: :nested do
          indexes :id,          type: :integer
          indexes :user_id,     type: :integer
          indexes :title,       type: :text
          indexes :description, type: :text
          indexes :status,      type: :keyword
          indexes :created_at,  type: :date
          indexes :updated_at,  type: :date
        end
      end
    end

    # Define the structure of the document to be indexed, including associated jobs
    def as_indexed_json(options = {})
      self.as_json(
        only: [:id, :name, :email, :phone, :created_at, :updated_at],
        include: {
          jobs: {
            only: [:id, :user_id, :title, :description, :status, :created_at, :updated_at]
          }
        }
      )
    end
  end

  class_methods do
    def index_user(user)
      user.__elasticsearch__.index_document
    end

    def delete_user_from_index(user)
      user.__elasticsearch__.delete_document
    end
  end
end
