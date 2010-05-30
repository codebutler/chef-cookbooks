begin
  require 'rubygems'
  require 'pg'
rescue LoadError
  Chef::Log.warn("Missing gem 'pg'")
end

module Opscode
  module Postgresql
    def db
      @@db ||= PGconn.connect(:dbname => 'postgres')
    end
    
    def users
      select_query = "SELECT rolname FROM pg_roles"
      @@users ||= db.exec(select_query).map{|row| row['rolname'] }
    end
    
    def user_exists?(user)
      users.include?(user)
    end
    
    def create_user(user, password)
      @@users = nil
      Chef::Log.info("Creating PostgreSQL user #{user}.")
      create_query = "CREATE USER #{db.escape(user)} WITH PASSWORD '#{db.escape(password)}'"
      db.exec(create_query)
    end
    
    def drop_user(user)
      @@users = nil
      Chef::Log.info("Dropping PostgreSQL user #{user}.")
      db.exec("DROP ROLE IF EXISTS #{db.escape(user)}")
    end
        
    def databases
      select_query = 'SELECT datname FROM pg_database'
      @@databases ||= db.exec(select_query).map{|row| row['datname'] }
    end
    
    def database_exists?(database)
      databases.include?(database)
    end

    def create_database(database, owner)
      @@databases = nil
      Chef::Log.info("Creating PostgreSQL database \"#{database}\".")
      db.exec("CREATE DATABASE #{db.escape(database)} OWNER #{db.escape(owner)}")
    end

    def drop_database(database)
      @@databases = nil
      Chef::Log.info("Dropping PostgreSQL database \"#{database}\".")
      db.exec("DROP DATABASE #{db.escape(database)}")
    end
  end
end
