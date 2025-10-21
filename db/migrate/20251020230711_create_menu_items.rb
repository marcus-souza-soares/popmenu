class CreateMenuItems < ActiveRecord::Migration[8.0]
  def change
    create_table :menu_items do |t|
      t.string :name
      t.integer :price_in_cents
      t.references :menu, null: false, foreign_key: true
      t.string :ingredients

      t.timestamps
    end
    add_index :menu_items, :name, unique: true
  end
end
