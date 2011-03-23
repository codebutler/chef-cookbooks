define :lnmp_site do  
  name       = params[:name]
  username   = params[:user] || name
  db_name    = params[:db_name]
  db_user    = params[:db_username]
  db_pass    = params[:db_password]
  enable_ssl = params[:enable_ssl] || false
  
  # Create user
  user username do
    action :create
    shell  '/dev/null'
  end

  # Create group
  group username do
    action :create
    members [ username ]
  end

  # Create website directory
  directory "/var/www/#{name}" do
    owner  username
    group  username
    mode   '0755'
    action :create
  end

  # Create mysql user and database
  mysql_user db_user do
    password db_pass
    action :create
  end
  mysql_database db_name do
    owner db_user
    action :create
  end
  
  # Install any SSL certificates
  if enable_ssl
    cookbook_file "/etc/ssl/certs/#{name}.crt" do
      owner 'root'
      group 'root'
      mode  '0644'
      action :create
    end
    cookbook_file "/etc/ssl/private/#{name}.key" do
      owner 'root'
      group 'root'
      mode  '0600'
      action :create
    end
  end

  # Add nginx configuration
  template "/etc/nginx/sites-available/#{name}" do
    source "nginx-site.erb"
    cookbook 'lnmp'
    owner  'root'
    group  'root'
    mode   '0644'
    variables({ 
      :name         => params[:name], 
      :domains      => params[:domains], 
      :php_cgi_port => params[:php_cgi_port], 
      :enable_ssl   => params[:enable_ssl] 
    })
    notifies :restart, resources(:service => 'nginx')
  end

  # Enable nginx site
  nginx_site name do
    enable true
    notifies :restart, resources(:service => 'nginx')
  end

  # Add and enable php init script
  unless params[:php_cgi_none]
    template "/etc/init/php5-fcgi-#{name}.conf" do
      source   'php5-fcgi.conf.erb'
      cookbook 'lnmp'
      owner    'root'
      group    'root'
      mode     '0644'
      variables({ :name => name, :user => username, :port => params[:php_cgi_port] })
    end
    service "php5-fcgi-#{name}" do
      supports :restart => true
      provider Chef::Provider::Service::Upstart
      action [ :enable, :start ]
    end
  end
end