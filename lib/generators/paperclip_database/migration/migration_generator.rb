require 'rails/generators/active_record'

module PaperclipDatabase
  module Generators
    class MigrationGenerator < ActiveRecord::Generators::Base
      desc "Create a migration to add database storage for the paperclip database storage." +
        "The NAME argument is the name of your model, and the following " +
        "arguments are the name of the attachments"

      argument :attachment_names,
      :required => true,
      :type => :array,
      :desc => "The names of the attachment(s) to add.",
      :banner => "attachment_one attachment_two attachment_three ..."

      def self.source_root
        @source_root ||= File.expand_path('../templates', __FILE__)
      end

      def generate_migration
        migration_template "migration.rb.erb", "db/migrate/#{migration_file_name}", migration_version: migration_version
      end

      def migration_name
        "create_#{name.underscore.tr('/', '_')}_#{attachment_names.map{|n| n.pluralize}.join('_and_')}"
      end

      def migration_file_name
        "#{migration_name}.rb"
      end

      def migration_class_name
        migration_name.camelize
      end

      def migration_version
        if Rails.version.to_i >= 5
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end

    end
  end
end
