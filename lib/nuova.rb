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
module Nuova
  
  require 'rubygems'
  require 'rexml/document'
  require 'rest_client'
  require 'logger'
  require 'ostruct'
  
  class API
    
    attr_reader :session
    attr_accessor :loglevel
  
    def initialize(opts={})
      @log = Logger.new(STDOUT)
      @log.level = Logger::ERROR
      @log.progname = self.class.to_s
      @log.info("initialize started")
       
      raise "Missing URL parameter" unless opts[:url]
      raise "Missing inName parameter" unless opts[:inName]
      raise "Missing inPassword parameter" unless opts[:inPassword]   
           
      @session = OpenStruct.new
      @session.url = opts[:url]
      @session.inName = opts[:inName] || opts[:name]
      @session.inPassword = opts[:inPassword] || opts[:password]

      @log.info("initialize ended")
    end

   #Build an send the <aaaLogin /> method to UCS
   #Returns *user.session* which is an OpenStruct
   #* Build the XMLAPI call from the opts parameters
   #* Send the XMLAPI object to dispatch, get an XML object back
   #* Create a new OpenStruct from the response and store in @user
   def login  
     @log.info("login started")
     
     request = REXML::Document.new('<aaaLogin />')
     request.root.add_attribute("inName",@session.inName)
     request.root.add_attribute("inPassword",@session.inPassword)

     response = dispatch(request)

     attrs = Hash.new
     response.attributes.each { | key, value | attrs[key]=value }
     @session.response = OpenStruct.new(attrs)

     if @session.response.errorCode
       @log.error @session.response.errorCode + " " + 
                  @session.response.invocationResult + " " +
                  @session.response.errorDescr
       exit
     else
       @session.cookie = @session.response.outCookie    
     end
     
     self
   end

   #Logout / kill the UCS session with the _@cookie_
   #Returns *user.session* which is an OpenStruct
   #* Build the XMLAPI call from the opts parameters
   #* Send the XMLAPI object to dispatch, get an XML object back
   #* Create a new OpenStruct from the response and store in @user
   def logout
     @log.info("logout started")

     # Do we have a session to logout of?
     if @session.cookie
       request = REXML::Document.new('<aaaLogout />')
       request.root.add_attribute("inCookie",@session.cookie)

       response = dispatch(request)

       attrs = Hash.new
       response.attributes.each { | key, value | attrs[key]=value }
       @session.response = OpenStruct.new(attrs)

       if @session.response.errorCode
         @log.error @session.response.errorCode + " " + 
                    @session.response.invocationResult + " " +
                    @session.response.errorDescr
         exit
       end
     else  
       @log.error("No session to logout of")
       exit
     end

     self
     @log.info("logout ended")
   end

   #Get an xml object containing API code, turn into text and HTTP POST it to _@user.url_
   #Returns the root REXML::Element of the UCS XMLAPI response document
   #* The caller will send a REXML object with the XMLAPI command in it
   #* Send the XMLAPI call to UCS and catch any exceptions (log and quit if we do)
   def dispatch(xml)
     @log.info("dispatch starting")
     @log.info("dispatch called with " + @session.url + xml.to_s)    

     # The RestClient.post method expects text, not a REXML object
     post = xml.to_s

     # FIXME: RestClient timeout is broken and default wait is 75s #dontaskmewhy
     begin
       response = RestClient.post @session.url, post, :content_type => 'text/xml'
     rescue => e
       @log.error "dispatch EXCEPTION " + e.class.to_s + " = " + e.to_s
       exit
     end

     @log.info("from api " + response.to_s)
     @log.info("dispatch ended")
     
     REXML::Document.new(response).root
   end

   #Build an XMLAPI call to find an object via distinguished name
   #Returns an *Array* of found objects
   #* Build the XMLAPI call from the opts parameters
   #* Send the XMLAPI object to dispatch, get an XML object back
   #If the response XML has objects under <outConfig> then 
   #* get each element and
   #* build an OpenStruct with attributes from the XML attributes
   #* add each OpenStruct to an array, which is returned to the method caller        outConfig = response.root.elements[1]
   def configResolveDn(opts={})
     @log.info("configResolveDn started")
     @log.info("paramters " + opts.to_s)
     
     inHierarchical = opts[:inHierarchical] || "false"
     if opts[:dn] then
       request = REXML::Document.new('<configResolveDn />')
       request.root.add_attribute("cookie",@session.cookie)
       request.root.add_attribute("inHierarchical",inHierarchical)
       request.root.add_attribute("dn",opts[:dn])

       response = dispatch(request)

       outConfig = response.root.elements[1]

       if outConfig then
         found = outConfig.elements[1]
       else
         found = nil
         if response.root.attributes["errorCode"]
           @log.error ["errorCode"] + " " + 
                    response.root.attributes["invocationResult"] + " " +
                    response.root.attributes["errorDescr"]
         end
         @log.error " ERROR No items found for dn = " + opts[:dn]
       end
     else
       @log.error "ERROR Please supply a :dn option like configResolveDn( :classId => 'equipmentChassis' )" unless opts[:classId]
     end
     
     @log.info("configResolveDn ended")
     found
   end

   #Build an XMLAPI call to find an object(s) via the class name
   #If you supply a :inFilter hash of property/value, we'll add a filter element
   #Returns an *Array* of found objects
   #* Build the XMLAPI call from the opts parameters
   #* Send the XMLAPI object to dispatch, get an XML object back
   #If the response XML has objects under <outConfig> then 
   #* get each element and
   #* build an OpenStruct with attributes from the XML attributes
   #* add each OpenStruct to an array, which is returned to the method caller            
   def configResolveClass(opts={})
     @log.info("configResolveClass started")

     inHierarchical = opts[:inHierarchical] || "false"
     if opts[:classId] then
       request = REXML::Document.new('<configResolveClass />')
       request.root.add_attribute("cookie",@session.cookie)
       request.root.add_attribute("inHierarchical",inHierarchical)
       request.root.add_attribute("classId",opts[:classId])
       if opts[:inFilter]
         filterHash = opts[:inFilter]
         filterType = filterHash["type"]
         filterProperty = filterHash["property"]
         filterValue = filterHash["value"]
         inFilter = request.root.add_element("inFilter")
         inFilter.add_element(filterType, { "class" => opts[:classId], "property" => filterProperty, "value" => filterValue})
       end

       response = dispatch(request)

       outConfig = response.root.elements[1]

       if outConfig then
         found = outConfig.elements
       else
         found = nil
         if response.root.attributes["errorCode"]
           @log.error ["errorCode"] + " " + 
                    response.root.attributes["invocationResult"] + " " +
                    response.root.attributes["errorDescr"]
         end
         @log.error " ERROR No items found for classId = " + opts[:classId] + " with filter: " + opts[:inFilter].to_s
       end
     else
     @log.error "ERROR Please supply a :classId option like configResolveClass( :classId => 'equipmentChassis' )" unless opts[:classId]
     end

     @log.info("configResolveClass ended")    
     found
   end

   #Build an XMLAPI call to find objects of a specified class under a specified distinguished name
   #Returns an *Array* of found objects
   #* Build the XMLAPI call from the opts parameters
   #* Send the XMLAPI object to dispatch, get an XML object back
   #If the response XML has objects under <outConfig> then 
   #* get each element and
   #* build an OpenStruct with attributes from the XML attributes
   #* add each OpenStruct to an array, which is returned to the method caller      
   def configResolveChildren(opts={})
     @log.info("configResolveChildren started")

     inHierarchical = opts[:inHierarchical] || "false"
     request = REXML::Document.new('<configResolveChildren />')
     request.root.add_attribute("cookie",@session.cookie)
     request.root.add_attribute("inHierarchical",inHierarchical)
     request.root.add_attribute("classId",opts[:classId]) 
     request.root.add_attribute("inDn",opts[:inDn]) 

     response = dispatch(request)

     outConfig = response.root.elements[1]
     
     if outConfig.has_elements? then
       found = Array.new
       outConfig.elements.each do |element|
         attrs = Hash.new
         attrs["classId"] = element.name
         element.attributes.each { | key, value | attrs[key]=value }
         found << OpenStruct.new(attrs)      
       end
       @log.info "configResolveChildren returning " + found.size.to_s + " objects"
     else
       @log.error "configResolveChildren ERROR No items found for classId = " + opts[:classId] 
     end

     @log.info("configResolveChildren ended")    
     found
   end

   #Build an XMLAPI call to find distinguished names in a specified class
   #Returns an *Array* of found objects
   #* Build the XMLAPI call from the opts parameters
   #* Send the XMLAPI object to dispatch, get an XML object back
   #If the response XML has objects under <outConfig> then 
   #* get each element and
   #* build an OpenStruct with attributes from the XML attributes
   #* add each OpenStruct to an array, which is returned to the method caller
   def configScope(opts={})     
     @log.info("configScope started")

     inHierarchical = opts[:inHierarchical] || "false"
     inRecursive = opts[:inRecursive] || "false"
     request = REXML::Document.new('<configScope />')
     request.root.add_attribute("cookie",@session.cookie)
     request.root.add_attribute("inHierarchical",inHierarchical)
     request.root.add_attribute("inClass",opts[:inClass]) 
     request.root.add_attribute("dn",opts[:dn]) 

     response = dispatch(request)

     outConfig = response.root.elements[1]

     if outConfig then
       found = outConfig.elements
     else
       found = nil
       if response.root.attributes["errorCode"]
         @log.error ["errorCode"] + " " + 
                  response.root.attributes["invocationResult"] + " " +
                  response.root.attributes["errorDescr"]
      end
       @log.error " ERROR No items found for classId = " + opts[:classId] + " with filter: " + opts[:inFilter].to_s
     end     

     @log.info("configScope ended")  
  
     found   
   end

  end
  

end
