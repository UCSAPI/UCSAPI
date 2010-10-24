#!/opt/local/bin/ruby

# == Synopsis 
#   Test the UCSAPI code
#
# == Examples
#   tc_ucsapi --url http://my.ucs.com/nuova --name myuser --password secret --verbose 
#
# == Usage 
#   tc_ucsapi --url URL --name NAME --password PASSWORD [--verbose] [--version] [--help]
#
#   For help use: tc_ucsapi -h | --help
#
# == Options
#   -u, --url           FQDN URL of the tart UCS API, including the /nuova path
#   -n, --name          Username to logon to UCS API
#   -p, --password      Password to logon to UCS API
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -V, --verbose       Verbose output
#
# == Author
#   Steve Chambers, Cisco
#   Blogger at http://viewyonder.com
#
# == Copyright
#   Copyright (c) 2010 Steve Chambers. Licensed under the Create Commons Unported
#   http://creativecommons.org/licenses/by/3.0/ 

# TO DO - replace all of this with Test::Unit!!
$: << '.'
require 'UCSAPI'
require 'optparse'
require 'logger'
require 'singleton'
require 'UCSMO'

class TestCase
  VERSION = '0.0.1'

  include UCSAPI
  
  def initialize(args,stdin)
    @args = args
    @stdin = stdin    
    @options = {}  
  end
  
  def run        
    optparse = OptionParser.new do |opts|
      opts.on('--url URL','The full url of UCS API, as in http://host.fqdn.com/nuova') do |url|
        @options[:url] = url
      end
      opts.on('--name NAME','The username to logon to UCS API, sent in <aaaLogin> as inName') do |name|
        @options[:inName] = name
      end
      opts.on('--password PASSWORD','The password to logon to UCS API, sent in <aaaLogin> as inPassword') do |password|
        @options[:inPassword] = password
      end
      opts.on('--verbose','Turn verbose logging on or off') do |verbose|
        @options[:verbose] = verbose
      end
    end
    optparse.parse!

    @log = Logger.new(STDOUT)
    @log.level = @options[:verbose] ? Logger::INFO : Logger::ERROR
    @log.progname = self.class.to_s
    @log.info("Beginning tests")
    @ucs = UCS.new(@options)
    @ucs.login
    
    begin
      tc_fabric
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    ensure
      @ucs.logout
      exit
    end
    
    @ucs.logout
    
    @log.info "run ended"
  end
  
  def tc_fabric
    @log.info "tc_fabric started"
    
    puts "\nTEST: GET ALL FABRICS - @ucs.fabric"
    puts @ucs.fabrics.to_s
    
    puts "\nTEST: GET FABRIC A BY ID - @ucs.fabric(:id = 'A')"
    puts @ucs.fabric(:id => 'A').to_s
    
    puts "\nTEST: GET FABRIC B BY DN - @ucs.fabric(:dn => 'sys/switch-B')"
    puts @ucs.fabric(:dn => 'sys/switch-B').to_s
    
    
    puts "\nTEST: GET ALL FABRICS TOTAL MEMORY - @ucs.fabric.totalMemory"
    puts @ucs.fabric.totalMemory
    
    puts "\nTEST: NON-EXISTENT METHOD VIA FABRIC ARRAY PROXY - @ucs.fabric.noSuchMethod"
    puts @ucs.fabric.noSuchMethod
    
    puts "\nTEST: GET ALL FABRIC ATTRIBUTES - @ucs.fabric.attributes"
    puts @ucs.fabric.attributes
    
    puts "\nTEST: GET ALL FABRIC INSPECT - @ucs.fabric.each { |fabric| puts fabric.inspect }"
    @ucs.fabric.each { |fabric| puts fabric.inspect }

    puts "\nTEST: USE FABRICS PROXY METHOD - @ucs.fabrics(:id => 'A')"
    puts @ucs.fabrics(:id => 'A')
    
    puts "\nTEST: GET FABRIC A BOOTFLASH - @ucs.fabric(:id=>'A').bootflash"
    puts @ucs.fabric(:id=>'A').bootflash

    puts "\nTEST: GET ALL FABRICS BOOTFLASH - @ucs.fabric.bootflash"
    puts @ucs.fabric.bootflash
    
    puts "\nTEST: GET FABRIC A WORKSPACE - @ucs.fabric(:id=>'A').workspace"
    puts @ucs.fabric(:id=>'A').workspace

    puts "\nTEST: GET FABRIC A WORKSPACE SIZE - @ucs.fabric(:id=>'A').workspace.size"
    puts @ucs.fabric(:id=>'A').workspace.size

    puts "\nTEST: GET ALL FABRICS WORKSPACE - @ucs.fabric.workspace"
    puts @ucs.fabric.workspace    
    
    puts "\nTEST: GET FABRIC A OPT - @ucs.fabric(:id=>'A').opt"
    puts @ucs.fabric(:id=>'A').opt

    puts "\nTEST: GET FABRIC A OPT SIZE - @ucs.fabric(:id=>'A').opt.size"
    puts @ucs.fabric(:id=>'A').opt.size

    puts "\nTEST: GET ALL FABRICS OPT - @ucs.fabric.opt"
    puts @ucs.fabric.opt
 
    puts "\nTEST: GET FABRIC A STATS - @ucs.fabric(:id=>'A').stats"
    puts @ucs.fabric(:id=>'A').stats

    puts "\nTEST: GET FABRIC A LOAD - @ucs.fabric(:id=>'A').stats.load"
    puts @ucs.fabric(:id=>'A').stats.load

    puts "\nTEST: GET ALL FABRICS STATS - @ucs.fabric.stats"
    puts @ucs.fabric.stats
      
    puts "\nTEST: GET FABRIC A SLOTS - @ucs.fabric(:id=>'A').slots"
    puts @ucs.fabric(:id=>'A').slots
      
    puts "\nTEST: GET FABRIC A SLOT 1 - @ucs.fabric(:id=>'A').slot(:id=>1)"
    puts @ucs.fabric(:id=>'A').slot(:id=>1).to_s

    puts "\nTEST: GET ALL FABRICS ALL SLOTS - @ucs.fabric.slots"
    puts @ucs.fabrics.slots    
    
    puts "\nTEST: GET ALL SLOTS ALL ATTRIBUTES - @ucs.fabric.slots.attributes"
    puts @ucs.fabrics.slots.attributes
    
    puts "\nTEST: GET THE SERIAL NUMBER OF ALL SLOTS - @ucs.fabric.slots.serial"
    puts @ucs.fabrics.slots.serial 
    
    puts "\nTEST: GET THE NUM PORTS OF FABRIC A SLOT 1 - @ucs.fabric( :id => 'A').slot( :id => 1 ).numPorts"
    puts @ucs.fabric( :id => 'B').slot( :id => 1 ).numPorts
    
    @log.info "tc_fabric ended"
  end

end

tc = TestCase.new(ARGV,STDIN)
tc.run
