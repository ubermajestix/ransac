require 'rubygems'
require 'dm-core'
require 'dm-validations'
require 'rubygems'
require 'patron'
require 'nokogiri'
require 'yaml'
require 'logging'
require 'iconv'

module Ransac
  VERSION = '0.0.0'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  
  class << self
    def initialize(opts={})      
      logger.info "Initializing Ransac"
      @environment = opts[:environment].nil? ? ENV['RACK_ENV'] : opts.delete(:environment)
      raise "must provide an environment!" unless ["test", "development", "production"].include?(@environment)    
      logger.info "environment: #{@environment}"
      establish_database_connection
    end
    public :initialize
  
    def app
      puts "Sinatra in the house. Somebody get him a drink."
      @app ||= Rack::Builder.new do
        use Rack::Session::Cookie, :key => 'rack.session', :path => '/',
         :expire_after => 2592000, :secret => ::Digest::SHA1.hexdigest(Time.now.to_s)
        run App
      end
    end
  
    def logger
      return @logger if @logger
      Logging.appenders.stdout(:level => :debug,:layout => Logging.layouts.pattern(:pattern => '[%c:%5l] %p %d %m\n'))
      log = Logging.logger['Ransac']
      log.add_appenders 'stdout'
      @logger = log
    end
    
    def environment
      @environment
    end
  
    def establish_database_connection
      db = @environment == "test" ? "sqlite3::memory:" : "sqlite3://#{LIBPATH}ransac.sqlite3"
      logger.info "connecting to database #{ENV['DATABASE_URL'] || db}"
      DataMapper.setup(:default, ENV['DATABASE_URL'] || db)
      DataMapper::Logger.new(STDOUT, @environment == "test" ? :debug : :info) # :off, :fatal, :error, :warn, :info, :debug
      DataMapper.auto_migrate! if @environment == "test"
    end

    def version
      VERSION
    end

    def libpath( *args )
      args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
    end

    def path( *args )
      args.empty? ? PATH : ::File.join(PATH, args.flatten)
    end

    def require_all_libs_relative_to( fname, dir = nil )
      dir ||= ::File.basename(fname, '.*')
      search_me = ::File.expand_path(
          ::File.join(::File.dirname(fname), dir, '**', '*.rb'))
      Dir.glob(search_me).sort.each {|rb| require rb}
    end
  end # class << self
end
Ransac.require_all_libs_relative_to(__FILE__)

module SledgeHammer
  def utf8_sledgehammer
    Iconv.iconv('ascii//translit', 'utf-8', self).to_s
  end
end

class String
  include SledgeHammer
end