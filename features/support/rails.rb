PROJECT_ROOT     = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
APP_NAME         = 'testapp'.freeze
BUNDLE_ENV_VARS = %w(RUBYOPT BUNDLE_PATH BUNDLE_BIN_PATH BUNDLE_GEMFILE)
ORIGINAL_BUNDLE_VARS = Hash[ENV.select{ |key,value| BUNDLE_ENV_VARS.include?(key) }]

ENV['RAILS_ENV'] = 'test'

Before do
  ENV['BUNDLE_GEMFILE'] = File.join(Dir.pwd, ENV['BUNDLE_GEMFILE']) unless ENV['BUNDLE_GEMFILE'].start_with?(Dir.pwd)
  @framework_version = nil
end

After do
  ORIGINAL_BUNDLE_VARS.each_pair do |key, value|
    ENV[key] = value
  end
end

When /^I reset Bundler environment variable$/ do
  BUNDLE_ENV_VARS.each do |key|
    ENV[key] = nil
  end
end

module RailsCommandHelpers
  def framework_version?(version_string)
    framework_version =~ /^#{version_string}/
  end

  def framework_version
    @framework_version ||= `rails -v`[/^Rails (.+)$/, 1]
  end

  def framework_major_version
    framework_version.split(".").first.to_i
  end

  def new_application_command(app_name)
    framework_major_version >= 3 ? "rails new #{app_name} --skip-sprockets --skip-javascript --skip-bundle" : "rails"
  end

  def generator_command
    framework_major_version >= 3 ? "rails generate" : "script/generate"
  end

  def runner_command
    framework_major_version >= 3 ? "rails runner" : "script/runner"
  end

  def rails2_generator_name(rails3_generator_name)
    case rails3_generator_name
    when "paperclip_database:migration" then "paperclip_database"
    else rails3_generator_name
    end
  end

end

module PaperclipGemHelpers
  def paperclip_version?(version_string)
    paperclip_version =~ /^#{version_string}/
  end

  def paperclip_version
    @paperclip_version = Gem::Specification.find_by_name('paperclip').version.to_s
  end
end

World(RailsCommandHelpers)
World(PaperclipGemHelpers)
