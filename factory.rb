=begin
factory.rb

This file will process the data and create instances of the Food and Micronutrient classes based on the provided data.
=end

require_relative 'food'          # Load the Food class
require_relative 'micronutrient' # Load the Micronutrient class
require_relative 'food_category' # Load the FoodCategory enum module

class Factory
  # Parses one or more input files (vitamin.txt, element.txt, etc.) and returns
  # a hash with deduplicated :micronutrients (keyed by id) and :foods (keyed by name).
  def self.parse_input_files(*file_paths)
    micronutrients = {} # Registry of all micronutrients keyed by id (e.g. "MN1")
    foods = {}          # Registry of all foods keyed by downcased name to prevent duplicates

    # Loop over each file path provided as an argument
    file_paths.each do |file_path|
      header_line = nil # Holds the most recently seen ID/name/category line
      foods_line  = nil # Holds the most recently seen Foods line

      # Lambda called once a header + foods pair has been accumulated
      process_entry = lambda do
        return unless header_line && foods_line # Skip if either line is missing

        # Parse the header: capture id, name, and category (Vitamin/Mineral + subtype)
        h = header_line.match(/^(\w+):\s+(.+?)\s+(Vitamin|Mineral)(.*)$/)
        return unless h # Skip malformed header lines

        id       = h[1]              # Entry ID, e.g. "MN1" or "ME3"
        name     = h[2].strip        # Micronutrient name, e.g. "Ascorbic Acid"
        category = (h[3] + h[4]).strip # Full category string, e.g. "Vitamin C" or "Mineral Trace"

        # Parse the foods line: extract the comma-separated food list
        f = foods_line.match(/^Foods \(String\):\s*(.+)$/)
        return unless f # Skip if foods line is malformed

        food_entries = f[1].split(",").map(&:strip) # Split into individual "food name (Category)" strings

        # Register the micronutrient only if this id has not been seen before
        unless micronutrients.key?(id)
          mn = Micronutrient.new(name) # Create a new Micronutrient instance
          mn.id = id                   # Assign the parsed id
          mn.category = category       # Assign the parsed category
          micronutrients[id] = mn      # Store in the registry
        end

        mn = micronutrients[id] # Retrieve the (possibly pre-existing) micronutrient

        # Loop over each food entry and register it, then link food <-> micronutrient
        food_entries.each do |food_entry|
          # Parse "food name (Category)" — category in parentheses is optional
          m         = food_entry.match(/^(.+?)\s*\(([^)]+)\)$/) # Match name and category separately
          food_name = m ? m[1].strip : food_entry                # Name is everything before the parentheses
          category  = m ? m[2].strip : FoodCategory::OTHER       # Category from parentheses, or Other if absent

          key = food_name.downcase                                             # Normalize key to avoid case duplicates
          foods[key] = Food.new(food_name, nil, category) unless foods.key?(key) # Register food with category if new

          food = foods[key]                                                    # Retrieve the Food instance
          food.add_micronutrient(mn) unless food.micronutrients.include?(mn.id) # Link food -> micronutrient
          mn.add_food(food)                                                    # Link micronutrient -> food
        end
      end

      # Loop over every line in the file one at a time using IO.foreach
      IO.foreach(file_path) do |line|
        line = line.chomp # Strip the trailing newline character

        if line.match?(/^\w+:/)          # Header line detected (e.g. "MN1: Retinol ...")
          header_line = line             # Store it and reset the foods line
          foods_line  = nil
        elsif line.match?(/^Foods \(String\):/) # Foods line detected
          foods_line = line                      # Store it and process the completed pair
          process_entry.call
        end
      end
    end

    { micronutrients: micronutrients, foods: foods } # Return both registries
  end
end


