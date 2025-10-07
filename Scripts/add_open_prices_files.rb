#!/usr/bin/env ruby
# add_open_prices_files.rb
# Script to add Open Prices integration files to Xcode project

require 'xcodeproj'

project_path = 'Grocery-budget-optimizer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Grocery-budget-optimizer' }

unless target
  puts "❌ Could not find target 'Grocery-budget-optimizer'"
  exit 1
end

# Find the Network and Models groups
network_group = project.main_group['Grocery-budget-optimizer']['Data']['Network']
models_group = project.main_group['Grocery-budget-optimizer']['Data']['Network']['Models']

unless network_group && models_group
  puts "❌ Could not find required groups"
  puts "Looking for: Grocery-budget-optimizer/Data/Network/ and Models/"
  exit 1
end

files_added = []

# Add OpenPricesResponse.swift to Models group
response_file_path = 'Grocery-budget-optimizer/Data/Network/Models/OpenPricesResponse.swift'
if File.exist?(response_file_path)
  # Check if already in project
  existing = models_group.files.find { |f| f.path == 'OpenPricesResponse.swift' }
  
  unless existing
    file_ref = models_group.new_file(response_file_path)
    target.add_file_references([file_ref])
    files_added << 'OpenPricesResponse.swift'
    puts "✅ Added OpenPricesResponse.swift to Models group"
  else
    puts "ℹ️  OpenPricesResponse.swift already in project"
  end
else
  puts "❌ Could not find file: #{response_file_path}"
end

# Add OpenPricesService.swift to Network group  
service_file_path = 'Grocery-budget-optimizer/Data/Network/OpenPricesService.swift'
if File.exist?(service_file_path)
  # Check if already in project
  existing = network_group.files.find { |f| f.path == 'OpenPricesService.swift' }
  
  unless existing
    file_ref = network_group.new_file(service_file_path)
    target.add_file_references([file_ref])
    files_added << 'OpenPricesService.swift'
    puts "✅ Added OpenPricesService.swift to Network group"
  else
    puts "ℹ️  OpenPricesService.swift already in project"
  end
else
  puts "❌ Could not find file: #{service_file_path}"
end

# Save the project
if files_added.any?
  project.save
  puts "\n✅ Successfully added #{files_added.count} file(s) to Xcode project"
  puts "📝 Files added: #{files_added.join(', ')}"
  puts "\nNext steps:"
  puts "1. Open Xcode"
  puts "2. Build the project (⌘B)"
  puts "3. Check for any compilation errors"
else
  puts "\n✅ All files already in project"
end
