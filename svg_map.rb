require_relative 'toffin'

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
