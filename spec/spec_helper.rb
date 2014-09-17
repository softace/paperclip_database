$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'paperclip_database'
require 'active_record'
require 'active_support'
require 'active_support/core_ext'
require 'yaml'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])
Paperclip.options[:logger] = ActiveRecord::Base.logger


# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end

def reset_activerecord
  if Gem::Version.new(::ActiveModel::VERSION::STRING) < Gem::Version.new('3.1.0')
    ActiveRecord::Base.descendants.each do |model|
      model.reset_column_information
    end
  else
    ActiveRecord::Base.clear_cache!
  end
end

def reset_class class_name
  if class_name.include? '::'
    module_name = PaperclipDatabase::deconstantize(class_name)
    class_module = module_name.constantize rescue Object
  else
    class_module = Object
  end
  class_name = class_name.demodulize

  ActiveRecord::Base.send(:include, Paperclip::Glue)
  class_module.send(:remove_const, class_name) rescue nil
  klass = class_module.const_set(class_name, Class.new(ActiveRecord::Base))

  klass.class_eval do
    include Paperclip::Glue
  end

  klass
end

def fixture_file(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end
