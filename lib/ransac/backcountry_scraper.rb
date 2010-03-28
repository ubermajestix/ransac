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
      File.open('backcountry_categories.yml', 'w'){|f| f.write categories.to_yaml}
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
        logger.info cat.inspect
        c = Category.create(:name=>cat.first, :href=>cat.last[:href])
        c.save!
      end
      logger.info Category.all.length
    end

    def self.get_products
      ::Category.all.each do |cat|
        logger.info cat.inspect
        response = patron.get cat.href.gsub("http://www.backcountry.com",'')
        doc = Nokogiri::HTML(response.body)
        doc.search('div.product')[0,8].each do |product_div|
          begin
            logger.info "-----"
            product = {}
            name_href = product_div.search('div.descrip_col h2 a')
            product[:name] = name_href.inner_html
            product[:href] = name_href.attribute('href')
            product[:description] = product_div.search('div.descrip_col p.descrip').inner_html.strip
            product[:price] = product_div.search('div.price').inner_html.gsub(/\$/,'').strip.scan(/\d+\.\d+/).last
            product[:male] = product[:name].include?("Men's")
            product[:female] = product[:name].include?("Women's")
            product[:category_id] = cat.id
            logger.info Product.create!(product).inspect
          rescue StandardError => e
            logger.error e.inspect
          end
        end
      end
    end
    
    def self.logger
      @logger ||= Ransac.logger
    end
  end # of class
end # of module