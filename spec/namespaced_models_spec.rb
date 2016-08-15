require 'spec_helper'

describe "PaperclipDatabase" do
  describe "Namespaced model" do
    before(:context) do
      Object.const_set('Namespace', Module.new())
      create_model_tables :namespace_models, :namespace_model_avatars, 'avatar'
      build_model 'Namespace::Model', 'namespace_models', :avatar, {:database_table => :namespace_model_avatars}

      @model = Namespace::Model.new
      file = File.open(fixture_file('5k.png'))

      @model.avatar = file
      @model.save

    end
    after(:context) do
      reset_activerecord
      reset_database :namespace_models, :namespace_model_avatars
      Object.send(:remove_const, 'Namespace')
    end

    it "has correct association name" do
      expect(@model.avatar.instance_variable_get(:@paperclip_files_association_name)).to eq 'namespace_model_avatar_paperclip_files'
    end

    it "has correct model constant" do
      expect(@model.avatar.instance_variable_get(:@paperclip_file_model).to_s).to eq 'Namespace::Model::NamespaceModelAvatarPaperclipFile'
    end

    it "has correct table name" do
      expect(@model.avatar.instance_variable_get(:@database_table)).to eq 'namespace_model_avatars'
    end

    it "has association" do
      expect(@model.methods.include?(:namespace_model_avatar_paperclip_files)).to be_truthy
    end
  end
end
