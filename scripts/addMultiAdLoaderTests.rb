#!/usr/bin/env ruby
# frozen_string_literal: true

# One-off helper. Run it once from the repo root (needs the `xcodeproj` gem, it is installed with CocoaPods):
#
#     ruby scripts/addMultiAdLoaderTests.rb
#
# What it does to EventHandlers/EventHandlers.xcodeproj (idempotent - safe to run again):
#   1. wires the missing target dependencies between the new framework targets
#        PrebidMultiAdLoader       -> PrebidRemoteConfig
#        PrebidMultiAdLoaderGAM    -> PrebidMultiAdLoader, PrebidRemoteConfig
#        PrebidMultiAdLoaderYandex -> PrebidMultiAdLoader, PrebidRemoteConfig
#      and links PrebidMobile.framework into PrebidRemoteConfig / PrebidMultiAdLoader
#      (the same way the existing PrebidMobile*Adapters targets do);
#   2. creates three unit-test targets from the Swift files next to the project:
#        PrebidMultiAdLoaderTests        <- EventHandlers/PrebidMultiAdLoaderTests        (core + remote config)
#        PrebidMultiAdLoaderGAMTests     <- EventHandlers/PrebidMultiAdLoaderGAMTests     (needs GoogleMobileAds)
#        PrebidMultiAdLoaderYandexTests  <- EventHandlers/PrebidMultiAdLoaderYandexTests  (needs YandexMobileAds)
#   3. creates a shared scheme per test target (used by scripts/testPrebidMobileAdapters.sh).
#
# It does NOT touch the Podfile. GoogleMobileAds / YandexMobileAds must still be linked into the
# GAM / Yandex framework AND test targets - see the hint printed at the end.

begin
  require 'xcodeproj'
rescue LoadError
  abort 'The xcodeproj gem is missing. Run: gem install xcodeproj (or gem install cocoapods)'
end

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'EventHandlers', 'EventHandlers.xcodeproj')
DEPLOYMENT_TARGET = '13.0'

FRAMEWORK_DEPENDENCIES = {
  'PrebidMultiAdLoader' => %w[PrebidRemoteConfig],
  'PrebidMultiAdLoaderGAM' => %w[PrebidMultiAdLoader PrebidRemoteConfig],
  'PrebidMultiAdLoaderYandex' => %w[PrebidMultiAdLoader PrebidRemoteConfig]
}.freeze

LINK_PREBID_MOBILE = %w[PrebidRemoteConfig PrebidMultiAdLoader].freeze

# name: test target / folder name; framework: the module under test (also the scheme's build target);
# depends_on: frameworks the tests link against.
TEST_TARGETS = [
  {
    name: 'PrebidMultiAdLoaderTests',
    framework: 'PrebidMultiAdLoader',
    depends_on: %w[PrebidMultiAdLoader PrebidRemoteConfig]
  },
  {
    name: 'PrebidMultiAdLoaderGAMTests',
    framework: 'PrebidMultiAdLoaderGAM',
    depends_on: %w[PrebidMultiAdLoaderGAM PrebidMultiAdLoader PrebidRemoteConfig]
  },
  {
    name: 'PrebidMultiAdLoaderYandexTests',
    framework: 'PrebidMultiAdLoaderYandex',
    depends_on: %w[PrebidMultiAdLoaderYandex PrebidMultiAdLoader PrebidRemoteConfig]
  }
].freeze

abort "Project not found: #{PROJECT_PATH}" unless File.directory?(PROJECT_PATH)

project = Xcodeproj::Project.open(PROJECT_PATH)

def find_target(project, name)
  project.targets.find { |t| t.name == name } || abort("Target #{name} not found in #{PROJECT_PATH}")
end

def link(target, file_reference)
  phase = target.frameworks_build_phase
  phase.add_file_reference(file_reference, true) unless phase.files_references.include?(file_reference)
end

def add_dependency(target, dependency)
  target.add_dependency(dependency) unless target.dependencies.any? { |d| d.target == dependency }
  link(target, dependency.product_reference)
end

# 1. Dependencies between the framework targets
FRAMEWORK_DEPENDENCIES.each do |name, dependency_names|
  target = find_target(project, name)
  dependency_names.each { |dependency_name| add_dependency(target, find_target(project, dependency_name)) }
end

prebid_mobile_ref = project.frameworks_group.files.find { |f| f.path == 'PrebidMobile.framework' }
if prebid_mobile_ref
  LINK_PREBID_MOBILE.each { |name| link(find_target(project, name), prebid_mobile_ref) }
else
  warn 'warning: PrebidMobile.framework reference not found in the Frameworks group; link it manually.'
end

# 2. Unit-test targets
test_targets = TEST_TARGETS.map do |config|
  name = config[:name]
  sources_dir = File.join(ROOT, 'EventHandlers', name)
  unless File.directory?(sources_dir)
    warn "warning: #{sources_dir} not found, skipping #{name}"
    next nil
  end

  test_target = project.targets.find { |t| t.name == name }
  test_target ||= project.new_target(:unit_test_bundle, name, :ios, DEPLOYMENT_TARGET, nil, :swift)

  group = project.main_group.children.find { |c| c.display_name == name }
  group ||= project.main_group.new_group(name, name)

  Dir.glob(File.join(sources_dir, '*.swift')).sort.each do |path|
    file_name = File.basename(path)
    ref = group.files.find { |f| f.path == file_name } || group.new_file(file_name)
    test_target.add_file_references([ref]) unless test_target.source_build_phase.files_references.include?(ref)
  end

  test_target.build_configurations.each do |build_config|
    settings = build_config.build_settings
    # Explicit on purpose: don't rely on xcodeproj's default for a target that may
    # already exist from an earlier partial run — an empty PRODUCT_NAME collapses the
    # test bundle's wrapper AND its linked executable onto the exact same output path
    # ("Multiple commands produce '.../.xctest'").
    settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = "org.prebid.#{name}"
    settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    settings['SWIFT_VERSION'] = '5.0'
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    settings['ENABLE_TESTABILITY'] = 'YES' if build_config.name == 'Debug'
  end

  config[:depends_on].each { |dependency_name| add_dependency(test_target, find_target(project, dependency_name)) }
  link(test_target, prebid_mobile_ref) if prebid_mobile_ref

  [config, test_target]
end.compact

project.save

# 3. Shared schemes
test_targets.each do |config, test_target|
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(find_target(project, config[:framework]))
  scheme.add_build_target(test_target)
  scheme.add_test_target(test_target)
  scheme.save_as(PROJECT_PATH, config[:name], true)
  puts "Done: #{config[:name]} target and scheme created."
end

puts <<~HINT

  Next steps:
    1. GoogleMobileAds / YandexMobileAds must be linked into the GAM / Yandex frameworks and into their test targets.
       With CocoaPods, add to the Podfile (adapt to how the other EventHandlers targets are declared there):

         target 'PrebidMultiAdLoaderGAM'          { pod 'Google-Mobile-Ads-SDK', '>= 13.6.0' }
         target 'PrebidMultiAdLoaderGAMTests'     { pod 'Google-Mobile-Ads-SDK', '>= 13.6.0' }
         target 'PrebidMultiAdLoaderYandex'       { pod 'YandexMobileAds', '8.4.0' }
         target 'PrebidMultiAdLoaderYandexTests'  { pod 'YandexMobileAds', '8.4.0' }

    2. pod install
    3. xcodebuild -workspace PrebidMobile.xcworkspace -scheme PrebidMultiAdLoaderTests -sdk iphonesimulator test
HINT
