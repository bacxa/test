class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :name, nil: false
      t.string :email, nil: false
      t.timestamps null: false
    end
  end
end
