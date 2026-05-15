=begin
food.rb

This file contains the definition of the Food class and related functionality.

=end

require_relative 'food_category' # Load the FoodCategory enum module

class Food
  attr_accessor :name, :price_per_serving, :micronutrients, :category # Expose name, price, micronutrient id list, and category as read/write

  def initialize(name, price_per_serving = nil, category = FoodCategory::OTHER) # category defaults to Other if not provided
    @name = name                           # Store the food's display name
    @price_per_serving = price_per_serving # Store the cost per serving (may be nil)
    @category = category                   # FoodCategory constant describing the type of food
    @micronutrients = []  # Array of micronutrient ids this food belongs to (e.g. ["MN1", "ME3"]) 
  end

  def add_micronutrient(micronutrient)
    @micronutrients << micronutrient.id # Store only the id, not the full object - less intensive
  end

  def to_s
    micronutrient_info = @micronutrients.join(", ")            # Flatten id array into a readable string
    "#{@name} (#{@category}): $#{@price_per_serving} per serving, Micronutrients: #{micronutrient_info}" # Full string representation of this food
  end
end