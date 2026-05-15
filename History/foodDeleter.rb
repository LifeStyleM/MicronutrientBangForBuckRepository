=begin
foodDeleter.rb

Handles deleting previously added foods from the database. Displays the
additions history, prompts the user to select an entry, removes it from the
input file, updates the in-memory registry, removes it from additions.txt,
and logs the deletion to deletions.txt.
=end

module FoodDeleter
  ADDITIONS_FILE = File.join(__dir__, 'additions.txt')       # Source: history of added foods
  DELETIONS_FILE = File.join(__dir__, 'deletions.txt')       # Append-only log of deleted foods
  INPUT_DIR      = File.join(__dir__, '..', 'Input')          # Directory containing vitamin.txt and element.txt

  # Regex to parse a line from additions.txt.
  # Format: [YYYY-MM-DD HH:MM] food_name (Category) -> MN#: Name [file.txt]
  ENTRY_RE = /^\[(.+?)\] (.+?) \((.+?)\) -> (\w+): (.+?) \[(.+?)\]$/.freeze

  # Entry point: displays the additions log, prompts the user to select an entry,
  # confirms, then removes the food from the input file, in-memory registry,
  # additions.txt, and logs the deletion to deletions.txt.
  def self.run(micronutrients, foods)
    unless File.exist?(ADDITIONS_FILE) && !File.zero?(ADDITIONS_FILE)
      puts "\n  No additions on record to delete." # Nothing to delete
      return
    end

    entries = File.readlines(ADDITIONS_FILE).map(&:chomp).reject(&:empty?) # Load all additions

    if entries.empty?
      puts "\n  No additions on record to delete."
      return
    end

    puts "\n\e[1m=== Recent Additions ===\e[0m\n\n"

    # Display each addition with a 1-based number so the user can reference it
    entries.each_with_index do |line, i|
      puts "  #{i + 1}. #{line}"
    end

    puts

    loop do
      print "  Select entry to delete (0=back  1-#{entries.size}  x=exit): "
      input = $stdin.gets&.chomp&.strip&.downcase # Read and normalise input

      return if input == '0' || input == 'b' || input == 'back' # Return to day prompt
      ( puts "Exiting."; exit(0) ) if input == 'x'               # Exit the program

      idx = input.to_i - 1 # Convert to 0-based index

      unless idx >= 0 && idx < entries.size
        puts "  Invalid. Enter 0 to go back, 1-#{entries.size} to select, or x."
        next
      end

      entry_line = entries[idx]          # The raw additions.txt line chosen for deletion
      match      = entry_line.match(ENTRY_RE) # Parse the structured entry

      unless match
        puts "  Could not parse that entry. Skipping." # Malformed line guard
        next
      end

      food_name = match[2] # Extracted food name
      category  = match[3] # Extracted category
      mn_id     = match[4] # Extracted micronutrient id (e.g. "MN7")
      mn_name   = match[5] # Extracted micronutrient name
      file_name = match[6] # Which input file it was written to

      puts "\n  Deleting: \e[1;31m#{food_name} (#{category})\e[0m from #{mn_id}: #{mn_name}"
      print "  Confirm? (y / n): "
      confirm = $stdin.gets&.chomp&.strip&.downcase # Read confirmation

      unless confirm == 'y'
        puts "  Cancelled." # User chose not to confirm — loop back to selection
        next
      end

      remove_from_input_file(food_name, category, mn_id, file_name) # Remove from txt file on disk
      remove_from_registry(food_name, mn_id, micronutrients, foods) # Remove from in-memory hashes
      remove_from_additions(entry_line)                              # Remove line from additions.txt
      log_deletion(food_name, category, mn_id, mn_name, file_name)  # Record in deletions.txt

      puts "  \e[31m✓ '#{food_name} (#{category})' removed from #{mn_id}: #{mn_name}.\e[0m\n"
      print "  Press enter to continue..."
      $stdin.gets
      return # Done — return to the day prompt loop
    end
  end

  # Removes the food entry from the matching Foods (String) line in the input file.
  # Handles three cases: item at end ", item", item at start "item, ", or sole item "item".
  def self.remove_from_input_file(food_name, category, mn_id, file_name)
    file_path  = File.join(INPUT_DIR, file_name)      # Build full path to input file
    content    = File.read(file_path)                 # Read current file content
    escaped_id = Regexp.escape(mn_id)                 # Escape id for safe regex use
    entry_str  = "#{food_name} (#{category})"         # Reconstruct the entry as it appears in the file

    # Match the header line and its Foods (String) line together, then strip the entry
    updated = content.gsub(/^(#{escaped_id}:.*\n)(Foods \(String\): .+)$/) do
      foods_line = $2
      new_line   = foods_line
        .gsub(/, #{Regexp.escape(entry_str)}/, '')  # Remove if preceded by ", "
        .gsub(/#{Regexp.escape(entry_str)}, /, '')  # Remove if followed by ", "
        .gsub(/#{Regexp.escape(entry_str)}/, '')    # Remove if it is the only entry
        .rstrip
      "#{$1}#{new_line}"
    end

    File.write(file_path, updated) # Write cleaned content back to disk
  end

  # Removes the food from the in-memory foods hash and from the micronutrient's foods array.
  def self.remove_from_registry(food_name, mn_id, micronutrients, foods)
    foods.delete(food_name.downcase)                                        # Remove from shared foods hash
    mn = micronutrients[mn_id]                                              # Look up the micronutrient
    mn.foods.reject! { |f| f.name.downcase == food_name.downcase } if mn   # Remove food from mn.foods
  end

  # Rewrites additions.txt with the chosen entry line removed.
  def self.remove_from_additions(entry_line)
    lines = File.readlines(ADDITIONS_FILE)              # Load all lines
    lines.reject! { |l| l.chomp == entry_line }         # Drop the matching line
    File.write(ADDITIONS_FILE, lines.join)              # Write back without the deleted entry
  end

  # Appends a timestamped deletion record to deletions.txt.
  def self.log_deletion(food_name, category, mn_id, mn_name, file_name)
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M')     # Human-readable timestamp
    entry     = "[#{timestamp}] DELETED: #{food_name} (#{category}) from #{mn_id}: #{mn_name} [#{file_name}]\n"
    File.open(DELETIONS_FILE, 'a') { |f| f.write(entry) } # Append-only so history is preserved
  end
end
