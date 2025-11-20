class Country < ApplicationRecord
  has_many :cities
  has_many :users
  has_many :rumors

  validates :name, presence: true
end