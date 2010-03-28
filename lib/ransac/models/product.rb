class Product
  include DataMapper::Resource
  property :id, Serial
  property :name, String 
  property :href, String 
  property :description, Text
  property :price, Float
  property :male, Boolean, :default => false
  property :female, Boolean, :default => false
  belongs_to :category
end