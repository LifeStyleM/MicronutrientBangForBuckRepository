=begin
main.rb

This is the main entry point of the program. 


=end

require_relative 'FactoryData/factory'
require_relative 'sharedFinder'
require_relative 'ShoppingModule/checkList' # Load CheckList module for shopping list coverage report

testMode = false # Set to true to enable test mode with hardcoded data instead of file input

input_dir = File.join(__dir__, 'Input')

# Uses the function within Factory class to parse the input files and build the data structures for micronutrients and foods.
result = Factory.parse_input_files(
  File.join(input_dir, 'vitamin.txt'),
  File.join(input_dir, 'element.txt')
)

micronutrients = result[:micronutrients]
foods = result[:foods]

puts "Loaded #{micronutrients.size} micronutrient(s) and #{foods.size} unique food(s)."
puts

if (testMode)
  micronutrients.each_value(&:print_info)

  puts
  SharedFinder.print_shared(foods, micronutrients)  
  puts "\n" + "=" * 60 + "\n\n"
end

CheckList.run(micronutrients, foods) # Run the shopping list coverage report


