=begin
foodAdder.rb

Handles adding unregistered foods to the database. Prompts the user for the
food's category and micronutrient, writes the entry to the correct input file,
updates the in-memory registry, and logs the addition to additions.txt.
=end

require_relative '../FactoryData/food'          # Load Food class to create new Food instances
require_relative '../FactoryData/food_category' # Load FoodCategory enum for category selection
require_relative '../FactoryData/micronutrient' # Load Micronutrient class

module FoodAdder
  HISTORY_FILE = File.join(__dir__, 'additions.txt')        # Path to the additions history log
  INPUT_DIR    = File.join(__dir__, '..', 'Input')           # Directory containing vitamin.txt and element.txt

  # Entry point: called when a shopping list item is not found in the foods registry.
  # Prompts the user to optionally add the food. Mutates foods and micronutrients in place.
  # Supports 'b'=back (skip this food) and 'x'=exit at every sub-prompt.
  def self.prompt_add(food_name, micronutrients, foods)
    loop do
      print "\n  \e[33m'#{food_name}' is not in the database.\e[0m Add it? (y / n / x): "
      response = $stdin.gets&.chomp&.strip&.downcase # Read and normalise user response

      case response
      when 'x' then ( puts "Exiting."; exit(0) ) # Exit the program immediately
      when 'n'    then return                        # Skip this food, continue processing others
      when 'y'                                       # Proceed to category selection
        category = loop do                           # Loop allows coming back from micronutrient prompt
          cat = prompt_category(food_name)           # Ask for the food's category
          break cat unless cat == :back              # :back here means re-ask the y/n question above
          break :back                                # Propagate back up to the y/n loop
        end
        next if category == :back                    # User backed out of category — re-show y/n

        mn = loop do                                 # Loop allows coming back from micronutrient to category
          result = prompt_micronutrient(micronutrients) # Ask which micronutrient
          break result unless result == :back           # Valid selection — break with the micronutrient
          # :back from micronutrient — go back to category
          category = loop do
            cat = prompt_category(food_name)
            break cat unless cat == :back
            break :back
          end
          next if category == :back                  # Backed all the way out — re-show y/n outer loop
        end
        next if mn == :back                          # Somehow propagated back — re-show y/n

        append_to_input_file(food_name, category, mn)   # Persist the food to the correct input file
        update_registry(food_name, category, mn, foods) # Add the food to the in-memory registry
        log_history(food_name, category, mn)            # Record the addition in additions.txt
        puts "  \e[32m✓ '#{food_name} (#{category})' added to #{mn.id}: #{mn.name}\e[0m\n"
        return                                       # Done with this food — return to caller
      else
        puts "  Please enter y, n, or x."            # Re-prompt on unrecognised input
      end
    end
  end

  # Displays all FoodCategory options as a numbered list and returns the chosen category string.
  # Returns :back if the user wants to go back to the y/n prompt.
  def self.prompt_category(food_name)
    puts "\n  Select a category for '#{food_name}' (0=back | x=exit):"

    # Loop over all categories and print each with a number
    FoodCategory::ALL.each_with_index do |cat, i|
      puts "    #{i + 1}. #{cat}" # Display 1-based index and category name
    end

    loop do
      print "  Enter number (0=back  1-#{FoodCategory::ALL.size}  x=exit): "
      input = $stdin.gets&.chomp&.strip&.downcase # Read and normalise input

      return :back if input == '0' || input == 'b' || input == 'back' # Signal caller to go back
      ( puts "Exiting."; exit(0) ) if input == 'x'                     # Exit the program

      idx = input.to_i - 1 # Convert 1-based input to 0-based index
      return FoodCategory::ALL[idx] if idx >= 0 && idx < FoodCategory::ALL.size # Valid selection

      puts "  Invalid. Enter 0 to go back, 1-#{FoodCategory::ALL.size} to select, or x."
    end
  end

  # Displays all micronutrients as a numbered list and returns the chosen Micronutrient object.
  # Returns :back if the user wants to go back to category selection.
  def self.prompt_micronutrient(micronutrients)
    puts "\n  Which micronutrient does this food belong to? (0=back | x=exit)"

    mn_list = micronutrients.values # Convert registry hash to ordered array

    # Loop over all micronutrients and print each with a number
    mn_list.each_with_index do |mn, i|
      puts "    #{i + 1}. #{mn.id}: #{mn.name} (#{mn.category})" # Show id, name, and category
    end

    loop do
      print "  Enter number (0=back  1-#{mn_list.size}  x=exit): "
      input = $stdin.gets&.chomp&.strip&.downcase # Read and normalise input

      return :back if input == '0' || input == 'b' || input == 'back' # Signal caller to go back to category
      ( puts "Exiting."; exit(0) ) if input == 'x'                     # Exit the program

      idx = input.to_i - 1 # Convert 1-based input to 0-based index
      return mn_list[idx] if idx >= 0 && idx < mn_list.size # Valid selection

      puts "  Invalid. Enter 0 to go back, 1-#{mn_list.size} to select, or x."
    end
  end

  # Appends the food entry to the Foods (String) line of the correct input file.
  def self.append_to_input_file(food_name, category, mn)
    file_name  = mn.id.start_with?('MN') ? 'vitamin.txt' : 'element.txt' # Route by micronutrient prefix
    file_path  = File.join(INPUT_DIR, file_name)                           # Build full path
    content    = File.read(file_path)                                      # Read current file content
    escaped_id = Regexp.escape(mn.id)                                      # Escape id for use in regex
    new_entry  = "#{food_name} (#{category})"                              # Format as "name (Category)"

    # Find the Foods (String) line immediately following this micronutrient's header and append
    updated = content.gsub(/^(#{escaped_id}:.*\n)(Foods \(String\): .+)$/) do
      "#{$1}#{$2}, #{new_entry}" # Append to existing food list
    end

    File.write(file_path, updated) # Write updated content back to disk
  end

  # Adds the new food to the in-memory foods hash and links it to the micronutrient.
  def self.update_registry(food_name, category, mn, foods)
    key  = food_name.downcase          # Normalise key for consistent lookup
    food = Food.new(food_name, nil, category) # Create new Food instance with category
    food.add_micronutrient(mn)         # Link food -> micronutrient (stores mn.id)
    mn.add_food(food)                  # Link micronutrient -> food
    foods[key] = food                  # Register food in the shared foods hash
  end

  # Appends a timestamped line to additions.txt.
  def self.log_history(food_name, category, mn)
    file_name = mn.id.start_with?('MN') ? 'vitamin.txt' : 'element.txt' # Note which file was updated
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M')                      # Human-readable timestamp
    entry     = "[#{timestamp}] #{food_name} (#{category}) -> #{mn.id}: #{mn.name} [#{file_name}]\n"
    File.open(HISTORY_FILE, 'a') { |f| f.write(entry) } # Append-only so history is never overwritten
  end

  # Prints the full contents of additions.txt, or a message if no additions have been made.
  def self.print_history
    unless File.exist?(HISTORY_FILE) && !File.zero?(HISTORY_FILE)
      puts "No additions recorded yet." # File absent or empty
      return
    end

    puts "\e[1m=== Recent Additions ===\e[0m\n\n"

    # Loop over each line in additions.txt and print it
    IO.foreach(HISTORY_FILE) do |line|
      puts "  #{line.chomp}" # Indent each entry for readability
    end
  end
end
