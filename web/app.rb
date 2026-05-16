require 'sinatra'
require 'cgi'
require_relative '../FactoryData/factory'
require_relative '../FactoryData/food_category'
require_relative '../sorterList'
require_relative '../ShoppingModule/checkList'

configure do
  set :public_folder, File.join(__dir__, 'public')
  set :views,         File.join(__dir__, 'views')
  set :bind,          '127.0.0.1'
  set :port,          4567
end

# ── Load data once at startup ──────────────────────────────────────────────────
_input_dir = File.join(__dir__, '..', 'Input')
_data = Factory.parse_input_files(
  File.join(_input_dir, 'vitamin.txt'),
  File.join(_input_dir, 'element.txt')
)
MICRONUTRIENTS = _data[:micronutrients].freeze
FOODS          = _data[:foods].freeze

# ── Helpers ────────────────────────────────────────────────────────────────────
helpers do
  def h(str)
    CGI.escapeHTML(str.to_s)
  end

  def tc(str)
    SorterList.title_case(str.to_s)
  end

  def metric_value(food, key)
    case key
    when '1' then 'N/A'
    when '2' then food.price_per_serving ? format('$%.2f', food.price_per_serving) : 'N/A'
    when '3' then "#{food.micronutrients.join(', ')} (#{food.micronutrients.size})"
    when '4' then 'N/A'
    end
  end

  def nav_active(*paths)
    paths.any? { |p| request.path_info.start_with?(p) } ? 'active' : ''
  end
end

# ── Routes ─────────────────────────────────────────────────────────────────────

get '/' do
  erb :index
end

# Customization – step 1: pick micronutrient
get '/customization' do
  @micronutrients = MICRONUTRIENTS.values
  erb :customization
end

# Customization – step 2: pick metric, order, and extra columns
get '/customization/options' do
  @mn_id         = params[:mn_id].to_s
  @micronutrient = MICRONUTRIENTS[@mn_id]
  halt 400, 'Unknown micronutrient' unless @micronutrient
  @metrics = SorterList::METRICS
  erb :customization_options
end

# Customization – step 3: results table
get '/customization/result' do
  @mn_id  = params[:mn_id].to_s
  metric  = params[:metric].to_s
  order   = params[:order]&.to_sym
  side    = Array(params[:side]).map(&:to_s)

  @micronutrient = MICRONUTRIENTS[@mn_id]
  halt 400, 'Unknown micronutrient' unless @micronutrient

  redirect '/effects' if metric == '4'

  halt 400, 'Unknown metric' unless SorterList::METRICS.key?(metric)
  halt 400, 'Unknown order'  unless %i[asc desc].include?(order)

  @sorted_foods = SorterList.sort_foods(@micronutrient.foods, metric, order)
  @metric       = metric
  @order        = order
  @display_keys = ([metric] + side.select { |k| SorterList::METRICS.key?(k) && k != metric }).uniq
  @metrics      = SorterList::METRICS
  erb :customization_result
end

# Categories – step 1: pick category
get '/categories' do
  @categories = FoodCategory::ALL.select { |cat| FOODS.values.any? { |f| f.category == cat } }
  erb :categories
end

# Categories – result: foods in category
get '/categories/result' do
  @category       = params[:category].to_s
  halt 400, 'Unknown category' unless FoodCategory::ALL.include?(@category)
  @foods          = FOODS.values.select { |f| f.category == @category }.sort_by(&:name)
  @micronutrients = MICRONUTRIENTS
  erb :categories_result
end

# Metric overview – step 1: pick metric
get '/metric_overview' do
  @metrics = SorterList::METRICS
  erb :metric_overview
end

# Metric overview – result (or redirect to effects for metric 4)
get '/metric_overview/result' do
  metric = params[:metric].to_s
  halt 400, 'Unknown metric' unless SorterList::METRICS.key?(metric)

  redirect '/effects' if metric == '4'

  order = params[:order]&.to_sym
  halt 400, 'Unknown order' unless %i[asc desc].include?(order)

  @sorted_foods = SorterList.sort_foods(FOODS.values, metric, order)
  @metric       = metric
  @order        = order
  @metrics      = SorterList::METRICS
  erb :metric_overview_result
end

# Effects – step 1: pick effect category
get '/effects' do
  @effects = SorterList.parse_effects
  halt 503, 'No effects data available' if @effects.empty?
  erb :effects
end

# Effects – result: foods for chosen effect
get '/effects/result' do
  @category = params[:category].to_s
  effects   = SorterList.parse_effects
  entries   = effects[@category]
  halt 400, 'Unknown effect category' unless entries

  # When showing Energy, inject banana (Pyridoxine), then exclude Exercise foods
  # unless they are banana.
  if @category == 'Energy'
    exercise_ids = (effects['Exercise & Performance'] || []).map { |e| e[:id] }.to_set
    existing_ids = entries.map { |e| e[:id] }.to_set

    # Inject banana if it's not already in Energy
    banana = FOODS['banana']
    if banana && !existing_ids.include?(banana.id.to_s)
      entries = entries + [{
        id:             banana.id.to_s,
        name:           banana.name,
        micronutrients: 'Pyridoxine (B6)',
        mechanism:      'Pyridoxine (B6) is a coenzyme in amino-acid and carbohydrate metabolism, directly supporting cellular energy production.'
      }]
    end

    # Exclude Exercise foods, but keep banana regardless
    entries = entries.reject { |e| exercise_ids.include?(e[:id]) && e[:name].downcase != 'banana' }
  end

  # Build a downcased set of Vitamin P (flavonoid) micronutrient names
  vit_p_names = MICRONUTRIENTS.values
                  .select { |mn| mn.category.to_s.include?('Vitamin P') }
                  .map    { |mn| mn.name.downcase }

  # Foods that mention at least one Vitamin P micronutrient come first; order within each group is preserved
  @entries = entries.sort_by.with_index do |e, i|
    has_vit_p = e[:micronutrients].downcase.split(/,\s*/).any? { |n| vit_p_names.include?(n.strip) }
    [has_vit_p ? 0 : 1, i]
  end

  erb :effects_result
end

# Shopping – step 1: pick day
get '/shopping' do
  @all_days  = CheckList.load_shopping_list_by_day
  @day_order = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
  erb :shopping
end

# Shopping – result: micronutrient coverage report
get '/shopping/result' do
  valid_days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
  @day       = params[:day].to_s
  halt 400, 'Unknown day' unless valid_days.include?(@day)

  all_days       = CheckList.load_shopping_list_by_day
  @shopping_list = all_days.fetch(@day, [])
  @unknown       = @shopping_list.reject { |item| FOODS.key?(item) }
  @covered       = []
  @not_covered   = []

  MICRONUTRIENTS.each_value do |mn|
    matches = mn.foods.select { |food| @shopping_list.include?(food.name.downcase) }
    if matches.any?
      @covered << { mn: mn, matches: matches }
    else
      @not_covered << mn
    end
  end

  @total_mn     = MICRONUTRIENTS.size
  @coverage_pct = @total_mn.zero? ? 0.0 : (@covered.size.to_f / @total_mn * 100).round(1)
  erb :shopping_result
end
