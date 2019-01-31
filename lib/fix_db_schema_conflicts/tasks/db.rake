require 'shellwords'
require_relative '../autocorrect_configuration'

def generate_local_filename
  "tmp_rubocop_schema.#{SecureRandom.urlsafe_base64}.yml"
end

namespace :db do
  namespace :schema do
    task :dump do
      puts "Dumping database schema with fix-db-schema-conflicts gem"

      filename = ENV['SCHEMA'] || if defined? ActiveRecord::Tasks::DatabaseTasks
        File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
      else
        "#{Rails.root}/db/schema.rb"
      end
      autocorrect_config = FixDBSchemaConflicts::AutocorrectConfiguration.load
      rubocop_yml = File.expand_path("../../../../#{autocorrect_config}", __FILE__)

      begin
        # Temporarily symlink the rubocop config file into the working directory so that rubocop
        # can find the ruby version correctly. Without this, rubocop will start looking from the
        # config file's path, deep inside this gem, where it won't be able to find your project's
        # ruby version.
        local_filename = generate_local_filename
        FileUtils.symlink(rubocop_yml, local_filename)
        `bundle exec rubocop --auto-correct --config #{local_filename} #{filename.shellescape}`
      ensure
        File.delete(local_filename) if File.exist?(local_filename)
      end
    end
  end
end
