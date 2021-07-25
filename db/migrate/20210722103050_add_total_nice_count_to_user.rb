class AddTotalNiceCountToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :total_nice_count, :integer
  end
end
