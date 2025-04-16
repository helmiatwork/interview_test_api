class Job < ApplicationRecord
  include JobIndexable
  STATUSES = ['pending', 'in_progress', 'completed']

  belongs_to :user

  validates :title, presence: true
  validates :description, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
end
