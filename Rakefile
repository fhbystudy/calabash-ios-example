require 'irb'

# tell the simulator to become the foremost app
#
# uses Apple Script
def activate_simulator
  sh "/usr/bin/osascript -e 'tell application \"#{ENV['DEVELOPER_DIR']}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\" to activate'"
end

desc 'make the simulator the foremost app'
task :launch_sim do activate_simulator end

# tell RubyMine to become the foremost app
def activate_rubymine
  sh "/usr/bin/osascript -e 'tell application \"RubyMine\" to activate'"
end

desc 'make RubyMine the foremost app'
task :activate_rubymine do
  activate_simulator
  activate_rubymine
end

desc 'build and package the project so in can be submitted to the test cloud'
task :xamarin do exec 'xamarin-build.sh' end

desc 'generate a cucumber tag report'
task :tag_report do sh 'cucumber -d -f Cucumber::Formatter::ListTags' end

# returns the bundle id of the app
def bundle_id
  'com.lesspainful.example.LPSimpleExample-cal'
end

# return the device info by reading and parsing the relevant file in the
# ~/.xamarin directory
#
#   read_device_info('neptune', :udid) # => reads the neptune udid (iOS)
#   read_device_info('earp', :ip)      # => reads the earp udid (iOS)
#   read_device_info('r2d2', :serial)  # => read the r2d2 serial number (android)
def read_device_info (device, kind)
  kind = kind.to_sym
  kinds = [:ip, :udid, :serial]
  unless kinds.include?(kind)
    raise "#{kind} must be one of '#{kinds}'"
  end
  cmd = "cat ~/.xamarin/devices/#{device}/#{kind} | tr -d '\n'"
  `#{cmd}`
end

# returns an iOS version string based on a canonical key
#
# the iOS version string is used to control which version of the simulator is
# launched.  use this to set the +SDK_VERSION+.
#
# IMPORTANT: launching an iOS 5 simulator is not support in Xcode 5 or greater
# IMPORTANT: Instruments 5.0 cannot be used to launch an app on an iOS 5 device
def sdk_versions
  {:ios5 => '5.1',
   :ios6 => '6.1',
   :ios7 => '7.0'}
end

# returns a hash with default arguments for various launch and irb functions
def default_device_opts
  bundle_path = `which bundle`
  use_bundler = (not bundle_path.eql?(''))
  {:bundle =>  use_bundler,
  :sdk_version => sdk_versions[:ios7],
  :launch => true}
end

# returns a string that can be use to launch a <tt>calabash-ios console</tt>
# that is configured using the opts hash
#
#   ios_console_cmd('neptune') # => a command to launch an irb against neptune
#
# used to create rake tasks like:
#
#   rake moody:neptune
def ios_console_cmd(device, opts={})
  default_opts = default_device_opts()
  opts = default_opts.merge(opts)

  # make a screenshot directory if one does not exist
  # *** trailing slash required ***
  ss_path = './screenshots/'
  FileUtils.mkdir(ss_path) unless File.exists?(ss_path)

  env = ["SCREENSHOT_PATH=#{ss_path}",
         'DEBUG=1',
         'CALABASH_FULL_CONSOLE_OUTPUT=1']

  if device.eql? :simulator
    udid = 'simulator'
    env << "DEVICE_TARGET='#{udid}'"
    sdk_version = opts[:sdk_version]
    env << "SDK_VERSION='#{sdk_version}'"
  else
    udid = read_device_info device, :udid
    env << "DEVICE_TARGET='#{udid}'"
    ip = read_device_info device, :ip
    env << "DEVICE_ENDPOINT='#{ip}'"
    bundle_id = bundle_id()
    env << "BUNDLE_ID='#{bundle_id}'"
  end

  env << "NO_LAUNCH=#{opts[:launch] ? '0' : '1'}"

  env << "IRBRC='./.irbrc'"
  env << 'bundle exec' if opts[:bundle]
  env << 'irb'
  env.join(' ')
end

# spawns a calabash console for the device using the opts hash
def ios_irb (device, opts={})
  default_opts = default_device_opts()
  opts = default_opts.merge(opts)
  cmd = ios_console_cmd(device, opts)
  puts "#{cmd}"
  exec cmd
end

# calabash simulator consoles

desc 'starts a calabash-ios console against the iOS 6 simulator'
task :sim6 do ios_irb(:simulator, {:sdk_version => sdk_versions[:ios6]}) end
desc 'starts a calabash-ios console against the iOS 7 simulator'
task :sim7 do ios_irb(:simulator, {:sdk_version => sdk_versions[:ios7]}) end

# returns a verbose simulator description key based on a canonical key
#
# using to control which simulator is launched
def simulator_hash
  {:iphone => 'iPhone Retina (3.5-inch)',
   :iphone_4in => 'iPhone Retina (4-inch)',
   :iphone_4in_64 => 'iPhone Retina (4-inch 64-bit)',
   :ipad => 'iPad',
   :ipad_r => 'iPad Retina',
   :ipad_r_64 => 'iPad Retina (64-bit)'}
end

# returns a canonical key for the current default simulator
def default_simulated_device
  res = `defaults read com.apple.iphonesimulator "SimulateDevice"`.chomp
  simulator_hash.each { |key, value|
    return key if res.eql?(value)
  }
  raise "could not find '#{res}' in hash values '#{simulator_hash()}'"
end

# kills the simulator if it is running
#
# uses Apple Script
def kill_simulator
  cmd = "xcode-select --print-path | tr -d '\n'"
  dev_dir = `#{cmd}`
  sh "/usr/bin/osascript -e 'tell application \"#{dev_dir}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\" to quit'"
