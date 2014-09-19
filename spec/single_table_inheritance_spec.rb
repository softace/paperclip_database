require 'spec_helper'

describe "PaperclipDatabase" do
  describe "Single table inheritance" do
    before(:example) do
      create_model_tables :users, :avatars
      build_model 'User', nil, :avatar, {}

      Object.const_set('SuperUser', Class.new(User))

      @model = SuperUser.new
      file = File.open(fixture_file('5k.png'))

      @model.avatar = file
      @model.save
    end
    after(:example) do
      reset_activerecord
      reset_database :users, :avatars
      Object.send(:remove_const, 'SuperUser')
    end

    it "has correct association name" do
      expect(@model.avatar.instance_variable_get(:@paperclip_files_association_name)).to eq 'paperclip_files'
    end

    it "has correct model constant" do
      expect(@model.avatar.instance_variable_get(:@paperclip_file_model).to_s).to eq 'User::UserAvatarPaperclipFile'
    end

    it "has correct table name" do
      expect(@model.avatar.instance_variable_get(:@database_table)).to eq 'avatars'
    end

    it "has association" do
      expect(@model.methods.include?(:paperclip_files)).to be_truthy
    end
  end
end
