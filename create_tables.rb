class CreateTables < ActiveRecord::Migration[8.0]
	def change
		create_table :tokenizable_files do |t|
			t.string :title
			t.string :type
			t.integer :directory_id
			t.timestamps
		end

		create_table :tokens do |t|
			t.string :name
		end

		create_join_table(
			:tokenizable_files,
			:tokens,
			table_name: :file_tokenizations
		)
	end
end
