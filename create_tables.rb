class CreateTables < ActiveRecord::Migration[8.0]
	def change
		create_table :tokenizable_files do |t|
			t.string :title
			t.string :file_type
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

		create_table :file_to_file_relations do |t|
			t.references :first_file, foreign_key: { to_table: :tokenizable_files }
			t.references :second_file, foreign_key: { to_table: :tokenizable_files }
		end
	end
end
