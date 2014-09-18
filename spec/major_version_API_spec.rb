require 'spec_helper'

module Namespace
end

##
## named subject 'association' is the SUT
# args can be
# [:table_name] The table name
#
shared_examples_for "major version API compatible" do |args|
  table_name = args[:table_name]
  describe "Major version compatible with table name '#{table_name}'" do
    it "has table name '#{table_name}'" do
      expect(association.instance_variable_get(:@database_table)).to eq table_name
    end
  end
end

describe "PaperclipDatabase" do
  describe "backward compatibility" do
    before(:example) do
      @model_table_name = defined?(model_table_name) ? model_table_name : model_name.tableize
      @attachment_table_name = defined?(attachment_table_name) ? attachment_table_name : attachment_name.tableize
      extra_paperclip_options = defined?(attachment_table_name)? {:database_table => :custom_avatars} : {}
      create_model_tables @model_table_name, @attachment_table_name, attachment_name
      build_model model_name, (defined?(model_table_name)? model_table_name: nil), attachment_name.to_sym, extra_paperclip_options
      @model = model_name.constantize.new
      file = File.open(fixture_file('5k.png'))

      @model.send(:"#{attachment_name}=",file)
      @model.save
    end
    subject(:association){@model.avatar}
    after(:example) do
      reset_activerecord
      reset_database @model_table_name, @attachment_table_name
    end

    describe "with default options" do
      let!(:model_name){'User'}
      let!(:attachment_name){'avatar'}
      it_behaves_like "major version API compatible", :table_name => 'avatars'
    end
    describe "with custom model table_name" do
      let(:model_name){'CUser'}
      let(:model_table_name){'custom_users'}
      let(:attachment_name){'avatar'}
      it_behaves_like "major version API compatible", :table_name => 'avatars'
    end
    describe "with custom attachment table_name" do
      let(:model_name){'AUser'}
      let(:attachment_name){'avatar'}
      let(:attachment_table_name){'custom_avatars'}
      it_behaves_like "major version API compatible", :table_name => 'custom_avatars'
    end
    describe "with custom model table_name and attachment table_name" do
      let(:model_name){'CaUser'}
      let(:model_table_name){'custom_users'}
      let(:attachment_name){'avatar'}
      let(:attachment_table_name){'custom_avatars'}
      it_behaves_like "major version API compatible", :table_name => 'custom_avatars'
    end
  end
end
