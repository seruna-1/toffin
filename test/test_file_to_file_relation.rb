require 'minitest/autorun'

require_relative '../lib/toffin'

require_relative 'common/database_population'

class TestFileToFileRelation < Minitest::Test
	include DatabasePopulation

	def setup
		self.create_database

		self.create_files

		self.create_tokens

		self.create_file_to_file_relations
	end

	def teardown
		self.destroy_database
	end

	def test_relation_creation
		FileToFileRelation.all.length == 1
	end

	def test_self_relation_prevention
		assert_raises { FileToFileRelation.create! first_file_id: 1, second_file_id: 1 }
	end

	def test_self_relation_prevention
		assert_raises { FileToFileRelation.create! first_file_id: 1, second_file_id: 2 }
	end

	def test_graph
		azimuth_id = TokenizableFile.find_by(title: '2025 1st semester restrospection').id

		pairs_lengths = [ 2, 4 ]

		for range in (1..2)
			pairs = FileToFileRelation.graph azimuth_id, range

			puts "Map with range #{range} inspection:", pairs.inspect

			puts "Prettyfied:"

			for pair in pairs
				puts pair.pretty
			end

			if pairs.length != pairs_lengths[range-1]
				raise "Incorrect map length. Expected #{pairs_lengths[range]}. Got #{pairs.length}."
			end

			puts ''
		end
	end
end
