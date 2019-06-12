class CreateTybLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :tyb_logs do |t|
      t.integer :status
      t.string :title
      t.text :content
      t.text :data

      t.timestamps
    end
  end
end
