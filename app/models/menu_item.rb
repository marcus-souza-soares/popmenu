class MenuItem < ApplicationRecord
  has_many :menu_assignments, dependent: :destroy
  has_many :menus, through: :menu_assignments
  has_many :restaurants, through: :menus

  validates :name, presence: true, uniqueness: true
  validates :price_in_cents, presence: true, numericality: { greater_than: 0 }
end
