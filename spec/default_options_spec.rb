require 'spec_helper'

module Namespace
end

describe "PaperclipDatabase" do
  describe "default options" do
    before(:each) do
      ActiveRecord::Base.connection.create_table :users, :force => true do |table|
        table.column :avatar_file_name, :string
        table.column :avatar_content_type, :string
        table.column :avatar_file_size, :integer
        table.column :avatar_updated_at, :datetime
        table.column :avatar_fingerprint, :string
      end
      ActiveRecord::Base.connection.create_table :avatars, :force => true do |table|
        table.column :user_id, :integer
        table.column :style, :string
        table.column :file_contents, :binary
      end

      Object.send(:remove_const, "UserAvatarPaperclipFile") rescue nil
      reset_class("User").tap do |klass|
        klass.has_attached_file :avatar, :storage => :database
        klass.validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
      end

      @model = User.new
      file = File.open(fixture_file('5k.png'))

      @model.avatar = file
      @model.save

    end

    after(:each) do
      ActiveRecord::Base.connection.drop_table :users
      ActiveRecord::Base.connection.drop_table :avatars
      reset_activerecord
    end

    it "has backward compatible table name" do
      expect(@model.avatar.instance_variable_get(:@database_table)).to eq 'avatars'
    end

    it "detects no namespace" do
      expect(@model.avatar.instance_variable_get(:@paperclip_class_module)).to eq Object
    end

    it "has association name" do
      expect(@model.avatar.instance_variable_get(:@paperclip_files_association_name)).to eq 'user_avatar_paperclip_files'
    end

    it "has model constant" do
      expect(@model.avatar.instance_variable_get(:@paperclip_file_model).to_s).to eq 'UserAvatarPaperclipFile'
    end

    it "has association" do
      expect(@model.methods.include?(:user_avatar_paperclip_files)).to be_truthy
    end
  end
  describe "Namespaced model" do
    describe "default options" do
      before(:each) do
        ActiveRecord::Base.connection.create_table :users, :force => true do |table|
          table.column :avatar_file_name, :string
          table.column :avatar_content_type, :string
          table.column :avatar_file_size, :integer
          table.column :avatar_updated_at, :datetime
          table.column :avatar_fingerprint, :string
        end
        ActiveRecord::Base.connection.create_table :avatars, :force => true do |table|
          table.column :user_id, :integer
          table.column :style, :string
          table.column :file_contents, :binary
        end

        Namespace.send(:remove_const, :"UserAvatarPaperclipFile") rescue nil
        reset_class("Namespace::User").tap do |klass|
          klass.has_attached_file :avatar, :storage => :database
          klass.validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
        end

        @model = Namespace::User.new
        file = File.open(fixture_file('5k.png'))

        @model.avatar = file
        @model.save

      end
      after(:each) do
        ActiveRecord::Base.connection.drop_table :users
        ActiveRecord::Base.connection.drop_table :avatars
        reset_activerecord
      end

      it "has backward compatible table name" do
        expect(@model.avatar.instance_variable_get(:@database_table)).to eq 'avatars'
      end

      it "detects namespace" do
        expect(@model.avatar.instance_variable_get(:@paperclip_class_module)).to eq Namespace
      end

      it "has association name" do
        expect(@model.avatar.instance_variable_get(:@paperclip_files_association_name)).to eq 'user_avatar_paperclip_files'
      end

      it "has model constant" do
        expect(@model.avatar.instance_variable_get(:@paperclip_file_model).to_s).to eq 'Namespace::UserAvatarPaperclipFile'
      end

      it "has association" do
        expect(@model.methods.include?(:user_avatar_paperclip_files)).to be_truthy
      end
    end
  end
end
