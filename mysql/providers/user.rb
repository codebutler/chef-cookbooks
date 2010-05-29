include Opscode::Mysql

action :create do
  password = new_resource.password
  if new_resource.force_password
    if user_exists?(new_resource)
      force_password(new_resource, password)
    else
      create_user(new_resource, password)
    end
  elsif !user_exists?(new_resource)
    create_user(new_resource, password)
  end
end

action :delete do
  drop_user(new_resource) if user_exists?(new_resource)
end
