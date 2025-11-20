class Rumor < ApplicationRecord
  belongs_to :user
  belongs_to :country, optional: true

  validates :content, presence: true

  # Scopes for Dashboard
  scope :high_danger, -> { where(danger_level: 'High') }
  scope :pending, -> { where(status: 'pending') }
end