require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/UCSAPI'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'UCSAPI' do
  self.description = 'A simple ruby interface to the Cisco UCS XMLAPI'
  self.url = 'http://ciscoucs.rubyforge.org'
  self.developer 'Steve Chambers', 'stevie_chambers @nospam@ viewyonder.com'
  self.post_install_message = 'PostInstall.txt'
  self.rubyforge_name       = 'ciscoucs'
  self.extra_deps << ['rubygems-update']
  self.extra_deps << ['rest-client']
  self.readme_file = 'README.rdoc'
  self.rubyforge_name = 'ciscoucs'
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
