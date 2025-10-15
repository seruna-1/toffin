class FileToFileRelation < ActiveRecord::Base
	belongs_to :first_file, class_name: "TokenizableFile", foreign_key: 'first_file_id'

	belongs_to :second_file, class_name: "TokenizableFile", foreign_key: 'second_file_id'
end
