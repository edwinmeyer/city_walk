#!/usr/bin/env ruby

# city_walk.rb -- A Ruby 1.9.3 demo program which traverses the course of a walking event.

# Usage: ruby city_walk.rb < cw_input.txt

# Street grid:
# This city has a rectilinear street grid where
#   lettered north-south avenues start with "A" at the eastern city limits and increase going west, and
#   numbered east-west streets start with "1" at the southern city limits and increase going north.
# Avenue "Z" marks the western city limit.  There is no fixed street number limit

# Input:
# city_walk.rb reads its input from STDIN. The input consists of one or more lines of comma-delimited text of the format
# <intersection>,<checkpoint type>

# An intersection is specified as <street number>&<avenue letter>. The program outputs intersections in this format;
# however the input may also provide the avenue letter first.

# checkpoint type is one of the following:
# start_east, start_west, start_north, start_south - start point of the walk with indicated initial direction.
# In the case of multiple start checkpoints, the latest encountered is used.
# end -- The walk ends at this checkpoint.
# go_north, go_south, go_west, go_east -- continue in the indicated direction from this checkpoint.
# turn_right, turn_left -- turn right or left at this checkpoint.
# go_back -- reverse direction at this checkpoint.

# The input can provide the checkpoint lines definition in an arbitrary order.

# Output:
# The output consists of lines listing all encountered checkpoints written to STDOUT, Each line contains the intersection,
# the checkpoint type, the direction to be followed leaving the checkpoint, and the cumulative number of blocks traversed
# at that point. The first line is that of the "start" checkpoint (cumulative block count 0), and the last line is that
# of the "end" checkpoint (direction "stop"). There are two possible course planning errors which prevent the
# end point from being reached:
#   1) going beyond the course boundaries, and
#   2) a non-terminating course loop. These errors are written as the last line of output below that for the last
#      encountered checkpoint as "out of bounds" or "infinite loop". The non-terminating loop error must be reported
#      immediately after the first repeated checkpoint is output.

# The classes which implement the city_walk course traversal program are:
# Grid -- contains the grid specification.
# GridLoader -- loads the Grid from the input stream.
# Position -- contains an intersection and the grid boundaries.
# Walker -- traverses the grid and returns the cumulative distance travelled.
# Checkpoint and its subclasses (e.g. StartEast, GoNorth, TurnLeft, etc.) -- Specify the new direction of the walker 
# out of the checkpoint.
# TraversalHistory -- detects loops by recording traversals of an intersection in a particular direction.

# See bottom of file for command line grid creation and traversal


# All city walk errors raise this exception
class CityWalkError < Exception
end

# Add to standard library String class
class String
  def camelize()
    self.split('_').map(&:capitalize).join('')
  end

  def to_const()
    Object.const_get(self)
  end
end


# Define the grid structure and the grid traversal method.
# Grid has knowledge of no other classes (except CityWalkError)
class Grid
  def initialize()
    @checkpoint_placements = Hash.new # Holds checkpoint objects keyed by their positions
  end

  attr_accessor :start_position

  # Place a checkpoint object at a specified position. Only one checkpoint per position is allowed.
  # position.to_s must be defined. Otherwise the positioning coordinate system is arbitrary.
  def place_checkpoint(checkpoint, position)
    raise CityWalkError, "attempt to place a 2nd checkpoint at intersection #{position}" if @checkpoint_placements[position.to_s]
    @checkpoint_placements[position.to_s] = checkpoint
    # STDOUT.puts  "place_checkpoint: checkpoint_class: #{checkpoint.class}, position: #{position}"
  end

  # return the checkpoint at the position or nil if no checkpoint
  def placement_at(position)
    @checkpoint_placements[position.to_s]
  end
end


# Position abstracts away details of the coordinate system and provides a single object that specifies position.
# Position depends upon no other grid classes.
class Position
  attr_reader :col_idx, :row_idx

  def self.set_grid_size(column_count, row_count)
    @@col_count = column_count
    @@row_count = row_count
  end

  def initialize(col_idx, row_idx)
    @col_idx = col_idx
    @row_idx = row_idx
  end

  # The string form of coordinates -- used by all other classes
  def to_s
    "#{@row_idx+1}&#{('A'.ord+@col_idx).chr}"
  end

  # Return true if the position is inside the grid boundaries
  def inside_boundary?()
    @col_idx >= 0 and @col_idx < @@col_count and @row_idx >= 0 and @row_idx < @@row_count
  end

  def move_one(direction)
    case
      when direction == :east then @col_idx -= 1
      when direction == :south then @row_idx -= 1
      when direction == :west then @col_idx += 1
      when direction == :north then @row_idx += 1
      else raise CityWalkError, "unknown direction: #{direction}"
    end
  end
end


# Traverses the grid and maintains the traversal history.
# Walker interacts with the Grid, Position and TraversalHistory classes
class Walker;
  def initialize(grid)
    @grid = grid
  end

  def walk()
    cumulative_distance = 0
    segment_distance = 0
    traversal_history = TraversalHistory.new # for detecting infinite traversal loops
    @position = @grid.start_position
    direction = nil # retrieve from start checkpoint

    # Move the walker's Position one intersection at a time until the stop checkpoint is reached
    while in_bounds = @position.inside_boundary?
      if checkpoint = @grid.placement_at(@position) # nil if no checkpoint - continue in same direction
        direction = checkpoint.new_direction(direction)
        STDOUT.puts "#{@position}: #{checkpoint.class} checkpoint, #{segment_distance} blocks walked, now heading #{direction}"
        segment_distance = 0
      end
      break if second_traversal = traversal_history.record_traversal(@position, direction)
      break if direction == :stop
      @position.move_one(direction) # move to the next intersection -- it could be to off edge of grid
      segment_distance += 1
      cumulative_distance += 1
    end

    final_status = if !in_bounds
      "    Out of course bounds at intersection #{@position}"
    elsif second_traversal
      "    Start of infinite loop at intersection #{@position}"
    else
      "    Total number of blocks walked: #{cumulative_distance}"
    end
    STDOUT.puts final_status
  end
