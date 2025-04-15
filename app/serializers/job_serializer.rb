class JobSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :status, :user_id, :created_at, :updated_at
  belongs_to :user
end
