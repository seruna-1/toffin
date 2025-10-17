class CreateTables < ActiveRecord::Migration[8.0]
	def connection
		Token.retrieve_connection
	end

	def change
		create_table :tokenizable_files do |t|
			t.string :title, null: false
			t.string :file_type, null: false
			t.integer :directory_id
			t.timestamps
		end

		create_table :tokens do |t|
			t.string :name, null: false
		end

		create_join_table(
			:tokenizable_files,
			:tokens,
			table_name: :file_tokenizations
		)

		change_column_null :file_tokenizations, :tokenizable_file_id, false
		change_column_null :file_tokenizations, :token_id, false

		create_table :file_to_file_relations do |t|
			t.references :first_file, foreign_key: { to_table: :tokenizable_files }, null: false
			t.references :second_file, foreign_key: { to_table: :tokenizable_files }, null: false
		end
	end
end
