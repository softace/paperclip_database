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

def reset_database(*tables)
  tables.each do |table|
    ActiveRecord::Base.connection.drop_table table
  end
end

def create_model_tables(model_table_name, attachment_table_name, association_name = nil)
  association_name ||= attachment_table_name.to_s.singularize
  ActiveRecord::Base.connection.create_table model_table_name, :force => true do |table|
    table.column :"#{association_name}_file_name", :string
    table.column :"#{association_name}_content_type", :string
    table.column :"#{association_name}_file_size", :integer
    table.column :"#{association_name}_updated_at", :datetime
    table.column :"#{association_name}_fingerprint", :string
  end
  single_model = model_table_name.to_s.singularize
  ActiveRecord::Base.connection.create_table attachment_table_name, :force => true do |table|
    table.column :"#{single_model}_id", :integer
    table.column :style, :string
    table.column :file_contents, :binary
  end
end

def build_model(name, table_name, attachment_name, paperclip_options)
  reset_class(name, attachment_name).tap do |klass|
    klass.table_name = table_name if table_name
    klass.has_attached_file attachment_name, {:storage => :database}.merge(paperclip_options)
    klass.validates_attachment_content_type attachment_name, :content_type => /\Aimage\/.*\Z/
  end
end

def reset_class class_name, attachment_name
  if class_name.include? '::'
    module_name = PaperclipDatabase::deconstantize(class_name)
    class_module = module_name.constantize rescue Object
  else
    class_module = Object
  end
  class_name = class_name.demodulize

  ActiveRecord::Base.send(:include, Paperclip::Glue)

  class_module.send(:remove_const, "#{class_name}#{attachment_name.to_s.classify}PaperclipFile") rescue nil
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
