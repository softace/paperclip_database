require 'spec_helper'

module Namespace
end

describe "PaperclipDatabase" do
  describe "Namespaced model" do
    before(:each) do
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
    after(:each) do
      ActiveRecord::Base.connection.drop_table :namespace_models
      ActiveRecord::Base.connection.drop_table :namespace_model_avatars
      ActiveRecord::Base.clear_cache!
    end

    it "detects namespace" do
      expect(@model.avatar.instance_variable_get(:@paperclip_class_module)).to eq Namespace
    end

    it "has correct association name" do
      expect(@model.avatar.instance_variable_get(:@paperclip_files_association_name)).to eq 'model_avatar_paperclip_files'
    end

    it "has correct model constant" do
      expect(@model.avatar.instance_variable_get(:@paperclip_file_model)).to eq Namespace::ModelAvatarPaperclipFile
    end

    it "has correct table name" do
      expect(@model.avatar.instance_variable_get(:@database_table)).to eq 'namespace_model_avatars'
    end

    it "has association" do
      expect(@model.methods.include?(:model_avatar_paperclip_files)).to be_truthy
    end
  end
end
