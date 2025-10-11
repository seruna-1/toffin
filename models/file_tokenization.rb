class FileTokenization < ActiveRecord::Base
	belongs_to :token

	belongs_to :tokenizable_file
end
