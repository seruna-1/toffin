require 'set'

class FileToFileRelation < ActiveRecord::Base
	belongs_to :first_file, class_name: "TokenizableFile", foreign_key: 'first_file_id'

	belongs_to :second_file, class_name: "TokenizableFile", foreign_key: 'second_file_id'

	validate :prevent_self_relation

	validate :ensure_uniqueness

	before_validation :sort_file_ids

	def self.relate file1, file2
		self.create first_file_id: file1.id, second_file_id: file2.id
	end

	# return [Array] File to file relations involving this one (directly if range is 1 or indirectly if greater).
	def self.graph azimuth_id, range=1
		seen_file_ids = Array.new

		pairs = Array.new

		stack = [ [azimuth_id] ] # Each distance is an array

		current_depth = 1

		while not stack.empty? and not (current_depth > range)
			if stack.first.empty?
				stack.shift

				current_depth += 1
			else
				current_id = stack.first.shift

				gotten_pairs = FileToFileRelation.where("first_file_id = :id OR second_file_id = :id", id: current_id)

				for gotten_pair in gotten_pairs
					pairs << gotten_pair

					for id in [ gotten_pair.first_file_id, gotten_pair.second_file_id ]
						if not seen_file_ids.any?(id)
							seen_file_ids << id

							if stack.length == 1
								stack << [id]
							else
								stack[1] << id
							end
						end
					end
				end
			end
		end

		return pairs
	end

	private

	# Prevents a relation from one file to iself
	def prevent_self_relation
		if self.first_file.id == self.second_file.id
			errors.add(:base, "A file cannot be related to itself.")
		end
	end

	# Ensures there is only one relation for the same two files
	def ensure_uniqueness
		existent = FileToFileRelation.find_by(first_file_id: self.first_file_id, second_file_id: self.second_file_id)

		if existent
			errors.add :first_file_id, "Duplicate relation."
		end
	end

	# Enforces that first_file_id is lower than second_file_id to avoid duplicates
	def sort_file_ids
		both_exist = self.first_file.id and self.second_file.id
		if both_exist and ( self.first_file.id > self.second_file.id )
			self.first_file.id, self.second_file.id = self.second_file.id, self.first_file.id
		end
	end
end
