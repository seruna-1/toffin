require 'minitest/autorun'

require_relative '../toffin'

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
		azimuth_id = TokenizableFile.find_by(title: 'concrete mathematics annotations').id

		# Map file to file relations directly involving azimuth
		map = FileToFileRelation.graph azimuth_id, 1

		if not map.length == 1
			raise \
				"The file titled [concrete mathematics] is the only one directly related to [concrete mathematics annotations]." + "\n" \
				+ "Wrong map: " + "\n" \
				+ map.inspect
		else
			puts "Map with range 1 inspection:", map.inspect

			puts "Map with range 1 by titles:"

			for relation in map
				puts "#{relation.first_file.title} relates to #{relation.second_file.title}"
			end
		end
	end
end
