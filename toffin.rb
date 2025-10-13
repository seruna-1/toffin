require 'sqlite3'

require 'active_record'

require_relative 'create_tables'

require_relative 'models/tokenizable_file'

require_relative 'models/token'

require_relative 'models/file_tokenization'

# Tree that grows from a common directory, containing tokenizable files.
class TokenizableFileTreeInterface

	attr_reader :root

	# @param root_path [String, Pathname] Path to the root directory of the tree.
	def initialize root_path
		@root = Pathname.new root_path

		database_path = @root + 'database.db'

		ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: database_path

		if not database_path.exist?
			puts "Database file doesn't exist. Creating one."

			CreateTables.new.change
		end
	end

	# @return [Array] Array of Token instances.
	def tokens
		Token.all
	end

	# @return [Array] Array of TokenizableFile instances.
	def files
		TokenizableFile.all
	end

	# Returns a directory id from a path.
	# @param path [Pathname] Relative path from root.
	# @return [Integer] Directory id.
	def self.directory_id_from_path path
		if path.absolute?
			raise Error "Provide relative path."
		end

		path.to_s.delete('/').to_i
	end

	# Returns a directory path from a directory id.
	# @param directory_number [Integer] Directory number (as in column directory_id in table tokenizable_files).
	# @return [Pathname] Directory path.
	def self.path_from_directory_id directory_number
		path = Pathname.new ''

		directory_number.to_s.each_char do |char|
			path += char
		end

		return path
	end

	# Iterator for directories in layer. If the layer is not full, returns the next path to be created in a future grow. Returns nil otherwise.
	# @param layer [Integer]
	# @return [Pathname, nil]
	def each_layer_dir layer
		current_path = @root

		may_be_created = nil

		terminate = false

		while not terminate
			path_deepness = current_path.each_filename.to_a.length

			deep_enough_to_yield = path_deepness == layer

			if not deep_enough_to_yield
				current_path += '0'
			else # Yield
				for i in (0..9)
					to_be_yielded = current_path + i.to_s

					if to_be_yielded.directory?
						yield to_be_yielded
					else
						if not may_be_created
							may_be_created = to_be_yielded
						end

						break
					end
				end

				# Go back

				loop do
					if current_path == @root
						terminate = true

						break
					end

					# Pop last path part

					tip = current_path.basename.to_s.to_i

					current_path += '..'

					# Continue loop if should pop another.

					if tip == 9 then next end

					# Push increased tip and stop if shouldn't pop another.

					tip += 1

					current_path + tip.to_s

					break
				end
			end
		end

		return may_be_created
	end

	# Creates a file with provided tokens and returns its path.
	# @param title [String] Title of the new file.
	# @param token_names [Arrray] Token names to associate with the new file. Any token that doesn't exist will be created.
	# @return [Pathname] Path of the created file.
	def create_file title, token_names
		existent_file_record = TokenizableFile.find_by title: title

		if existent_file_record
			raise Error "A file with title #{title} already exists with id #{existent_file_record.id}."
		end

		layers = self.layers

		directory = self.get_free_directory

		file_record = TokenizableFile.new

		file_record.title = title

		file_record.directory_id = TokenizableFileTreeInterface.directory_id_from_path directory

		file_record.save

		file_path = directory + file_record.id.to_s

		for token_name in token_names
			token_record = Token.find_by name: token_name

			if not token_record
				puts "Token #{token_name} doesn't exist. Creating."

				token_record = Token.create! name: token_name
			end

			file_record.tokens << token_record
		end

		file_path.write ''

		return file_path
	end

	# Looks for a free directory in a given layer or creates one if that layer has space, then returns the path. Otherwise, returns nil.
	# @param layer [Integer]
	# @return [Pathname, nil]
	def get_free_directory_in_layer layer
		to_be_created = self.each_layer_dir(layer) do |directory|
			files = 0

			for file in directory.children
				if not file.directory? then files += 1 end
			end

			if files < 100 then return directory end
		end

		if not to_be_created
			return nil
		else
			Dir.mkdir to_be_created

			return to_be_created
		end
	end

	# Looks for a directory with free space in the lowest layer, if any. If not, creates a layer with a free directory.
	# @return [Pathname] Directory with free space.
	def get_free_directory
		found_directory = nil

		for layer in Range.new(1, self.layers)
			found_directory = get_free_directory_in_layer layer

			if found_directory then return found_directory end
		end

		# Everything full, create layer

		new_directory = @root + '0/'*(self.layers+1)

		Dir.mkdir new_directory

		return new_directory
	end

	# @return [Integer] Number of layers.
	def layers
		path = @root

		layers = 0

		loop do
			children_names = path.children.map do |child|
				child.basename.to_s
			end

			if not children_names.any? '0' then break end

			path += '0'

			layers += 1
		end

		return layers
	end

	# Looks for files containing all provided tokens.
	# @param token_names [Array] Array of token names.
	# @return [Array] Array of TokenizableFile records.
	def search_by_tokens token_names
		TokenizableFile.joins(:tokens)
			.where(tokens: {name: token_names})
			.group('tokenizable_files.id')
			.having('COUNT(tokens.id) = ?', token_names.count)
	end

	# @return [Pathname, nil] File path for a given file number, if any. Nil otherwise.
	def get_file file_number
		file_record = TokenizableFile.find file_number

		if not file_record
			return nil
		end

		return TokenizableFileTreeInterface.path_from_directory_id(file_record.directory_id) + file_number.to_s
	end
end
