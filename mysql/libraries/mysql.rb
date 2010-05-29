begin
  require 'mysql'
rescue LoadError
  Chef::Log.warn("Missing gem 'mysql'")
end

module Opscode
  module Mysql
    def db
      @@db ||= ::Mysql.new new_resource.host, 'root', node[:mysql][:server_root_password]
    end
    
    def users
      select_query = "SELECT CONCAT(`User`, '@', `Host`) FROM `mysql`.`user`"
      @@users ||= query(select_query).collect.flatten
    end
    
    def user_exists?(user)
      users.include?("#{user.name}@#{user.host}")
    end
    
    def create_user(user, password)
      @@users = nil
      Chef::Log.info("Creating MySQL user #{user.name}@#{user.host}.")
      create_query = "CREATE USER #{user_handle(user)} IDENTIFIED BY '#{db.quote(password)}'"
      query(create_query)
      db.reload
    end
    
    def drop_user(user)
      @@users = nil
      Chef::Log.info("Dropping MySQL user #{user.name}@#{user.host}.")
      handle = user_handle(user)

      query("REVOKE ALL PRIVILEGES, GRANT OPTION FROM #{handle}")
      query("DROP USER #{handle}")
      db.reload
    end
    
    def force_password(user, password)
      password_ok = false
      select_query =
        "SELECT COUNT(User) " +
          "FROM `mysql`.`user` WHERE " +
          "`User` = ? AND " +
          "`Host` = ? AND " +
          "`Password` = PASSWORD(?)"
        
      password_ok = query(select_query, password, user.name, user.host)[0] > 0

      unless password_ok
        Chef::Log.info("Reseting MySQL password of #{user.name}@#{user.host}.")
        set_query = "SET PASSWORD FOR #{user_handle(user)} = PASSWORD(?)"
        query(set_query, password)
        db.reload
      else
        Chef::Log.debug("MySQL password OK for #{user.name}@#{user.host}.")
      end
    end    
    
    def databases
      @@databases ||= db.list_dbs
    end
    
    def database_exists?(database)
      databases.include?(database)
    end

    def create_database(database)
      @@databases = nil
      Chef::Log.info("Creating MySQL database \"#{database}\".")
      query("CREATE DATABASE #{db.quote(database)}")
    end

    def drop_database(database)
      @@databases = nil
      Chef::Log.info("Dropping MySQL database \"#{database}\".")
      query("DROP DATABASE #{db.quote(database)}")
    end
    
    def user_privileges(grant)
      @@grants ||= {}
      
      handle = user_handle(grant, :grant)
      return @@grants[handle] if @@grants && @@grants[handle]
      
      @@grants[handle] = {}

      # TODO don't ignore grant option
      db.query("SHOW GRANTS FOR #{handle}").each do |row|
        if row[0] =~ /\AGRANT (.*) ON [`'"]?(\S+?)[`'"]?(\.\S+)? TO .+\Z/
          @@grants[handle][$2] = $1.split(/,\s*/).map do |p|
            p == "ALL PRIVILEGES" ? "ALL" : p
          end
        end
      end
      @@grants[handle]
    end

    def manage_privileges(action, grant, privileges)
      handle = user_handle(grant, :grant)
      @@grants[handle] = nil
      db_escaped = grant.database == "*" ? "*" : "`#{db.quote(grant.database)}`"
      if action == :delete
        privileges += ["GRANT OPTION"] if grant.grant_option
        Chef::Log.info("Revoking #{privileges.join(", ")} privileges on MySQL database \"#{grant.database}\" from #{grant.user}@#{grant.user_host}.")
        privilege_query = "REVOKE #{privileges.join(', ')} ON #{db_escaped}.* FROM #{handle}"
      else
        if grant.grant_option
          Chef::Log.info("Granting #{privileges.join(", ")} privileges on MySQL database \"#{grant.database}\" to #{grant.user}@#{grant.user_host} WITH GRANT OPTION.")
          privilege_query = "GRANT #{privileges.join(', ')} ON #{db_escaped}.* TO #{handle} WITH GRANT OPTION"
        else
          Chef::Log.info("Granting #{privileges.join(", ")} privileges on MySQL database \"#{grant.database}\" to #{grant.user}@#{grant.user_host}.")
          privilege_query = "GRANT #{privileges.join(', ')} ON #{db_escaped}.* TO #{handle}"
        end
      end
      
      query(privilege_query)
      db.reload
    end

    def manage_grants(action, grant)
      privileges = user_privileges(grant)
      current_db_privileges = privileges[grant.database] || []
      new_db_privileges = [grant.privileges].flatten.map { |p| p.upcase }
      case action
      when :create
        unless current_db_privileges.include?("ALL")
          missing_privileges = new_db_privileges - current_db_privileges
          unless missing_privileges.empty?
            manage_privileges(:create, grant, missing_privileges)
          else
            Chef::Log.debug("MySQL user #{grant.user}@#{grant.user_host} has all necessary privileges on database \"#{grant.database}\".")
          end
        else
          Chef::Log.debug("MySQL user #{grant.user}@#{grant.user_host} has ALL privileges on database \"#{grant.database}\".")
        end
      when :delete
        if new_db_privileges.include?("ALL") && !current_db_privileges.empty?
          manage_privileges(:delete, grant, "ALL")
        else
          unwanted_privileges = current_db_privileges & new_db_privileges
          unless unwanted_privileges.empty?
            manage_privileges(:delete, grant, unwanted_privileges)
          else
            Chef::Log.debug("MySQL user #{grant.user}@#{grant.user_host} has no unwanted privileges on database \"#{grant.database}\".")
          end
        end
      end
    end

    
    private
    
    def query(q, *args, &block)
      Chef::Log.debug("MySQL query: #{q}")
      st = db.prepare(q)
      st.execute(*args)
            
      if st.num_rows > 0
        if block_given?
          while row = st.fetch do
            yield row
          end
        else
          rows = []
          while row = st.fetch do
            rows << row
          end
          rows
        end
      end
    end
    
    def user_handle(user, resource_type = :user)
      if resource_type == :grant
        # user is a grant :)
        "`#{db.quote(user.user)}`@`#{db.quote(user.user_host)}`"
      else
        "`#{db.quote(user.name)}`@`#{db.quote(user.host)}`"
      end
    end
  end
end
