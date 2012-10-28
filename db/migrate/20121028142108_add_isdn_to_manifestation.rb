class AddIsdnToManifestation < ActiveRecord::Migration
  def change
    add_column :manifestations, :isdn, :string
  end
end
