class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :menu_assignments, dependent: :destroy
  has_many :menu_items, through: :menu_assignments

  validates :name, presence: true
end
