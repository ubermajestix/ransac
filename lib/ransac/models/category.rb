class Category
  include DataMapper::Resource
  property :id, Serial
  property :name, String 
  property :href, String 
  has n, :products
end