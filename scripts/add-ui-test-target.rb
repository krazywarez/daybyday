# Adds the DayByDayUITests UI test target to the project and the shared DayByDay scheme.
require 'xcodeproj'

project_path = File.expand_path('../DayByDay.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)
app = project.targets.find { |t| t.name == 'DayByDay' }
abort 'DayByDayUITests already exists' if project.targets.any? { |t| t.name == 'DayByDayUITests' }

tests = project.new_target(:ui_test_bundle, 'DayByDayUITests', :ios, '17.5')
tests.add_dependency(app)

group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
group.path = 'DayByDayUITests'
group.source_tree = '<group>'
project.main_group.children << group
tests.file_system_synchronized_groups ||= []
tests.file_system_synchronized_groups << group

tests.build_configurations.each do |config|
  s = config.build_settings
  s['TEST_TARGET_NAME'] = 'DayByDay'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{app.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}.uitests"
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['DEVELOPMENT_TEAM'] = app.build_configurations.first.build_settings['DEVELOPMENT_TEAM']
  s['CODE_SIGN_STYLE'] = 'Automatic'
end

project.save

scheme_path = File.join(project_path, 'xcshareddata', 'xcschemes', 'DayByDay.xcscheme')
scheme = Xcodeproj::XCScheme.new(scheme_path)
scheme.build_action.add_entry(Xcodeproj::XCScheme::BuildAction::Entry.new(tests).tap do |e|
  e.build_for_running = false
  e.build_for_profiling = false
  e.build_for_archiving = false
  e.build_for_analyzing = false
end)
scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(tests))
scheme.save!
