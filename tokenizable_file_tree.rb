require 'sqlite3'

require 'active_record'

require_relative 'create_tables'

# Tree that grows from a common directory, containing tokenizable files.
class TokenizableFileTree

	# Prevent instantiation
	private_class_method :new

	@root = nil

	# @return [Pathname] Path to the root directory of the tree.
	def self.root
		@root
	end

	# @param root_path [String, Pathname] Path to the root directory of the tree.
	def self.open root_path
		if @root
			puts "Changing root from #{@root.to_s} to #{root_path}."
		end

		@root = Pathname.new root_path

		database_path = @root + 'database.db'

		ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: database_path

		if not database_path.exist?
			puts "Database file doesn't exist. Creating one."

			CreateTables.new.change
		end
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
	def self.each_layer_dir layer
		current_path = @root

		may_be_created = nil

		maybe_more_layer_dirs = true
		# terminate = false

		while not maybe_more_layer_dirs
			path_deepness = current_path.each_filename.to_a.length

			deep_enough_to_yield = path_deepness == layer

			if not deep_enough_to_yield
				current_path += '0'
			else
				tip = 0

				continue_yielding = true

				while continue_yielding
					to_be_yielded = current_path + i.to_s

					if to_be_yielded.directory?
						yield to_be_yielded
					else
						if not may_be_created
							may_be_created = to_be_yielded
						end

						continue_yielding = false
					end
				end

				# Go back

				try_pop_tip = true

				while maybe_more_layer_dirs and try_pop_tip
					if current_path == @root
						maybe_more_layer_dirs = false
					end

					# Pop last path part (tip)

					tip = current_path.basename.to_s.to_i

					current_path += '..'

					if not tip == 9
						# Shouldn't continue popping. Increase current tip and put it back.

						tip += 1

						current_path + tip.to_s

						try_pop_tip = false
					end
				end
			end
		end

		return may_be_created
	end

	# Looks for a free directory in a given layer or creates one if that layer has space, then returns the path. Otherwise, returns nil.
	# @param layer [Integer]
	# @return [Pathname, nil]
	def self.get_free_directory_in_layer layer
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
	def self.get_free_directory
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
	def self.layers
		path = @root

		layers = 0

		can_go_deeper = true

		while can_go_deeper
			children_names = path.children.map { |child| child.basename.to_s }

			if not children_names.any? '0'
				can_go_deeper = false
			else
				path += '0'

				layers += 1
			end
		end

		return layers
	end
end
