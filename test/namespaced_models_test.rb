require File.expand_path("../test_helper", __FILE__)

module Namespace
end

class NamespacedModelsTest < Test::Unit::TestCase
  def setup
    reset_class("Namespace::Model").tap do |klass|
      klass.table_name = 'namespace_models'
      klass.has_attached_file :avatar, :storage => :database,
                                       :database_table => :namespace_model_avatars
      klass.validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
    end

    ActiveRecord::Base.connection.create_table :namespace_models, :force => true do |table|
      table.column :avatar_file_name, :string
      table.column :avatar_content_type, :string
      table.column :avatar_file_size, :integer
      table.column :avatar_updated_at, :datetime
      table.column :avatar_fingerprint, :string
    end
    ActiveRecord::Base.connection.create_table :namespace_model_avatars, :force => true do |table|
      table.column :namespace_model_id, :integer
      table.column :style, :string
      table.column :file_contents, :binary
    end

    @model = Namespace::Model.new
    file = File.open(fixture_file('5k.png'))

    @model.avatar = file
    @model.save
  end

  def test_namespaced_model_detection
    assert_equal(Namespace, @model.avatar.instance_variable_get(:@paperclip_class_module))
  end

  def test_association_name
    assert_equal('model_avatar_paperclip_files', @model.avatar.instance_variable_get(:@paperclip_files_association_name))
  end

  def test_model_constant
    assert_equal(Namespace::ModelAvatarPaperclipFile, @model.avatar.instance_variable_get(:@paperclip_file_model))
  end

  def test_table_name
    assert_equal('namespace_model_avatars', @model.avatar.instance_variable_get(:@database_table))
  end

  def test_association
    assert(@model.methods.include?(:model_avatar_paperclip_files))
  end
end
