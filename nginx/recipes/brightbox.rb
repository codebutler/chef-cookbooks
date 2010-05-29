bash "refresh-apt" do
  user 'root'
  code <<-EOH
  apt-get update
  EOH
  action :nothing
end

template "/etc/apt/sources.list.d/brightbox.list" do
  source "apt-brightbox.list.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :run, resources(:bash => 'refresh-apt')
end

package "nginx-brightbox" do
  action :install
end

directory node[:nginx][:log_dir] do
  mode 0755
  owner node[:nginx][:user]
  action :create
end

%w{nxensite nxdissite}.each do |nxscript|
  template "/usr/sbin/#{nxscript}" do
    source "#{nxscript}.erb"
    mode 0755
    owner "root"
    group "root"
  end
end

template "nginx.conf" do
  path "#{node[:nginx][:dir]}/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "#{node[:nginx][:dir]}/sites-available/default" do
  source "default-site.erb"
  owner "root"
  group "root"
  mode 0644
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end