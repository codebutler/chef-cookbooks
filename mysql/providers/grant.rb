include Opscode::Mysql

action :create do
  manage_grants(:create, new_resource)
end

action :delete do
  manage_grants(:delete, new_resource)
end
