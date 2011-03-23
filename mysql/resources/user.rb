# http://dev.mysql.com/doc/refman/5.0/en/create-user.html

actions :create, :delete

attribute :host,           :kind_of => String, :default => "localhost"
attribute :password,       :kind_of => String
attribute :force_password, :kind_of => [TrueClass, FalseClass], :default => false