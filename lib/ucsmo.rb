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
module UCSMO
  
  class Slot

    require 'logger'
    require 'rexml/document'
      
    attr_accessor :api, :attributes
  
    #We use the create(xml) method for new Fabrics, not new()
    #The create method uses the XML from the UCS API to add accessor methods
    #that are in the node, like networkElement has a totalMemory node, so
    #we add a totalMemory accessor method.
    #We also add all these attributes to an attributes hash to be nice for
    #others to easily access and process the list of fabric attributes
    def self.create(api,element)
      attributes = {}
      mo = Slot.new
      element.attributes.each do |key, value|
        mo.class.send(:attr_accessor, key)
        mo.send("#{key}=", value)
        attributes[key] = value
      end
      mo.attributes = attributes
      mo.api = api
      mo
    end
    
    def initialize(opts={})
      @log = Logger.new(STDOUT)
#      @log.level = opts[:verbose] ? Logger::INFO : Logger::ERROR
      @log.level = Logger::ERROR
      @log.progname = self.class.to_s
      @log.info("initialized")  
      self       
    end
  
  end
  
  class SlotArray < Array

    require 'rexml/document'

    attr_accessor :slots
    
    #We use create(xml) and not new() to create a new FabricArray.
    #This is so we can populate ourself with Fabrics created from the XML whic
    #should contain multiple nodes
    def self.create(api,elements)
      slots = SlotArray.new
      elements.each do |element| 
        mo = Slot.create(api,element)
        slots << mo
      end
      slots
    end

    def initialize(opts={})
      @log = Logger.new(STDOUT)
#      @log.level = opts[:verbose] ? Logger::INFO : Logger::ERROR
      @log.level = Logger::INFO 
      @log.progname = self.class.to_s
      @log.info("initialized")
      self
    end
  
    private

    def method_missing(method, *args, &block)
      @log.info("method_missing started with " + method.id2name)
      output = SlotArray.new
      each do |mo| 
        begin
          output << mo.send(method, *args, &block) 
        rescue Exception => e
          puts e.message
        end
      end
      @log.info("method_missing ended")
      output
    end  
  end

  class Fabric

    require 'rexml/document'
      
    attr_accessor :attributes, :api
  
    #We use the create(xml) method for new Fabrics, not new()
    #The create method uses the XML from the UCS API to add accessor methods
    #that are in the node, like networkElement has a totalMemory node, so
    #we add a totalMemory accessor method.
    #We also add all these attributes to an attributes hash to be nice for
    #others to easily access and process the list of fabric attributes
    def self.create(api,element)
      attributes = {}
      fabric = Fabric.new
      element.attributes.each do |key, value|
        fabric.class.send(:attr_accessor, key)
        fabric.send("#{key}=", value)
        attributes[key] = value
      end
      fabric.attributes = attributes
      fabric.api = api
      fabric
    end
    
    def initialize(opts={})
      @log = Logger.new(STDOUT)
      @log.level = opts[:verbose] ? Logger::INFO : Logger::ERROR
      @log.level = Logger::ERROR
      @log.progname = self.class.to_s
      @log.info("initialized")       
    end
  
    def bootflash
      @log.info("bootflash started")
    
      classId = 'storageItem'
      stor_dn = dn + '/stor-part-bootflash'
      element = @api.configResolveDn(:dn => stor_dn)
      hash = Hash.new
      element.attributes.each do |key, value|
        hash[key] = value
      end

      @log.info("bootflash ended")

      OpenStruct.new(hash)
    end
  
    def workspace
      @log.info("workspace started")
    
      classId = 'storageItem'
      stor_dn = dn + '/stor-part-workspace'
      element = @api.configResolveDn(:dn => stor_dn)
      hash = Hash.new
      element.attributes.each do |key, value|
        hash[key] = value
      end

      @log.info("workspace ended")

      OpenStruct.new(hash)
    end  
  
    def opt
      @log.info("opt started")
    
      classId = 'storageItem'
      stor_dn = dn + '/stor-part-opt'
      hash = Hash.new
      element = @api.configResolveDn(:dn => stor_dn)
      element.attributes.each do |key, value|
        hash[key] = value
      end

      @log.info("opt ended")

      OpenStruct.new(hash)
    end  

    def stats
      @log.info("stats started")
    
      stats_dn = dn + '/sysstats'
      classId = 'swSystemStats'
      hash = Hash.new
      element = @api.configResolveDn(:dn => stats_dn)
      element.attributes.each do |key, value|
        hash[key] = value
      end

      classId = 'swEnvStats'
      stats_dn = dn + '/envstats'
      element = @api.configResolveDn(:dn => stats_dn)
      element.attributes.each do |key, value|
        hash[key] = value
      end

      @log.info("opt ended")

      OpenStruct.new(hash)
    end

    def slot(opts={})
      @log.info("slot started")

      classId = 'equipmentSwitchCard'

      if opts[:dn] 
        element = @api.configResolveDn( :dn => opts[:dn] )
        found = Slot.create(@api,element)  
      elsif opts[:id] then
        slot_dn = @attributes["dn"] + "/slot-"+ opts[:id].to_s
        element = @api.configResolveDn( :dn => slot_dn)
        found = Slot.create(@api,element)  
      else
        classId = 'equipmentSwitchCard'
        elements = @api.configScope( :dn => @attributes["dn"], :inClass => classId)
        found = SlotArray.create(@api,elements)
      end
      
      @log.info("slot() ended")
      found    
    end
    
    def slots(opts={})
      @log.info("slots started")

      found = slot(opts)
      
      @log.info("slot ended")
      found
     end

    def lan
      @log.info("lan started")
      @log.info("lan ended")
    end
 
    def san
      @log.info("san started")
      @log.info("san ended")
    end

    def psu
      @log.info("psu started")
      @log.info("psu ended")
    end

    def fan
      @log.info("fan started")
      @log.info("fan ended")
    end

    def mgmt
      @log.info("mgmt started")
      @log.info("mgmt ended")
    end

  end

  class FabricArray < Array
  
    require 'logger'
    require 'rexml/document'
    
    attr_accessor :api
    
    #We use create(xml) and not new() to create a new FabricArray.
    #This is so we can populate ourself with Fabrics created from the XML whic
    #should contain multiple nodes
    def self.create(api,elements)
      array = FabricArray.new
      elements.each do |element| 
        mo = Fabric.create(api,element)
        array << mo
      end
      array.api = api
      array
    end
    
    def initialize(opts={})
      @log = Logger.new(STDOUT)
#      @log.level = opts[:verbose] ? Logger::INFO : Logger::ERROR
      @log.level = Logger::ERROR
      @log.progname = self.class.to_s
      @log.info("initialized") 
    end

    def slot(opts={})
      @log.info "slot started"
      
      found = nil
      each { |mo| found = mo.slot(opts) }
      
      @log.info "slot ended"
      found
    end
    
    def slots
      @log.info "slots started"
      
      classId = 'equipmentSwitchCard'
      slots = SlotArray.new
      each do |mo| 
        elements = @api.configScope( :dn => mo.attributes["dn"], :inClass => classId)
        slots << SlotArray.create(@api,elements)
      end
      @log.info "slots ended"
      slots
    end

    private
  
    def method_missing(method, *args, &block)
      @log.info("method_missing started with " + method.id2name)
      output = []
      each do |mo| 
        begin
          output << mo.send(method, *args, &block) 
        rescue Exception => e
          puts e.message
        end
      end
      @log.info("method_missing ended")

      output
    end
        
  end
end