end

desc 'kills the current simulator'
task :kill_sim do kill_simulator end


# sets the default simulator using a canonical key
#
#          :iphone # => 'iPhone Retina (3.5-inch)'
#      :iphone_4in # => 'iPhone Retina (4-inch)'
#   :iphone_4in_64 # => 'iPhone Retina (4-inch 64-bit)'
#            :ipad # => 'iPad'
#          :ipad_r # => 'iPad Retina'
#       :ipad_r_64 # => 'iPad Retina (64-bit)'
#
def set_default_simulator(device_key)
  hash = simulator_hash
  unless hash[device_key]
    raise "#{device_key} was not one of '#{hash.keys}'"
  end

  activate_simulator
  current_device = default_simulated_device()
  unless current_device.eql?(device_key)
    value = hash[device_key]
    puts "setting default simulator to '#{value}' using device key '#{device_key}'"
    `defaults write com.apple.iphonesimulator "SimulateDevice" '"#{value}"'`
    kill_simulator
  end
  activate_simulator
end

desc 'returns the default simulator as a canonical key'
task :default_simulator do puts "#{default_simulated_device()}" end

desc 'sets the default simulator using a canonical key'
task :set_simulator, :device_key do |t, args|
  key = args.device_key().to_sym
  set_default_simulator(key)
end

desc 'set the default simulator to the iphone 3.5in'
task :set_sim_iphone do set_default_simulator(:iphone) end
desc 'set the default simulator to the iphone 4in'
task :set_sim_iphone_4in do set_default_simulator(:iphone_4in) end
desc 'set the default simulator to the iphone 4in 64bit'
task :set_sim_iphone_64 do set_default_simulator(:iphone_4in_64) end
desc 'set the default simulator to the ipad (non retina)'
task :set_sim_ipad do set_default_simulator(:ipad) end
desc 'set the default simulator to the ipad retina'
task :set_sim_ipad_r do set_default_simulator(:ipad_r) end
desc 'set the default simulator to the ipad retina 64 bit'
task :set_sim_ipad_64 do set_default_simulator(:ipad_r_64) end



# my stuff
namespace :moody do

  def ruby_versions
    {'20' => '2.0.0-p353',
     '19' => '1.9.3-p484',
     '18' => '1.8.7-p374'}
  end

  def switch_ruby_version(version)
    versions = ruby_versions
    unless versions[version]
      raise "expected version '#{version}' to be one of '#{versions}'"
    end
    sh "rbenv local #{versions[version]}"
    sh 'rbenv rehash'
  end

  task :ruby18 do switch_ruby_version('18') end
  task :ruby19 do switch_ruby_version('19') end
  task :ruby20 do switch_ruby_version('20') end

  def reinstall_gems
    puts 'uninstalling gems'
    `gem list --no-version | xargs gem uninstall -ax`
    puts 'installing bundler'
    `gem install bundler`
    puts 'installing gems'
    `bundle install`
  end

  #noinspection RubyUnusedLocalVariable
  def smoke_test(device)
    reinstall_gems
    cmd = "bundle exec cucumber -p quiet -p #{device} --tags @smoke_test"
    sh cmd
  end

  task :venus_smoke do smoke_test 'venus' end

  # calabash device consoles
  task :venus do ios_irb('venus') end
  task :earp do ios_irb('earp') end
  task :neptune do ios_irb('neptune', {:launch => false, :sdk_version => sdk_versions[:ios6]}) end
  task :pluto do ios_irb('pluto', {:launch => false, :sdk_version => sdk_versions[:ios5]}) end

  def ideviceinstaller(device, cmd)
    cmds = [:install, :uninstall, :reinstall]
    raise "#{cmd} must be one of '#{cmds}'" unless cmds.include? cmd
    udid =  read_device_info(device, :udid)
    bin_dir='~/bin/libimobiledevice'

    if cmd == :install
      sh './xamarin-build.sh'
      ipa='./xamarin/LPSimpleExample-cal.ipa'
      sh "export DYLD_LIBRARY_PATH=#{bin_dir}; #{bin_dir}/ideviceinstaller -U #{udid} --install #{ipa}"
    elsif cmd == :uninstall
      bundle_id = bundle_id()
      sh "export DYLD_LIBRARY_PATH=#{bin_dir}; #{bin_dir}/ideviceinstaller -U #{udid} --uninstall #{bundle_id}"
    else
      ideviceinstaller(device, :uninstall)
      ideviceinstaller(device, :install)
    end
  end

  task :pluto_reinstall do ideviceinstaller('pluto', :reinstall) end
  task :neptune_reinstall do ideviceinstaller('neptune', :reinstall) end
  task :venus_reinstall do ideviceinstaller('venus', :reinstall) end
  task :earp_reinstall do ideviceinstaller('earp', :reinstall) end

  # test cloud
  #noinspection RubyUnusedLocalVariable
  task :tc, :device_set, :profile do |t, args|
    sh './xamarin-build.sh'

    api_key= `cat ~/.xamarin/test-cloud/moody | tr -d '\n'`

    device_set = args.device_set
    device_set = 'fdc46092' if device_set.eql?('iphones')
    device_set = '4b583121' if device_set.eql?('5S')

    profile = args.profile

    ipa = 'LPSimpleExample-cal.ipa'
    sh "cd xamarin; bundle exec test-cloud submit #{ipa} #{api_key} -d #{device_set} -c cucumber.yml -p #{profile}"
  end

end

