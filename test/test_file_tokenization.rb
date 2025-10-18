require 'minitest/autorun'

require_relative '../lib/toffin'

require_relative 'common/database_population'

class TestFileTokenization < Minitest::Test
	include DatabasePopulation

	def setup
		self.create_database

		self.create_files

		self.create_tokens
	end

	def test_file_tokenization
		self.tokenizate_files
	end
end
