require_relative '../../toffin'

module DatabasePopulation
	def create_database
		Dir.mkdir 'test-backend'

		TokenizableFileTree.open 'test-backend'
	end

	def create_files
		TokenizableFile.create(title: 'concrete mathematics', file_type: 'pdf')
		TokenizableFile.create(title: 'concrete mathematics annotations', file_type: 'md')
		TokenizableFile.create(title: 'calculus', file_type: 'pdf')
		TokenizableFile.create(title: 'calculus annotations', file_type: 'md')
	end

	def create_tokens
		Token.create(name: 'livro')
		Token.create(name: 'mathematics')
		Token.create(name: 'concrete mathematics')
		Token.create(name: 'donald knuth')
		Token.create(name: 'calculus')
		Token.create(name: 'james stewart')
	end

	def tokenizate_files
		TokenizableFile.find_by(title: 'concrete mathematics').tokens \
				<< Token.find_by(name: 'livro') \
				<< Token.find_by(name: 'mathematics') \
				<< Token.find_by(name: 'concrete mathematics') \
				<< Token.find_by(name: 'donald knuth')

		TokenizableFile.find_by(title: 'calculus').tokens \
				<< Token.find_by(name: 'livro') \
				<< Token.find_by(name: 'mathematics') \
				<< Token.find_by(name: 'calculus') \
				<< Token.find_by(name: 'james stewart')
	end

	def create_file_to_file_relations
		FileToFileRelation.relate(
			TokenizableFile.find_by(title: 'concrete mathematics'),
			TokenizableFile.find_by(title: 'concrete mathematics annotations')
		)
	end
end
