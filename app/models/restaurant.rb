class Restaurant < ApplicationRecord
  has_many :menus, dependent: :destroy
  has_many :menu_assignments, through: :menus
  has_many :menu_items, through: :menu_assignments

  validates :name, presence: true, uniqueness: true
end
