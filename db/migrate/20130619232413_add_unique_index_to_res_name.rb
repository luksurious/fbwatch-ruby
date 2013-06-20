class AddUniqueIndexToResName < ActiveRecord::Migration
  def change
    add_index :resources, :name, :unique
  end
end
