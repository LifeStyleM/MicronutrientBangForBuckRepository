=begin
sharedFinder.rb

Finds every food that is shared across more than one micronutrient and reports
which micronutrients each shared food belongs to.

=end

require_relative 'factory'
require_relative 'food_category' # Load FoodCategory to drive display order

module SharedFinder
  # Accepts the foods hash from Factory.parse_input_files and returns a filtered
  # hash containing only foods that belong to more than one micronutrient.
  def self.find_shared(foods)
    foods.select { |_key, food| food.micronutrients.size > 1 } # Keep only foods with multiple micronutrients
  end

  # Prints shared foods organized by FoodCategory, in the order defined by FoodCategory::ALL.
  # Accepts the foods hash and the micronutrients registry to resolve names from ids.
  def self.print_shared(foods, micronutrients)
    shared = find_shared(foods) # Get the filtered set of shared foods

    if shared.empty?
      puts "No shared foods found."
      return
    end

    puts "Shared foods (#{shared.size} total), organized by category:\n\n"

    grouped = shared.values.group_by(&:category) # Group Food objects by their category string

    # Loop over categories in the canonical order defined by FoodCategory::ALL
    FoodCategory::ALL.each do |cat|
      next unless grouped.key?(cat) # Skip categories that have no shared foods

      puts "=== #{cat} ==="

      # Loop over each shared food in this category
      grouped[cat].each do |food|
        mn_labels = food.micronutrients.map { |id| "#{id} #{micronutrients[id].name}" }.join(", ") # Resolve ids to names
        puts "  \e[1;32m>> #{food.name}\e[0m"        # Bold green food name with >> marker
        puts "     Found in: #{mn_labels}"
      end

      puts
    end
  end
end