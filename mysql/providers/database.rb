include Opscode::Mysql

action :flush_tables_with_read_lock do
  Chef::Log.info "mysql_database: flushing tables with read lock"
  db.query "flush tables with read lock"
  new_resource.updated = true
end

action :unflush_tables do
  Chef::Log.info "mysql_database: unlocking tables"
  db.query "unlock tables"
  new_resource.updated = true
end

action :create do
  unless database_exists?(new_resource.name)
    create_database(new_resource.name)
  else
    Chef::Log.debug("MySQL database \"#{new_resource.name}\" exists.")
  end
  unless new_resource.owner.to_s == ""
    mysql_user "#{new_resource.owner}" do
      host new_resource.owner_host
      action :create
    end
    mysql_grant "#{new_resource.name}_#{new_resource.owner}" do
      database new_resource.name
      user new_resource.owner
      user_host new_resource.owner_host
      privileges "ALL"
      action :create
    end
  end
end

action :delete do
  if database_exists?(new_resource.name)
    drop_database(new_resource.name)
  else
    Chef::Log.debug("MySQL database \"#{new_resource.name}\" doesn't exist.")
  end
  unless new_resource.owner.to_s == ""
    mysql_grant "#{new_resource.name}_#{new_resource.owner}" do
      action :delete
      database new_resource.name
      user new_resource.owner
      user_host new_resource.owner_host
    end
  end
end
