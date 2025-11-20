class TownhallDocument < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :status, presence: true
end
