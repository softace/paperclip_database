require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

desc 'Default: clean, appraisal:install, all.'
task :default => [:clean, :all]

desc 'Test the paperclip_database plugin under all supported Rails versions.'
task :all do |t|
  if ENV['BUNDLE_GEMFILE']
    exec('rake spec cucumber')
  else
    exec("rm gemfiles/*.lock")
    Rake::Task["appraisal:gemfiles"].execute
    Rake::Task["appraisal:install"].execute
    exec('rake appraisal')
  end
end

desc 'Test the paperclip_database plugin.'
RSpec::Core::RakeTask.new(:spec)

desc 'Run integration test'
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--format progress}
end

desc 'Start an IRB session with all necessary files required.'
task :shell do |t|
  chdir File.dirname(__FILE__)
  exec 'irb -I lib/ -I lib/paperclip_database -r rubygems -r active_record -r paperclip -r tempfile -r init'
end

desc 'Clean up files.'
task :clean do |t|
  FileUtils.rm_rf "doc"
  FileUtils.rm_rf "tmp"
  FileUtils.rm_rf "pkg"
  FileUtils.rm_rf "public"
  Dir.glob("paperclip_database-*.gem").each{|f| FileUtils.rm f }
end
