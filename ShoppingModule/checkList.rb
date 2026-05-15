=begin
checkList.rb

This file will check, using the shopping.txt file, to see if the micronutrients are all met and how many foods
are within that micronutrient within the shopping list. 
=end

require_relative '../FactoryData/factory'     # Load Factory to parse micronutrient/food data from input files
require_relative '../History/foodAdder'       # Load FoodAdder to handle unregistered foods
require_relative '../History/foodDeleter'     # Load FoodDeleter to delete previously added foods

module CheckList
  SHOPPING_FILE = File.join(__dir__, 'shopping.txt') # Path to the shopping list file

  # Maps every accepted abbreviation (downcased) to its canonical full day name.
  # Adding a new alias here is all that is needed to support it everywhere.
  DAY_ALIASES = {
    'm'  => 'Monday',
    't'  => 'Tuesday',
    'w'  => 'Wednesday',
    'r'  => 'Thursday',
    'f'  => 'Friday',
    'sa' => 'Saturday',
    'su' => 'Sunday'
  }.freeze

  # Prompts the user to pick a day and returns the canonical day name, or :delete if 'd' is typed.
  # Loops until valid input is received, handling any capitalisation variant.
  # Type 'x' at any prompt to quit the program.
  def self.prompt_day
    loop do
      print "Which day? (M/T/W/R/F/Sa/Su  |  d, x): " # Display the prompt
      input = $stdin.gets                                      # Read raw input from stdin
      next unless input                                        # Guard against EOF / piped input

      key = input.chomp.strip.downcase                         # Normalise: strip whitespace and downcase

      if key == 'x'                                            # User wants to quit
        puts "Exiting."
        exit(0)
      end

      return :delete if key == 'd'                             # Signal caller to enter delete mode

      day = DAY_ALIASES[key]                                   # Look up canonical name from the alias map
      return day if day                                        # Valid input — return the full day name

      puts "  Invalid input '#{input.chomp}'. Please enter one of: M, T, W, R, F, Sa, Su  (or d, x)"
    end
  end

  # Reads shopping.txt and returns a hash of { "Monday" => ["food1", "food2"], ... }.
  # Lines directly under a day header belong to that day.
  def self.load_shopping_list_by_day
    result       = {}   # Hash of day name => array of downcased food strings
    current_day  = nil  # Tracks which day section we are currently parsing

    return result unless File.exist?(SHOPPING_FILE) # Return empty hash if file is missing

    # Loop over each line in shopping.txt
    IO.foreach(SHOPPING_FILE) do |line|
      line = line.chomp.strip # Remove surrounding whitespace and trailing newline

      if line.match?(/\A\w+:\z/)                    # Line is a day header like "Monday:"
        day_name    = line.chomp(':').capitalize      # Strip colon and capitalise consistently
        current_day = day_name                        # Switch active day context
        result[current_day] ||= []                    # Initialise the day's array if not present
      elsif !line.empty? && current_day              # Non-blank line under an active day header
        result[current_day] << line.downcase          # Append normalised food name to current day
      end
    end

    result # Return the fully parsed day => foods hash
  end

  # Checks a single day's food list against the micronutrient registry and prints a coverage report.
  # Loops back to the day prompt if the user enters delete mode.
  def self.run(micronutrients, foods)
    loop do
      result = prompt_day                               # Ask the user which day (or 'd' for delete)

      if result == :delete                              # User wants to delete an addition
        FoodDeleter.run(micronutrients, foods)          # Run delete flow; returns when done or backed out
        next                                            # Return to day prompt after deletion
      end

      day           = result
      all_days      = load_shopping_list_by_day         # Parse the full shopping file by day
      shopping_list = all_days.fetch(day, [])           # Get only the selected day's foods

    puts "\n\e[1mEvaluating: #{day}\e[0m\n\n"

    if shopping_list.empty?
      puts "No foods listed for #{day}. Add items under '#{day}:' in shopping.txt and re-run."
      return
    end

    puts "Foods (#{shopping_list.size}): #{shopping_list.map(&:capitalize).join(', ')}\n\n"

    # Scan for foods not in the database and offer to add them
    unknown = shopping_list.reject { |item| foods.key?(item) } # Items with no registry entry
    unknown.each do |item|
      FoodAdder.prompt_add(item, micronutrients, foods) # Prompt user to add each unknown food
    end

    puts "\n" unless unknown.empty? # Blank line before coverage report if any prompts were shown

    covered     = [] # Micronutrients that have at least one match on this day
    not_covered = [] # Micronutrients with no match on this day

    # Loop over every micronutrient in the registry
    micronutrients.each_value do |mn|
      matches = mn.foods.select { |food| shopping_list.include?(food.name.downcase) } # Find foods present in the day's list

      if matches.any?
        covered << { mn: mn, matches: matches } # Store micronutrient and matched foods
      else
        not_covered << mn # No food for this micronutrient today
      end
    end

    # --- Covered ---
    puts "\e[1;32m=== Covered (#{covered.size}/#{micronutrients.size}) ===\e[0m\n\n"

    # Loop over each covered micronutrient and print matched food names in green
    covered.each do |entry|
      mn          = entry[:mn]
      matches     = entry[:matches]
      food_labels = matches.map { |f| "\e[32m#{f.name}\e[0m" }.join(', ') # Green food names
      puts "  \e[1m#{mn.id}: #{mn.name}\e[0m (#{matches.size} food(s) matched)"
      puts "    #{food_labels}"
      puts
    end

    puts

    # --- Not Covered ---
    puts "\e[1;31m=== Not Covered (#{not_covered.size}/#{micronutrients.size}) ===\e[0m\n\n"

    # Loop over each uncovered micronutrient and suggest its top 3 foods
    not_covered.each do |mn|
      suggestions = mn.foods.first(3).map(&:name).join(', ') # Suggest first 3 foods as examples
      puts "  \e[1m#{mn.id}: #{mn.name}\e[0m"
      puts "    Suggestions: #{suggestions}"
      puts
    end

    puts
    coverage_pct = (covered.size.to_f / micronutrients.size * 100).round(1) # Calculate coverage percentage
    puts "Coverage: #{coverage_pct}% (#{covered.size} of #{micronutrients.size} micronutrients met)"

    puts "\n"
    FoodAdder.print_history # Print the recent additions log at the end of each run
    break                   # Coverage report complete — exit the loop
    end  # loop
  end    # def self.run
end      # module CheckList
