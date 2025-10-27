class TokenizableFileTree::FileToFileRelation < TokenizableFileTree::RecordBase
	belongs_to :first, class_name: "TokenizableFileTree::File", foreign_key: 'first_id'

	belongs_to :second, class_name: "TokenizableFileTree::File", foreign_key: 'second_id'

	validate :prevent_self_relation

	validate :ensure_uniqueness

	before_validation :sort_file_ids

	def self.relate file1, file2
		self.create first_file_id: file1.id, second_file_id: file2.id
	end

	def pretty
		ids = [ self.first_file_id, self.second_file_id ]

		names = ids.map { |id| TokenizableFile.find(id).title }

		"Between [#{names[0]}] and [#{names[1]}]."
	end

	# return [Array] File to file relations involving this one (directly if range is 1 or indirectly if greater).
	def self.graph azimuth_id, range=1
		seen_file_ids = Set.new

		next_depth_ids = [azimuth_id]

		relations = Set.new

		current_depth = 1

		while not next_depth_ids.empty? and current_depth <= range
			puts "Unseen file ids: #{next_depth_ids}"

			current_depth_ids = next_depth_ids

			next_depth_ids = []

			current_depth += 1

			# Prevent current file ids to reappear
			seen_file_ids += current_depth_ids

			for file_id in current_depth_ids
				current_relations = FileToFileRelation.where("first_file_id = :id OR second_file_id = :id", id: file_id)

				for current_relation in current_relations
					relations << current_relation

					if not seen_file_ids.any? current_relation.first_file_id
						next_depth_ids << current_relation.first_file_id
					end

					if not seen_file_ids.any? current_relation.second_file_id
						next_depth_ids << current_relation.second_file_id
					end
				end
			end
		end

		return relations
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
