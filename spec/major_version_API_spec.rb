require 'spec_helper'

##
## named subject 'attachment' is the SUT
# args can be
# [:table_name] The table name
#
shared_examples_for "major version API compatible" do |args|
  table_name = args[:table_name]
  describe "Major version compatible with table name '#{table_name}'" do
    subject{attachment}
    it "has table name '#{table_name}'" do
      expect(subject.instance_variable_get(:@database_table)).to eq table_name
    end
    ##Basic (common)
    it { is_expected.to respond_to(:exists?).with(1).argument }
    it { is_expected.to respond_to(:flush_writes).with(0).argument }
    it { is_expected.to respond_to(:flush_deletes).with(0).argument }
    it { is_expected.to respond_to(:copy_to_local_file).with(2).arguments }

    ##Database specific
    it { is_expected.to respond_to(:files).with(0).arguments }
    it { is_expected.to respond_to(:database_path).with(1).argument }
    it { is_expected.to respond_to(:to_file).with(1).argument }
    it { is_expected.to respond_to(:to_io).with(1).argument }
    it { is_expected.to respond_to(:file_for).with(1).argument }
    it { is_expected.to respond_to(:file_contents).with(1).argument }
  end
end

## named subject 'namespace' is the SUT
shared_examples_for "model" do |args|
  describe "with default options" do
    let!(:model_name){"#{namespace}User"}
    let!(:attachment_name){'avatar'}
    it_behaves_like "major version API compatible", :table_name => 'avatars'
  end
  describe "with custom model table_name" do
    let(:model_name){"#{namespace}CUser"}
    let(:model_table_name){'custom_users'}
    let(:attachment_name){'avatar'}
    it_behaves_like "major version API compatible", :table_name => 'avatars'
  end
  describe "with custom attachment table_name" do
    let(:model_name){"#{namespace}AUser"}
    let(:attachment_name){'avatar'}
    let(:attachment_table_name){'custom_avatars'}
    it_behaves_like "major version API compatible", :table_name => 'custom_avatars'
  end
  describe "with custom model table_name and custom attachment table_name" do
    let(:model_name){"#{namespace}SUser"}
    let(:model_table_name){'special_users'}
    let(:attachment_name){'avatar'}
    let(:attachment_table_name){'custom_avatars'}
    it_behaves_like "major version API compatible", :table_name => 'custom_avatars'
  end
end

describe "PaperclipDatabase" do
  before(:example) do
    @attachment_table_name = defined?(attachment_table_name) ? attachment_table_name : attachment_name.tableize
    extra_paperclip_options = defined?(attachment_table_name)? {:database_table => attachment_table_name.to_sym} : {}

    build_model model_name, (defined?(model_table_name)? model_table_name: nil), attachment_name.to_sym, extra_paperclip_options
    @model_table_name = model_name.constantize.table_name
    create_model_tables @model_table_name, @attachment_table_name, attachment_name
    @model = model_name.constantize.new
    file = File.open(fixture_file('5k.png'))

    @model.send(:"#{attachment_name}=",file)
    @model.save
  end
  subject(:attachment){@model.avatar}
  after(:example) do
    reset_activerecord
    reset_database @model_table_name, @attachment_table_name
  end

  describe "model with no namespace" do
    subject(:namespace){''}
    it_behaves_like "model"
  end
  describe "model in namespace 'Namespace::'" do
    before(:context) { Object.const_set('Namespace', Module.new()) }
    after(:context) { Object.send(:remove_const, 'Namespace') }
    subject(:namespace){'Namespace::'}
    it_behaves_like "model"
  end
end
