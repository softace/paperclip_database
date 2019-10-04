Given /^I generate a new rails application$/ do
  steps %{
    When I successfully run `bundle exec #{new_application_command(APP_NAME)}`
    And I cd to "#{APP_NAME}"
    And I turn off class caching
    And I fix the application.rb for 3.0.12
    And I remove turbolinks
    And I empty the application.js file
    And I configure the application to use "paperclip_database" from this project
    And I reset Bundler environment variable
    And I successfully run `bundle install --local`
  }
end

Given "I fix the application.rb for 3.0.12" do
  ##See https://github.com/rails/rails/issues/9619
  in_current_directory do
    File.open("config/application.rb", "a") do |f|
      f << "ActionController::Base.config.relative_url_root = ''"
    end
  end
end

Given "I allow the attachment to be submitted" do
  in_current_directory do
    if framework_major_version == 3
      transform_file("app/models/user.rb") do |content|
        content.gsub("attr_accessible :name",
                     "attr_accessible :name, :avatar")
      end
    else
      transform_file("app/controllers/users_controller.rb") do |content|
        content.gsub("params.require(:user).permit(:name)",
                     "params.require(:user).permit!")
      end
    end
  end
end

Given "I remove turbolinks" do
  in_current_directory do
    transform_file("app/assets/javascripts/application.js") do |content|
      content.gsub("//= require turbolinks", "")
    end
    transform_file("app/views/layouts/application.html.erb") do |content|
      content.gsub(', "data-turbolinks-track" => true', "")
    end
  end
end

Given "I empty the application.js file" do
  in_current_directory do
    transform_file("app/assets/javascripts/application.js") do |content|
      ""
    end
  end
end

Given /^I run a "(.*?)" generator to generate a "(.*?)" scaffold with "(.*?)"$/ do |generator_name, model_name, attributes|
  step %[I successfully run `bundle exec #{generator_command} #{generator_name} #{model_name} #{attributes}`]
end

Given /^I run a "(.*?)" generator to add a paperclip "(.*?)" to the "(.*?)" model$/ do |generator_name, attachment_name, model_name|
  step %[I successfully run `bundle exec #{generator_command} #{generator_name} #{model_name} #{attachment_name}`]
end

Given /^I run a "(.*?)" generator to create storage for paperclip "(.*?)" to the "(.*?)" model$/ do |generator_name, attachment_name, model_name|
  step %[I successfully run `bundle exec #{generator_command} #{generator_name} #{model_name} #{attachment_name}`]
end

Given /^I run a migration$/ do
  step %[I successfully run `bundle exec rake db:migrate`]
end

Given /^I update my new user view to include the file upload field$/ do
  steps %{
    Given I overwrite "app/views/users/new.html.erb" with:
      """
      <%= form_for @user, :html => { :multipart => true } do |f| %>
        <%= f.label :name %>
        <%= f.text_field :name %>
        <%= f.label :avatar %>
        <%= f.file_field :avatar %>
        <%= submit_tag "Submit" %>
      <% end %>
      """
  }
end

Given /^I update my user view to include the attachment$/ do
  steps %{
    Given I overwrite "app/views/users/show.html.erb" with:
      """
      <p>Name: <%= @user.name %></p>
      <p>Avatar: <%= image_tag @user.avatar.url %></p>
      """
  }
end

Given /^I add this snippet to the User model:$/ do |snippet|
  file_name = "app/models/user.rb"
  in_current_directory do
    content = File.read(file_name)
    File.open(file_name, 'w') { |f| f << content.sub(/end\Z/, "#{snippet}\nend") }
  end
end

Given /^I replace \/(.*?)\/ with this snippet in the "(.*?)" controller:$/ do |pattern, controller_name, snippet|
  in_current_directory do
    transform_file("app/controllers/#{controller_name}_controller.rb") do |content|
      content.gsub(Regexp.new(pattern, Regexp::MULTILINE), snippet)
    end
  end
end

Given /^I start the rails application$/ do
  in_current_directory do
    require "./config/environment"
    require "capybara/rails"
  end
end

Given /^I reload my application$/ do
  Rails::Application.reload!
end

When %r{I turn off class caching} do
  in_current_directory do
    file = "config/environments/test.rb"
    config = IO.read(file)
    config.gsub!(%r{^\s*config.cache_classes.*$},
                 "config.cache_classes = false")
    File.open(file, "w"){|f| f.write(config) }
  end
end

Then /^the file at "([^"]*)" should be the same as "([^"]*)"$/ do |web_file, path|
  expected = IO.binread(path)
  actual = if web_file.match %r{^https?://}
    Net::HTTP.get(URI.parse(web_file))
  else
    visit(web_file)
    page.source
  end
  expect(actual).to eq expected
end

When /^I configure the application to use "([^\"]+)" from this project$/ do |name|
  append_to_gemfile "gem '#{name}', :path => '#{PROJECT_ROOT}'"
  steps %{And I run `bundle install --local`}
end

When /^I configure the application to use "([^\"]+)"$/ do |gem_name|
  append_to_gemfile "gem '#{gem_name}'"
end

When /^I append gems from Appraisal Gemfile$/ do
  File.read(ENV['BUNDLE_GEMFILE']).split(/\n/).each do |line|
    if line =~ /^gem "(?!rails|appraisal)/
      append_to_gemfile line.strip
    end
  end
end

When /^I comment out the gem "(.*?)" from the Gemfile$/ do |gemname|
  comment_out_gem_in_gemfile gemname
end

Then /^the result of "(.*?)" should be the same as "(.*?)"$/ do |rails_expr, path|
  expected = IO.binread(path)
  actual = eval "#{rails_expr}"
  expect(actual).to eq expected
end


module FileHelpers
  def append_to(path, contents)
    in_current_directory do
      File.open(path, "a") do |file|
        file.puts
        file.puts contents
      end
    end
  end

  def append_to_gemfile(contents)
    append_to('Gemfile', contents)
  end

  def comment_out_gem_in_gemfile(gemname)
    in_current_directory do
      gemfile = File.read("Gemfile")
      gemfile.sub!(/^(\s*)(gem\s*['"]#{gemname})/, "\\1# \\2")
      File.open("Gemfile", 'w'){ |file| file.write(gemfile) }
    end
  end

  def transform_file(filename)
    if File.exists?(filename)
      content = File.read(filename)
      File.open(filename, "w") do |f|
        content = yield(content)
        f.write(content)
      end
    end
  end
end

World(FileHelpers)
