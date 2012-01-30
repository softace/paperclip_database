class PaperclipDatabaseGenerator < Rails::Generator::NamedBase
  attr_accessor :attachments, :migration_name

  def initialize(args, options = {})
    super
    @class_name, @attachments = args[0], args[1..-1]
  end

  def manifest
    file_name = generate_file_name
    @migration_name = file_name.camelize
    record do |m|
      m.migration_template "paperclip_database_migration.rb.erb",
                           File.join('db', 'migrate'),
                           :migration_file_name => file_name
    end
  end

  private

  def generate_file_name
    debugger
    names = attachments.map{|a| "#{class_name.underscore}_#{a.pluralize}" }
    names = names[0..-2] + ["and", names[-1]] if names.length > 1
    "create_#{names.join('_')}"
  end

end
