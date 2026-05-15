=begin
sorterList.rb 

This program will sort a list of values based on the metrics given in the readme file. That is, there will be only 3 metrics:
1. season/cultivation availability
2. monetary cost
3. effects

Additionally, we may add another metric: nutritional value for that certain micronutrient.

This program uses the input from the database. The database is the files in the Input folder. 
This program will use that data to sort the respective micronutrient the user has chosen. The reason why we make the user 
choose instead of just sorting ALL of the micronutrients is so that customization is possible and that the user will not
be overwhelmed with information that they may not need.

Operations:
1. User is prompted to choose an option at the start. Let's add an option "c" for "customization". 
2. If the user chooses "c", they will be prompted to choose which micronutrient they want to sort. 
3. Then, the user will be prompted to choose which metric they want to sort by.
4. Additionally, the user will be prompted to choose whether they want to sort in ascending or descending order.
5. After, the user will be prompted their choice for whether to display all options or some option(s), such that the user
is able to conveniently type what choice they want to see (e.g., abc -> a, b, and c. ab -> a and b. a -> a. etc.).
=end

require_relative 'FactoryData/food_category'
require 'terminal-table'

module SorterList
  METRICS = {
    '1' => 'Category (Season/Availability)',
    '2' => 'Monetary Cost',
    '3' => 'Micronutrient Coverage',
    '4' => 'Effects'
  }.freeze

  # Entry point. Accepts the parsed micronutrients and foods hashes from Factory.
  def self.run(micronutrients, foods)
    loop do
      puts "Options: c = customization | x = exit"
      print "Enter choice: "
      input = $stdin.gets
      next unless input

      key = input.chomp.strip.downcase

      case key
      when 'x'
        puts "Exiting."
        exit(0)
      when 'c'
        run_customization(micronutrients)
      else
        puts "  Invalid option '#{key}'. Please enter 'c' or 'x'.\n\n"
      end
    end
  end

  # Drives the food-category browse flow.
  def self.run_category_browse(foods, micronutrients)
    # Collect only categories that actually have foods in the loaded data
    present_categories = FoodCategory::ALL.select do |cat|
      foods.values.any? { |f| f.category == cat }
    end

    puts "\nFood categories:"
    print_list(present_categories) { |cat| cat }
    index_map = present_categories.each_with_index.map { |cat, i| [(i + 1).to_s, cat] }.to_h

    category = loop do
      print "\nEnter category number (or x to cancel): "
      input = $stdin.gets
      next unless input
      key = input.chomp.strip.downcase
      return if key == 'x'
      cat = index_map[key]
      break cat if cat
      puts "  Invalid selection '#{key}'. Please enter a number from the list."
    end

    cat_foods = foods.values.select { |f| f.category == category }.sort_by(&:name)

    rows = cat_foods.each_with_index.map do |food, i|
      mn_names = food.micronutrients.map { |id| micronutrients[id]&.name }.compact.join(', ')
      [(i + 1).to_s, title_case(food.name), mn_names.empty? ? 'N/A' : mn_names]
    end

    table = Terminal::Table.new(
      title:    category,
      headings: ['#', 'Food', 'Micronutrients'],
      rows:     rows
    )
    table.align_column(0, :right)

    puts
    puts table
    puts
  end

  # Drives the full customization flow.
  def self.run_customization(micronutrients)
    micronutrient = prompt_micronutrient(micronutrients)
    return unless micronutrient

    metric = prompt_metric
    return unless metric

    # Effects metric has its own display flow — no sort order needed
    if metric == '4'
      run_effects_overview
      return
    end

    order = prompt_order
    return unless order

    sorted_foods = sort_foods(micronutrient.foods, metric, order)
    display_foods(sorted_foods, micronutrient, metric, order)
  end

  # Title-cases a string: capitalizes every word except minor words in non-initial positions.
  MINOR_WORDS = %w[a an the and but or nor for so yet at by in of on to up via with from into
                   onto over past than upon as per].to_set.freeze

  def self.title_case(str)
    words = str.split(' ')
    words.each_with_index.map do |word, i|
      i == 0 || !MINOR_WORDS.include?(word.downcase) ? word.capitalize : word.downcase
    end.join(' ')
  end

  # Prints a numbered list right-aligned by the widest label. Yields each item for its display string.
  # Accepts an optional :labels array; if omitted, items are auto-numbered starting at 1.
  # Returns the label width so callers can compute matching indents.
  def self.print_list(items, labels: nil)
    auto_num = labels.nil?
    width    = auto_num ? items.size.to_s.length : labels.map(&:length).max
    items.each_with_index do |item, i|
      lbl  = auto_num ? (i + 1).to_s : labels[i]
      text = block_given? ? yield(item) : item.to_s
      puts "  %#{width}s. %s" % [lbl, text]
    end
    width
  end

  # Prompts the user to pick a micronutrient by number and returns it.
  def self.prompt_micronutrient(micronutrients)
    mn_list = micronutrients.values
    puts "\nAvailable micronutrients:"
    print_list(mn_list) { |mn| "#{mn.id}: #{mn.name} (#{mn.category})" }
    index_map = mn_list.each_with_index.map { |mn, i| [(i + 1).to_s, mn] }.to_h

    loop do
      print "\nEnter micronutrient number (or x to cancel): "
      input = $stdin.gets
      next unless input

      key = input.chomp.strip.downcase
      return nil if key == 'x'

      mn = index_map[key]
      return mn if mn

      puts "  Invalid selection '#{key}'. Please enter a number from the list."
    end
  end

  # Prompts the user to pick a sort metric and returns the key ('1', '2', '3', or '4').
  def self.prompt_metric
    puts "\nAvailable metrics:"
    print_list(METRICS.values, labels: METRICS.keys) { |v| v }

    loop do
      print "\nEnter metric number (or x to cancel): "
      input = $stdin.gets
      next unless input

      key = input.chomp.strip.downcase
      return nil  if key == 'x'
      return key  if METRICS.key?(key)

      puts "  Invalid metric '#{key}'. Please enter 1, 2, 3, or 4."
    end
  end

  # Prompts the user for ascending or descending order and returns :asc or :desc.
  def self.prompt_order
    loop do
      print "\nSort order: a = ascending | d = descending (or x to cancel): "
      input = $stdin.gets
      next unless input

      key = input.chomp.strip.downcase
      return nil   if key == 'x'
      return :asc  if key == 'a'
      return :desc if key == 'd'

      puts "  Invalid input '#{key}'. Please enter 'a' or 'd'."
    end
  end

  # Sorts a food list by the chosen metric and order. Nil prices are always placed last.
  def self.sort_foods(food_list, metric, order)
    sorted = case metric
             when '1' # Category (Season/Availability) — alphabetical by category then name
               food_list.sort_by { |f| [f.category.to_s, f.name] }
             when '2' # Monetary Cost — nil prices go to the end regardless of direction
               with_price    = food_list.select { |f| f.price_per_serving }
               without_price = food_list.reject { |f| f.price_per_serving }
               with_price.sort_by { |f| f.price_per_serving } + without_price
             when '3' # Micronutrient Coverage — foods covering more micronutrients rank first/last
               food_list.sort_by { |f| [f.micronutrients.size, f.name] }
             when '4' # Effects — not yet tracked; preserve original order
               food_list
             else
               food_list
             end

    order == :desc ? sorted.reverse : sorted
  end

  # Prints the sorted food list, then prompts for which metrics to display alongside each food.
  def self.display_foods(sorted_foods, micronutrient, metric, order)
    return if sorted_foods.empty?

    order_label = order == :asc ? "ascending" : "descending"

    # Side metrics: the 2 metrics that are NOT the main sort metric, labeled a and b.
    side_metrics = METRICS.reject { |k, _| k == metric }
    side_labeled = ('a'..'z').first(side_metrics.size).zip(side_metrics.to_a)
                             .map { |lbl, (key, name)| [lbl, key, name] }

    puts "\nAdditional metrics to display (s = #{METRICS[metric]}):"
    print_list(side_labeled, labels: side_labeled.map(&:first)) { |item| item[2] }
    puts

    selected_side_keys = prompt_metric_display(side_labeled, metric)
    return if selected_side_keys.nil?

    # Main metric always first, then any chosen side metrics
    display_keys = [metric] + selected_side_keys

    # --- Build table with terminal-table ---
    headings = ['#', 'Food'] + display_keys.map { |k| METRICS[k] }

    rows = sorted_foods.each_with_index.map do |food, i|
      row = [(i + 1).to_s, title_case(food.name)]
      display_keys.each do |k|
        row << case k
               when '1' then 'N/A'  # season/availability data not yet tracked
               when '2' then food.price_per_serving ? "$#{'%.2f' % food.price_per_serving}" : 'N/A'
               when '3' then food.micronutrients.join(', ') + " (#{food.micronutrients.size})"
               when '4' then 'N/A'  # effects data not yet tracked
               end
      end
      row
    end

    table = Terminal::Table.new(
      title:    "#{micronutrient.name} — sorted by #{METRICS[metric]} (#{order_label})",
      headings: headings,
      rows:     rows
    )
    table.align_column(0, :right)

    puts
    puts table
    puts
  end

  # Prompts the user to pick side metrics to show alongside the main sort metric.
  # Options: all, a, b, s (sort metric only), x (cancel).
  # Returns an array of side metric keys (may be empty for 's'), or nil for 'x'.
  def self.prompt_metric_display(side_labeled, main_metric)
    label_to_key = side_labeled.map { |lbl, key, _| [lbl, key] }.to_h
    side_labels  = side_labeled.map(&:first).join  # e.g. "ab"

    loop do
      print "Display which? (all | #{side_labels.chars.join(' | ')} | s | x): "
      input = $stdin.gets
      return nil unless input

      raw = input.chomp.strip.downcase
      return nil  if raw == 'x'
      return []   if raw == 's'
      return label_to_key.values if raw == 'all'

      chosen  = raw.chars.uniq.select { |c| label_to_key.key?(c) }
      invalid = raw.chars.uniq.reject { |c| label_to_key.key?(c) }

      unless invalid.empty?
        puts "  Unknown label(s): #{invalid.join(', ')}. Valid: #{side_labels.chars.join(', ')}, s, all"
        next
      end

      return chosen.map { |c| label_to_key[c] }
    end
  end

  EFFECTS_FILE = File.join(__dir__, 'Input', 'effects.txt')

  # Parses effects.txt and returns { "Sleep" => [{id:, name:, micronutrients:, mechanism:}, ...], ... }.
  def self.parse_effects
    result      = {}
    current_cat = nil

    return result unless File.exist?(EFFECTS_FILE)

    IO.foreach(EFFECTS_FILE) do |line|
      line = line.chomp.strip
      next if line.empty?

      if line.match?(/\A[A-Za-z &\-\/]+:\z/)        # Category header e.g. "Sleep:"
        current_cat = line.chomp(':')
        result[current_cat] ||= []
      elsif current_cat && (m = line.match(/^(F\d+)\s+\(([^)]+)\):\s+(.+?)\s+—\s+(.+)$/))
        result[current_cat] << {
          id:           m[1],
          name:         m[2],
          micronutrients: m[3],
          mechanism:    m[4]
        }
      end
    end

    result
  end

  # Prompts the user to pick a metric and shows ALL foods for it across the entire database.
  def self.run_metric_overview(foods, micronutrients)
    puts "\nAvailable metrics:"
    print_list(METRICS.values, labels: METRICS.keys) { |v| v }

    loop do
      print "\nEnter metric number (or x to cancel): "
      input = $stdin.gets
      next unless input
      key = input.chomp.strip.downcase
      return if key == 'x'

      unless METRICS.key?(key)
        puts "  Invalid metric '#{key}'. Please enter 1, 2, 3, or 4."
        next
      end

      if key == '4'
        run_effects_overview
      else
        order = prompt_order
        return unless order
        all_foods  = foods.values
        sorted     = sort_foods(all_foods, key, order)
        order_label = order == :asc ? "ascending" : "descending"

        rows = sorted.each_with_index.map do |food, i|
          val = case key
                when '1' then 'N/A'
                when '2' then food.price_per_serving ? "$#{'%.2f' % food.price_per_serving}" : 'N/A'
                when '3' then food.micronutrients.join(', ') + " (#{food.micronutrients.size})"
                end
          [(i + 1).to_s, title_case(food.name), food.category, val]
        end

        table = Terminal::Table.new(
          title:    "All Foods — #{METRICS[key]} (#{order_label})",
          headings: ['#', 'Food', 'Category', METRICS[key]],
          rows:     rows
        )
        table.align_column(0, :right)
        puts
        puts table
        puts
      end
      return
    end
  end

  # Prompts the user to choose an effect category then displays a table of foods for that effect.
  def self.run_effects_overview
    effects = parse_effects

    if effects.empty?
      puts "  No effects data found in effects.txt."
      return
    end

    categories = effects.keys
    puts "\nEffect categories:"
    print_list(categories) { |c| c }
    index_map = categories.each_with_index.map { |c, i| [(i + 1).to_s, c] }.to_h

    category = loop do
      print "\nEnter effect number (or x to cancel): "
      input = $stdin.gets
      next unless input
      key = input.chomp.strip.downcase
      return if key == 'x'
      cat = index_map[key]
      break cat if cat
      puts "  Invalid selection '#{key}'. Please enter a number from the list."
    end

    entries = effects[category]

    rows = entries.each_with_index.map do |e, i|
      [(i + 1).to_s, "#{title_case(e[:name])} (#{e[:id]})", e[:micronutrients], e[:mechanism]]
    end

    table = Terminal::Table.new(
      title:    category,
      headings: ['#', 'Food', 'Key Micronutrients', 'Mechanism'],
      rows:     rows
    )
    table.align_column(0, :right)
    puts
    puts table
    puts
  end
end

