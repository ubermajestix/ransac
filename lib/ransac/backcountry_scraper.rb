#!/usr/bin/env ruby
module Ransac
  class BackcountryScraper
    
    def self.patron
      return @patron unless @patron.nil?
      @patron = Patron::Session.new
      @patron.base_url = "http://backcountry.com"
      @patron
    end  
    
    # get all categories from links like
    # http://www.backcountry.com/store/cat/100000009/Shoes.html
    # 
    # then get all sub categories
    # http://www.backcountry.com/store/subcat/40/Womens-Footwear.html
    def self.get_categories
      puts "="*45
      puts patron.inspect
      puts "="*45
      response = patron.get "/"
      doc = Nokogiri::HTML(response.body)
  
      categories = {}
      doc.search('a').each do |a|
        if a.attribute('href').to_s
          href = a.attribute('href').to_s
          if href.match(/\/store\/cat\/\d+\//)
            category = href.split("/").last.gsub(".html", '')
            categories[category] = {:href => href.gsub('http://www.backcountry.com', '')}
          end
        end
      end
      puts categories.inspect
      puts categories.keys
      puts categories.keys.length
  
      categories.each do |cat, hash|
        response = patron.get hash[:href]
        doc = Nokogiri::HTML(response.body)
        doc.search('a').each do |a|
            if a.attribute('href').to_s
              href = a.attribute('href').to_s
              if href.match(/\/store\/subcat\/\d+\//)
                category = href.split("/").last.gsub(".html", '')
                hash[category] = {:href => href}
              end
            end
        end
      end
      File.open('backcountry_categories.yml', 'w'){|f| f.write categories.to_yml}
    end
  
    def self.save_categories
      categories = YAML::load_file('backcountry_categories.yml')
      subcats = []
      categories.each do |cat, hash|
        hash.delete('href')
        hash.each do |subcat|
          subcats << subcat unless subcats.include?(subcat)
        end
      end
      subcats.each do |cat|
        next if cat.first == :href
        puts cat.inspect
        Category.create!(:name=>cat.first, :href=>cat.last[:href])
      end
      puts Category.all.length
    end
  
  end
end