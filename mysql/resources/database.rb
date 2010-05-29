# http://dev.mysql.com/doc/refman/5.0/en/create-database.html
def initialize(name, collection=nil, node=nil)
  super(name, collection, node)
  @action = :create
end

actions :create, :delete, :flush_tables_with_read_lock, :unflush_tables

attribute :owner,      :kind_of => String
attribute :owner_host, :kind_of => String, :default => "localhost"
