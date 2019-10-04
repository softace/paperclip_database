module Paperclip
  module Storage
    # Store files in a database.
    #
    # Usage is identical to the file system storage version, except:
    #
    # 1. In your model specify the "database" storage option; for example:
    #   has_attached_file :avatar, :storage => :database
    #
    # The files will be stored in a new database table named with the plural attachment name
    # by default, "avatars" in this example.
    #
    # 2. You need to create this new storage table with at least these columns:
    #   - file_contents
    #   - style
    #   - the primary key for the parent model (e.g. user_id)
    #
    # Note the "binary" migration will not work for the LONGBLOG type in MySQL for the
    # file_cotents column. You may need to craft a SQL statement for your migration,
    # depending on which database server you are using. Here's an example migration for MySQL:
    #
    # create_table :avatars do |t|
    #   t.string :style
    #   t.integer :user_id
    #   t.timestamps
    # end
    # execute 'ALTER TABLE avatars ADD COLUMN file_contents LONGBLOB'
    #
    # You can optionally specify any storage table name you want and whether or not deletion is done by cascading or not as follows:
    #   has_attached_file :avatar, :storage => :database, :database_table => 'avatar_files', :cascade_deletion => true
    #
    # 3. By default, URLs will be set to this pattern:
    #   /:relative_root/:class/:attachment/:id?style=:style
    #
    # Example:
    #   /app-root-url/users/avatars/23?style=original
    #
    # The idea here is that to retrieve a file from the database storage, you will need some
    # controller's code to be executed.
    #
    # Once you pick a controller to use for downloading, you can add this line
    # to generate the download action for the default URL/action (the plural attachment name),
    # "avatars" in this example:
    #   downloads_files_for :user, :avatar
    #
    # Or you can write a download method manually if there are security, logging or other
    # requirements.
    #
    # If you prefer a different URL for downloading files you can specify that in the model; e.g.:
    #   has_attached_file :avatar, :storage => :database, :url => '/users/show_avatar/:id/:style'
    #
    # 4. Add a route for the download to the controller which will handle downloads, if necessary.
    #
    # The default URL, /:relative_root/:class/:attachment/:id?style=:style, will be matched by
    # the default route: :controller/:action/:id
    #
    module Database

      def self.extended(base)
        base.instance_eval do
          setup_attachment_class
          setup_paperclip_file_model
          setup_paperclip_files_association
          override_default_options base
        end
        Paperclip.interpolates(:database_path) do |attachment, style|
          attachment.database_path(style)
        end
        Paperclip.interpolates(:relative_root) do |attachment, style|
          begin
            if ActionController::AbstractRequest.respond_to?(:relative_url_root)
              relative_url_root = ActionController::AbstractRequest.relative_url_root
            end
          rescue NameError
          end
          if !relative_url_root && ActionController::Base.respond_to?(:relative_url_root)
            ActionController::Base.relative_url_root
          end
        end

        ActiveRecord::Base.logger.info("[paperclip] Database Storage Initalized.")
      end

      def setup_paperclip_files_association
        @paperclip_files_association_name = @paperclip_file_model.name.demodulize.tableize
        @database_table = @paperclip_file_model.table_name
        #FIXME: This fails when using  set_table_name "<myname>" in your model
        #FIXME: This should be fixed in ActiveRecord...
        instance.class.has_many(@paperclip_files_association_name.to_sym,
                                :class_name => @paperclip_file_model.name,
                                :foreign_key => instance.class.table_name.classify.underscore + '_id'
                                )
      end
      private :setup_paperclip_files_association

      def setup_paperclip_file_model
        class_name = "#{instance.class.table_name.singularize}_#{name.to_s}_paperclip_file".classify
        if @attachment_class.const_defined?(class_name, false)
          @paperclip_file_model = @attachment_class.const_get(class_name, false)
        else
          @paperclip_file_model = @attachment_class.const_set(class_name, Class.new(::ActiveRecord::Base))
          @paperclip_file_model.table_name = @options[:database_table] || name.to_s.pluralize
          @paperclip_file_model.validates_uniqueness_of :style, :scope => instance.class.table_name.classify.underscore + '_id'
          case ActiveModel::VERSION::MAJOR
          when 3, 4
            @paperclip_file_model.scope :file_for, lambda {|style| @paperclip_file_model.where('style = ?', style) }
          when 5,6
            @paperclip_file_model.scope :file_for, lambda {|style| where('style = ?', style) }
          else
            raise "ActiveModel version #{ActiveModel::VERSION::STRING} is not supported (yet)"
          end
        end
      end
      private :setup_paperclip_file_model

      def setup_attachment_class
        instance.class.ancestors.each do |ancestor|
          # Pick the top-most definition like
          # Paperclip::AttachmentRegistry#definitions_for
          names_for_ancestor = ancestor.attachment_definitions.keys rescue []
          if names_for_ancestor.member?(name)
            @attachment_class = ancestor
          end
        end
      end
      private :setup_attachment_class

      def copy_to_local_file(style, dest_path)
        File.open(dest_path, 'wb+'){|df| to_file(style).tap{|sf| File.copy_stream(sf, df); sf.close;sf.unlink} }
      end

      def override_default_options(base)
        if @options[:url] == base.class.default_options[:url]
          @options[:url] = ":relative_root/:class/:attachment/:id?style=:style"
        end
        @options[:path] = ":database_path"
      end
      private :override_default_options

      def database_table
        @database_table
      end

      def database_path(style)
        paperclip_file = file_for(style)
        if paperclip_file
          "#{database_table}(id=#{paperclip_file.id},style=#{style.to_s})"
        else
          "#{database_table}(id=new,style=#{style.to_s})"
        end
      end

      def exists?(style = default_style)
        if original_filename
          instance.send("#{@paperclip_files_association_name}").where(:style => style).exists?
        else
          false
        end
      end

      # Returns representation of the data of the file assigned to the given
      # style, in the format most representative of the current storage.
      def to_file style = default_style
        if @queued_for_write[style]
          @queued_for_write[style]
        elsif exists?(style)
          tempfile = Tempfile.new instance_read(:file_name)
          tempfile.binmode
          tempfile.write file_contents(style)
          tempfile.flush
          tempfile.rewind
          tempfile
        else
          nil
        end

      end
      alias_method :to_io, :to_file

      def files
        instance.send("#{@paperclip_files_association_name}")
      end

      def file_for(style)
        db_result = instance.send("#{@paperclip_files_association_name}").send(:file_for, style.to_s)
        raise RuntimeError, "More than one result for #{style}" if db_result.size > 1
        db_result.first
      end

      def file_contents(style = default_style)
        file_for(style).file_contents
      end

      def flush_writes
        ActiveRecord::Base.logger.info("[paperclip] Writing files for #{name}")
        @queued_for_write.each do |style, file|
            case ActiveModel::VERSION::MAJOR
            when 3
              paperclip_file = instance.send(@paperclip_files_association_name).send(:find_or_create_by_style, style.to_s)
            when 4,5,6
              paperclip_file = instance.send(@paperclip_files_association_name).send(:find_or_create_by, style: style.to_s)
            else
              raise "ActiveModel version #{ActiveModel::VERSION::STRING} is not supported (yet)"
            end
          paperclip_file.file_contents = file.read
          paperclip_file.save!
          instance.reload
        end
        @queued_for_write = {}
      end

      def flush_deletes #:nodoc:
        ActiveRecord::Base.logger.info("[paperclip] Deleting files for #{name}")
        @queued_for_delete.uniq! ##This is apparently necessary for paperclip v 3.x
        @queued_for_delete.each do |path|
          /id=([0-9]+)/.match(path)
          if @options[:cascade_deletion] && !instance.class.exists?(instance.id)
            raise RuntimeError, "Deletion has not been done by through cascading." if @paperclip_file_model.exists?($1)
          else
            @paperclip_file_model.destroy $1
          end
        end
        @queued_for_delete = []
      end

      module ControllerClassMethods
        def self.included(base)
          base.extend(self)
        end
        def downloads_files_for(model, attachment, options = {})
          define_method("#{attachment.to_s.pluralize}") do
            #FIXME: Handling Namespaces
            model_record = Object.const_get(model.to_s.camelize.to_sym, false).find(params[:id])
            style = params[:style] ? params[:style] : 'original'
            send_data model_record.send(attachment).file_contents(style),
                      :filename => model_record.send("#{attachment}_file_name".to_sym),
                      :type => model_record.send("#{attachment}_content_type".to_sym)
          end
        end
      end
    end
  end
end
