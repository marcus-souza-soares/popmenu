class MenuItem < ApplicationRecord
  belongs_to :menu

  validates :name, presence: true, uniqueness: true
  validates :price_in_cents, presence: true, numericality: { greater_than: 0 }
end
