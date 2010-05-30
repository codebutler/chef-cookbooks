include Opscode::Postgresql

action :create do
  unless database_exists?(new_resource.name)
    create_database(new_resource.name, new_resource.owner)
  else
    Chef::Log.debug("Postgresql database \"#{new_resource.name}\" exists.")
  end
end

action :delete do
  if database_exists?(new_resource.name)
    drop_database(new_resource.name)
  else
    Chef::Log.debug("Postgresql database \"#{new_resource.name}\" doesn't exist.")
  end
end
