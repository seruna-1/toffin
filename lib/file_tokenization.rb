require_relative 'record'

class FileTokenization < TokenizableFileTree::RecordBase
	belongs_to :token

	belongs_to :tokenizable_file
end
