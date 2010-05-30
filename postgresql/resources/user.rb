def initialize(name, collection=nil, node=nil)
  super(name, collection, node)
  @action = :create
end

actions :create, :delete

attribute :password, :kind_of => String
