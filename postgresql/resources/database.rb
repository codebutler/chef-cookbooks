def initialize(name, collection=nil, node=nil)
  super(name, collection, node)
  @action = :create
end

actions :create, :delete

attribute :owner, :kind_of => String