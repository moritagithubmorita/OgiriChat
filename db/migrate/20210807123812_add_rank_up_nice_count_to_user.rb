class AddRankUpNiceCountToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :rankup_nice_count, :integer
  end
end
