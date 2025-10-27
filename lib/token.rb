require_relative 'record_base'

class Token < TokenizableFileTree::RecordBase
	has_many :file_tokenizations

	has_many :files, through: :file_tokenizations
end
