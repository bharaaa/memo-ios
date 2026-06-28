require 'xcodeproj'

project_path = '/Users/bharaalfha/02_Coding_Projects/Memo/Memo.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Add the Pipeline group under AI if it doesn't exist
ai_group = project.main_group.find_subpath(File.join('Memo', 'AI'), true)
pipeline_group = ai_group.find_subpath('Pipeline', true)
pipeline_group.set_source_tree('<group>')
pipeline_group.set_path('Pipeline')

files = [
  'Memo/AI/Pipeline/TransactionParsingModels.swift',
  'Memo/AI/Pipeline/LocalParser.swift',
  'Memo/AI/Pipeline/TransactionMergeEngine.swift',
  'Memo/AI/Pipeline/EscalationEngine.swift',
  'Memo/AI/Pipeline/TransactionParsingPipeline.swift'
]

files.each do |file_path|
  file_name = File.basename(file_path)
  # Check if file is already in the project to avoid duplicates
  unless pipeline_group.files.any? { |f| f.path == file_name }
    file_ref = pipeline_group.new_reference(file_name)
    target.add_file_references([file_ref])
    puts "Added #{file_name} to Xcode project"
  else
    puts "#{file_name} already in Xcode project"
  end
end

project.save
puts "Project saved successfully"
