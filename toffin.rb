require 'sqlite3'

require 'active_record'

require_relative 'create_tables'

require_relative 'models/tokenizable_file'

require_relative 'models/token'

require_relative 'models/file_tokenization'

class TokenizableFileTreeInterface
	attr_reader :root

	# @param path [String, Pathname]
	def initialize path
		@root = Pathname.new path

		database_path = @root + 'database.db'

		ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: database_path

		if not database_path.exist?
			puts "Database file doesn't exist. Creating one."

			CreateTables.new.change
		end
	end

	# @param path [Pathname] Relative path
	def self.directory_id_from_path path
		if path.absolute?
			raise Error "Provide relative path."
		end

		path.to_s.delete('/').to_i
	end

	# Iterator for directories in layer. If the layer is not full, returns the next path to be created in a future grow. Returns nil otherwise.
	# @param layer [Integer]
	# @return [Pathname, nil]
	def each_layer_dir layer
		current_path = Pathname.new ''

		loop do
			# Whether ready to yield dirs or to go deeper
			if current_path.each_filename.to_a.length == (layer - 1)
				for i in (0..9)
					to_be_yielded = current_path + i.to_s

					if not to_be_yielded.file?
						return to_be_yielded
					elsif to_be_yielded.directory?
						yield to_be_yielded
					else
						break
					end
				end

				yielded = true
			else
				current_path += '0'

				yielded = false
			end

			if yielded then next end

			terminate = false

			while not terminate
				tip = current_path.basename.to_s.to_i

				current_path += '..'

				if tip == 9 then next end

				tip += 1

				current_path + tip.to_s
			end

			if terminate then break end
		end
	end

	# @param title [String]
	# @param token_names [Arrray]
	def create_file title, token_names
		existent_file_record = TokenizableFile.find_by title: title

		if existent_file_record
			raise Error "A file with title #{title} already exists with id #{existent_file_record.id}."
		end

		layers = self.layers

		directory = self.find_free_directory

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
	# @return [nil]
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

	def find_free_directory
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

	def layers
		path = @root

		layers = 0

		while path.entries.any? '0'
			path += '0'

			layers += 1
		end

		return layers
	end
end
