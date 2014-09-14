require 'rubygems'
require 'tempfile'
require 'pathname'
if Gem.loaded_specs['rails'].version.to_s[0..2] == "4.0"
  require 'minitest/unit'
else
  require 'minitest/test'
end
require 'active_record'
require 'active_record/version'
require 'active_support'
require 'active_support/core_ext'
require 'mocha/setup'
require 'ostruct'
require 'paperclip'

ROOT = Pathname(File.expand_path(File.join(File.dirname(__FILE__), '..')))

module Rails
  module RailsVersion
    STRING = Gem.loaded_specs['rails'].version.to_s
  end
  VERSION = RailsVersion

  def root
    Pathname.new(ROOT).join('tmp')
  end
  def self.env
    'test'
  end
end

$LOAD_PATH << File.join(ROOT, 'lib')
$LOAD_PATH << File.join(ROOT, 'lib', 'paperclip')
$LOAD_PATH << File.join(ROOT, 'lib', 'paperclip_database')

require File.join(ROOT, 'lib', 'paperclip_database.rb')

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])
Paperclip.options[:logger] = ActiveRecord::Base.logger

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

  klass.reset_column_information
  klass.connection_pool.clear_table_cache!(klass.table_name) if klass.connection_pool.respond_to?(:clear_table_cache!)
  klass.connection.schema_cache.clear_table_cache!(klass.table_name) if klass.connection.respond_to?(:schema_cache)
  klass
end

def reset_table table_name, &block
  block ||= lambda { |table| true }
  ActiveRecord::Base.connection.create_table :dummies, {:force => true}, &block
end

def modify_table table_name, &block
  ActiveRecord::Base.connection.change_table :dummies, &block
end

def rebuild_model options = {}
  ActiveRecord::Base.connection.create_table :dummies, :force => true do |table|
    table.column :title, :string
    table.column :other, :string
    table.column :avatar_file_name, :string
    table.column :avatar_content_type, :string
    table.column :avatar_file_size, :integer
    table.column :avatar_updated_at, :datetime
    table.column :avatar_fingerprint, :string
  end
  rebuild_class options
end

def rebuild_class options = {}
  reset_class("Dummy").tap do |klass|
    klass.has_attached_file :avatar, options
    Paperclip.reset_duplicate_clash_check!
  end
end

def rebuild_meta_class_of obj, options = {}
  (class << obj; self; end).tap do |metaklass|
    metaklass.has_attached_file :avatar, options
    Paperclip.reset_duplicate_clash_check!
  end
end

def fixture_file(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end
