=begin
food_category.rb

Defines the FoodCategory module, which acts as an enum for categorizing foods.
=end

module FoodCategory
  VEGETABLE = "Vegetable"   # Leafy greens, root vegetables, squash, etc.
  FRUIT     = "Fruit"       # Fresh fruits, dried fruits, and fruit juices
  RED_MEAT  = "Red Meat"    # Beef, pork, lamb, organ meats, and processed meats
  POULTRY   = "Poultry"     # Chicken, turkey, and other birds
  SEAFOOD   = "Seafood"     # Fish, shellfish, and other marine animals
  DAIRY     = "Dairy"       # Milk, cheese, yogurt, and fortified dairy alternatives
  GRAIN     = "Grain"       # Bread, rice, cereal, pasta, and other grain products
  LEGUME    = "Legume"      # Beans, lentils, peas, soy products, and tofu
  NUT_SEED  = "Nut/Seed"    # All nuts, seeds, and nut butters
  OIL       = "Oil"         # Plant-derived cooking oils
  HERB      = "Herb"        # Teas, spices, and dried herbs
  OTHER     = "Other"       # Eggs, yeast, salt, fortified supplements, and processed foods

  # Ordered list of all categories; used to control display order in SharedFinder
  ALL = [VEGETABLE, FRUIT, RED_MEAT, POULTRY, SEAFOOD, DAIRY, GRAIN, LEGUME, NUT_SEED, OIL, HERB, OTHER].freeze
end
