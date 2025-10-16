require 'set'

class FileToFileRelation < ActiveRecord::Base
	belongs_to :first_file, class_name: "TokenizableFile", foreign_key: 'first_file_id'

	belongs_to :second_file, class_name: "TokenizableFile", foreign_key: 'second_file_id'

	def self.relate file1, file2
		self.create first_file_id: file1.id, second_file_id: file2.id
	end

	# return [Array] File to file relations involving this one (directly if range is 1 or indirectly if greater).
	def self.graph azimuth_id, range=1
		seen_file_ids = Array.new

		pairs = Array.new

		stack = [ [aizmuth_id] ] # Each distance is an array

		current_depth = 1

		while not stack.empty? and not (current_depth > range)
			if stack.first.empty?
				stack.shift

				current_depth += 1
			else
				current_id = stack.first.shift

				gotten_pairs = FileRelation.where("first_file_id = :id OR second_file_id = :id", id: current_id)

				for gotten_pair in gotten_pairs
					pairs << gotten_pair

					for id in [ gotten_pair.first_file_id, gotten_pair.second_file_id ]
						if not seen_file_ids.has?(id)
							seen_file_ids << id

							stack[1] << id
						end
					end
				end
			end
		end
	end
end
