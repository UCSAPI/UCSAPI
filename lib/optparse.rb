#!/opt/local/bin/ruby
$: << '.'
require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
  opts.on('--url','The full url of UCS API, as in http://host.fqdn.com/nuova') do |url|
    options[:url] = url
  end
  opts.on('--name','The username to logon to UCS API, sent in <aaaLogin> as inName') do |name|
    options[:name] = name
  end
  opts.on('--password','The password to logon to UCS API, sent in <aaaLogin> as inPassword') do |password|
    options[:password] = password
  end
end
optparse.parse!
puts options
