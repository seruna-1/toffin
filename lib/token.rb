class Token < ActiveRecord::Base
	has_many :file_tokenizations

	has_many :tokenizable_files, through: :file_tokenizations
end
