require 'victor'

require_relative 'test/common/database_population'
include DatabasePopulation

class PlottedFile
	attr_reader :x
	attr_reader :y
	attr_reader :record

	def initialize x, y, record
		@x = x
		@y = y
		@record = record
	end
end

def distribute_points_on_circumference(n, radius = 100, center_x = 100, center_y = 100)
	points = []

	# The total angle for a full circle is 2 * PI radians
	total_angle = 2 * Math::PI

	# Calculate the angular separation between each point
	angle_step = total_angle / n.to_f

	(0...n).each do |i|
		# Calculate the angle (theta) for the current point
		theta = i * angle_step

		# Calculate the coordinates relative to the center (0, 0)
		x = center_x + radius * Math.cos(theta)
		y = center_y + radius * Math.sin(theta)

		# Store the result
		points << [x.round(2), y.round(2)] # Rounding for clean output
	end

	return points
end

def distribute n_points = 5
	point_positions = distribute_points_on_circumference(n_points)

	puts "Positions for #{n_points} points:"
	point_positions.each_with_index do |(x, y), index|
		puts "Point #{index + 1}: (X: #{x}, Y: #{y})"
	end
end

def draw_point svg, x, y, text="point"
	svg.text text, text_anchor: "middle", font_size: 16, x: x, y: (y-10)

	svg.circle cx: x, cy: y, r: 5
end

create_database
create_files
create_tokens
tokenizate_files
create_file_to_file_relations

azimuth = TokenizableFile.find_by(title: '2025 1st semester restrospection')

relations = FileToFileRelation.graph azimuth.id, 2

plotted_files = Array.new

svg = Victor::SVG.new viewBox: '0 0 1000 1000', style: { background: :lightgreen }

for relation in relations
	# Draw point if they do not exist

	plotted_file_1 = nil
	plotted_file_2 = nil

	for already_plotted_file in plotted_files
		if already_plotted_file.record.id == relation.first_file_id
			plotted_file_1 = already_plotted_file
		elsif already_plotted_file.record.id == relation.second_file_id
			plotted_file_2 = already_plotted_file
		end
	end

		if not plotted_file_1
			plotted_file_1 = PlottedFile.new rand(1000), rand(1000), TokenizableFile.find(relation.first_file_id)
			plotted_files << plotted_file_1
		end

		if not plotted_file_2
			plotted_file_2 = PlottedFile.new rand(1000), rand(1000), TokenizableFile.find(relation.second_file_id)
			plotted_files << plotted_file_2
		end

		draw_point svg, plotted_file_1.x, plotted_file_1.y, plotted_file_1.record.title
		draw_point svg, plotted_file_2.x, plotted_file_2.y, plotted_file_2.record.title

		svg.line stroke: "black", x1: plotted_file_1.x, x2: plotted_file_2.x, y1: plotted_file_1.y, y2: plotted_file_2.y
end


svg.save '/tmp/test.svg'

destroy_database
