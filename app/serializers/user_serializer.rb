class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone, :created_at, :updated_at
  has_many :jobs
end
