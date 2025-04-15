class Job < ApplicationRecord
  belongs_to :user
  
  validates :title, presence: true
  validates :description, presence: true
  validates :status, presence: true, inclusion: { in: ['pending', 'in_progress', 'completed'] }
end
