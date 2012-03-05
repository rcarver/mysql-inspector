class CreateThings < ActiveRecord::Migration
  def change
    create_table(:things) do |t|
      t.references :user
      t.string :name
    end
  end
end

