actions :append

attribute :chain, :name_attribute => true, :kind_of => String
attribute :table, :equal_to => ["filter", "nat", "mangle", "raw"], :default => "filter"
attribute :rule, :kind_of => [String, Array], :required => true
attribute :jump, :kind_of => [String, FalseClass], :default => "ACCEPT"
attribute :direction, :equal_to => ["INPUT", "FORWARD", "OUTPUT", "PREROUTING", "POSTROUTING"], :default => "INPUT"
attribute :chain_condition, :kind_of => [String]
attribute :weight, :kind_of => Integer, :default => 50

def initialize(*args)
  super
  @action = :append
end

