require_relative 'tokenizable_file_tree'

# File in a tokenizable file tree.
class TokenizableFile < ActiveRecord::Base
	# Can be the first or the second in file to file relations

	has_many :first_relations,
		class_name: 'FileToFileRelation',
		foreign_key: 'first_file_id',
		dependent: :destroy

	has_many :second_relations,
		class_name: 'FileToFileRelation',
		foreign_key: 'second_file_id',
		dependent: :destroy

	# Access for both cases in file to file relations

	has_many :related_files_as_first,
		through: :first_relations,
		source: :second_file

	has_many :related_files_as_second,
		through: :second_relations,
		source: :first_file

	has_many :file_tokenizations

	has_many :tokens, through: :file_tokenizations

	before_save :assign_directory_id

	after_save :create_in_filesystem

	before_destroy :destroy_from_filesystem

	# return [Array] Files related to this one.
	def related_files
		self.related_files_as_first + self.related_files_as_second
	end

	# Associates an array of token_names to the file. If any token name hasn't a record, it is created.
	# @params token_names [Array] Array of token names.
	def add_token_names token_names
		for token_name in token_names
			token_record = Token.find_by name: token_name

			if not token_record
				puts "Token #{token_name} doesn't exist. Creating."

				token_record = Token.create! name: token_name
			end

			self.tokens << token_record
		end
	end

	# @return [Pathaname] Path to this file.
	def path
		filename = self.id.to_s + '.' + self.file_type

		path_to_file = TokenizableFileTree.path_from_directory_id(self.directory_id) + filename

		return path_to_file
	end

	# Looks for files containing all provided tokens.
	# @param token_names [Array] Array of token names.
	# @return [Array] Array of TokenizableFile records.
	def self.search_by_tokens token_names
		TokenizableFile.joins(:tokens)
		.where(tokens: {name: token_names})
		.group('tokenizable_files.id')
		.having('COUNT(tokens.id) = ?', token_names.count)
	end

	private

	# Runs before a file is created, assigns its directory
	def assign_directory_id
		directory_path = TokenizableFileTree.get_free_directory

		self.directory_id = TokenizableFileTree.directory_id_from_path directory_path
	end

	# Runs before a file is created, assigns its directory
	def destroy_from_filesystem
		self.path.delete
	end

	# Runs after a file is created in the database. Creates it in filesystem.
	# @note The file path already can be obtained (from file id and directory id).
	def create_in_filesystem
		self.path.write ''
	end
end
