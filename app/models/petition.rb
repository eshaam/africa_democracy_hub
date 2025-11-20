class Petition < ApplicationRecord
  belongs_to :user, optional: true

  # Validations
  validates :topic, presence: true
  validates :raw_input, presence: true

  # Scopes for Active Admin
  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
end
