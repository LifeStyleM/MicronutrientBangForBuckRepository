=begin
micronutrient.rb

This file contains the definition of the Micronutrient class and related functionality.

=end

class Micronutrient
  attr_accessor :id, :name, :category, :amount_per_serving, :unit, :foods # Expose all fields as read/write

  def initialize(name, amount_per_serving = nil, unit = nil) # amount and unit are optional; used when quantity data is available
    @name = name                        # Store the micronutrient's display name (e.g. "Ascorbic Acid")
    @amount_per_serving = amount_per_serving # Amount present per food serving (nil if not tracked)
    @unit = unit                        # Unit of measurement, e.g. "mg" or "mcg" (nil if not tracked)
    @foods = []                         # Array of Food objects that contain this micronutrient
  end

  def to_s
    "#{@name}: #{@amount_per_serving} #{@unit}" # Basic string representation showing name and optional amount
  end

  def add_food(food)
    @foods << food unless @foods.include?(food) # Append the Food object only if not already present
  end

  def print_info
    puts "#{@id}: #{@name} (#{@category})"          # Print the id, name, and category on one line
    puts "  Foods: #{@foods.map(&:name).join(', ')}" # Print all associated food names joined by commas
  end
end