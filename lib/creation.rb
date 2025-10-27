require 'active_record'

class TokenizableFileTree::Creation < ActiveRecord::Migration[8.0]
	def connection
		TokenizableFileTree::RecordBase.retrieve_connection
	end

	def change
		create_table :files do |t|
			t.string :title, null: false
			t.string :format, null: false
			t.boolean :is_directory, default: false
			t.integer :location_id
			t.timestamps
		end

		create_table :tokens do |t|
			t.string :name, null: false
			t.string :description
		end

		create_join_table(
			:files,
			:tokens,
			table_name: :file_tokenizations
		)

		change_column_null :file_tokenizations, :file_id, false
		change_column_null :file_tokenizations, :token_id, false

		create_table :file_to_file_relations do |t|
			t.references :first, foreign_key: { to_table: :files }, null: false
			t.references :second, foreign_key: { to_table: :files }, null: false
		end
	end
end
