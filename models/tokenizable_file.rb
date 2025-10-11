class TokenizableFile < ActiveRecord::Base
	has_many :file_tokenizations

	has_many :tokens, through: :file_tokenizations
end
