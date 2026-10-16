# Adds the DayByDayTests unit test target and a shared DayByDay scheme.
require 'xcodeproj'

project_path = File.expand_path('../DayByDay.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)
app = project.targets.find { |t| t.name == 'DayByDay' }
abort 'DayByDayTests already exists' if project.targets.any? { |t| t.name == 'DayByDayTests' }

tests = project.new_target(:unit_test_bundle, 'DayByDayTests', :ios, '17.5')
tests.add_dependency(app)

group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
group.path = 'DayByDayTests'
group.source_tree = '<group>'
project.main_group.children << group
tests.file_system_synchronized_groups ||= []
tests.file_system_synchronized_groups << group

tests.build_configurations.each do |config|
  s = config.build_settings
  s['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/DayByDay.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DayByDay'
  s['BUNDLE_LOADER'] = '$(TEST_HOST)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{app.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}.tests"
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SWIFT_APPROACHABLE_CONCURRENCY'] = 'YES'
  s['SWIFT_DEFAULT_ACTOR_ISOLATION'] = 'MainActor'
  s['DEVELOPMENT_TEAM'] = app.build_configurations.first.build_settings['DEVELOPMENT_TEAM']
  s['CODE_SIGN_STYLE'] = 'Automatic'
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app, tests)
scheme.test_action.code_coverage_enabled = false
scheme.save_as(project_path, 'DayByDay', true)
