Gem::Specification.new do |spec|
	spec.name          = "toffin"
	spec.version       = "0.0.0"
	spec.authors       = ["Mateus Cezário Barreto"]
	spec.email         = ["mateus.cezario.barreto@gmail.com"]

	spec.summary       = "Tokenizable file tree."
	spec.description   = "Methods to organize files and to associate tokens to then in a tokenizable file tree."
	spec.homepage      = "https://github.com/seruna-1/toffin"
	spec.license       = "MIT"

	spec.files         = Dir.glob("{lib/**/*.rb,bin/*,*.md}")
end
