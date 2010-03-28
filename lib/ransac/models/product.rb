class Product
  include DataMapper::Resource
  property :id, Serial
  property :name, String 
  property :href, String 
  property :description, Text
  property :price, Integer
  belongs_to :category
end