end


# Checkpoint is the superclass for all checkpoint subclasses
class Checkpoint
  # return the new direction out of the checkpoint. If set (by the Start... and Go... subclasses) @new_direction is returned.
  # Otherwise the @deflection_rules determine the new direction.
  def new_direction(direction=nil)
    return :stop if self.class == Stop
    if @new_direction
      return @new_direction
    else
      # iterate over the deflection rules until a matching current direction is found
      @deflection_rules.each do |cur_direction, new_direction|
        return new_direction if direction == cur_direction
      end
      raise CityWalkError, "successor direction to #{direction} not found in rules for #{self.class}"
    end
  end
end

# Create individual Start.. & Go.. Checkpoint subclasses. The subclasses do nothing other than to set the
# @new_direction instance variable for use by Checkpoint#new_direction.
# Eight Checkpoint subclasses are created dynamically of the form:
#   class StartNorth < Checkpoint
#     def initialize()
#       @new_direction = :north
#     end
#   end

['go', 'start'].each do |type|
  [:north, :east, :south, :west].each do |direction|
    Object.const_set("#{type}_#{direction}".camelize, Class.new(Checkpoint) do
      define_method(:initialize) do
        @new_direction = direction
      end
    end)
  end
end


class Stop < Checkpoint
end

class TurnRight < Checkpoint
  def initialize()
    @deflection_rules = [ [:south, :west], [:west, :north], [:north, :east], [:east, :south] ]
  end
end

class TurnLeft < Checkpoint
  def initialize()
    @deflection_rules = [ [:south, :east], [:west, :south], [:north, :west], [:east, :north] ]
  end
end

class GoBack < Checkpoint
  def initialize()
    @deflection_rules = [ [:south, :north], [:west, :east], [:north, :south], [:east, :west] ]
  end
end


# Keep track of the first prior traversal of a intersection in a particular direction
# An attempted second traversal fails
class TraversalHistory
  def initialize()
    @traversals = Hash.new
  end

  def traversal_at?(position, direction)
    pos_direction = traversal_key(position, direction)
    @traversals[pos_direction.to_s]
  end

  # Record the first traversal of position towards direction and return true
  # Return true if already such a traversal
  def record_traversal(position, direction)
    return true if traversal_at?(position, direction)
    pos_direction = traversal_key(position, direction)
    @traversals[pos_direction.to_s] = true
    false # 1st traversal of this position in direction
  end

  private
  def traversal_key(position, direction)
    "#{position}-#{direction}"
  end
end


# GridLoader is the external interface used by the command line script (see bottom of file) to load the grid from an
# IO stream. GridLoader embeds all knowledge of the input data format and also is aware of the valid checkpoint types.
# It interacts only with the Position and Grid classes.
class GridLoader

  # Load the grid from an input IO stream
  def self.load_grid_definition(grid, input_stream)
    @grid = grid # save class instance variable
    while line = input_stream.gets.chomp.strip rescue nil
      split_line = line.split('#') # 1st elem is that prior to comment start ('#')
      # skip if empty line or line starts with '#'
      load_grid_def_line(split_line[0]) if split_line.length>0 && split_line[0].length > 0
    end
  end

  private
  # Process an individual input line
  def self.load_grid_def_line(line)
    raise CityWalkError, "input line must have exactly two fields: #{line}" unless line.split(',').size == 2
    intersection, checkpoint_type = line.split(',')
    intersection.strip!; checkpoint_type.strip!
    if intersection =~ /\A\d+&[A-Za-z]\Z/
      street, avenue = intersection.split('&')
    elsif intersection =~ /\A[A-Za-z]&\d+\Z/
      avenue, street = intersection.split('&')
    else
      raise CityWalkError, "unknown intersection: #{intersection}"
    end

    row_idx = street.to_i - 1
    col_idx = avenue.upcase.ord - 'A'.ord

    # Place a checkpoint into the current intersection
    if %w(start_east start_west start_north start_south stop go_north go_south go_west go_east turn_right
        turn_left go_back).include?(checkpoint_type)
      checkpoint = checkpoint_type.camelize.to_const.new
    else
      raise CityWalkError, "unknown checkpoint #{checkpoint_type}"
    end

    position = Position.new(col_idx, row_idx)
    @grid.place_checkpoint(checkpoint, position)

    # record the start position if a Start checkpoint
    if %w(start_east start_west start_north start_south).include?(checkpoint_type)
      @grid.start_position = position
    end

    @row_count ||= 0
    @row_count = row_idx + 1 if row_idx >= @row_count
    @col_count ||= 0
    @col_count = col_idx + 1 if col_idx >= @col_count
    Position.set_grid_size(@col_count, @row_count)
  end
end


# Create, Load, and Traverse the grid
grid = Grid.new # create empty grid object
GridLoader.load_grid_definition(grid, STDIN) # load the grid definition from the input stream
walker = Walker.new(grid)
walker.walk() # traverse the grid and output the result
