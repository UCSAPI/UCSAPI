# == Synopsis 
#   Main Ruby interface with help methods for UCS API
#
# == Examples
#   ucs = UCS.new(options) where options is hash containing :url, :inName, :inPassword.. 
#   ucs.login - will use the Nuova library which is like the "raw" interface to UCS
#   ucs.fabric (or another object) - use a helper method to retrieve UCS objects from API
#   ucs.logout - end session on UCS
#
# == Methods 
#   new(hash)
#   login
#   fabric with optional hash containing either :id or :dn
#   logout
#
# == Author
#   Steve Chambers, Cisco
#   Blogger at http://viewyonder.com
#
# == Copyright
#   Copyright (c) 2010 Steve Chambers. Licensed under the Create Commons Unported
#   http://creativecommons.org/licenses/by/3.0/ 

# TO DO - replace license link with viewyonder link
# TO DO - get a singleton logger

module UCSAPI
  
  require 'rubygems'
  require 'rexml/document'
  require 'rest_client'
  require 'ostruct'
  require 'logger'
  require_relative 'Nuova'
  require_relative 'UCSMO'
  
  VERSION = '0.0.9'
    
  class UCS
    
    include Nuova
    include UCSMO
    
    attr_reader :api
    
    def initialize(opts={})
    
      raise "No parameters" if opts == nil 
      @log = Logger.new(STDOUT)
      @log.level = Logger::ERROR
      @log.progname = self.class.to_s

      @log.info("initialize starting")
      @api = API.new(opts)
      @log.info("initialize ending")
    end
    
    def login
      @api.login if @api.session.cookie = ""
    end
    
    def api
      @api
    end
    
    def session
      @api.session
    end
    
    def logout
      @api.logout
    end
    
    #Logic is simple:
    #* If you give us a dn, return one Fabric 
    #* If you provide a text ID, return one Fabric
    #* If you provide nothing, return FabricArray
    def fabric(opts={})
      @log.info("fabric started")

      classId = 'networkElement'
      if opts[:dn] 
        element = @api.configResolveDn( :dn => opts[:dn])
        found = Fabric.create(@api,element)  
      elsif opts[:id] then
        dn = 'sys/switch-' + opts[:id]
        element = @api.configResolveDn( :dn => dn )
        found = Fabric.create(@api,element)  
      else
        classId = 'networkElement'    
        elements = @api.configResolveClass( :classId => classId)
        found = FabricArray.create(@api,elements)     
      end
      
      @log.info "fabric ended"
      found 
    end
    
    def fabrics(opts={})   
      @log.info("fabrics started")

      found = fabric(opts)
      
      @log.info("fabrics ended")
      found
    end
    
  end
  
end