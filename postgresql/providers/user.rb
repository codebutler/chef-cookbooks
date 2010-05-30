include Opscode::Postgresql

action :create do
  unless user_exists?(new_resource.name)
    create_user(new_resource.name, new_resource.password)
  else
    Chef::Log.debug("Postgresql user \"#{new_resource.name}\" exists.")
  end
end

action :delete do
  drop_user(new_resource) if user_exists?(new_resource)
end
