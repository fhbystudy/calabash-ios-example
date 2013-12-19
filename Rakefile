require 'irb'

task :activate_simulator do
  sh "/usr/bin/osascript -e 'tell application \"#{ENV['DEVELOPER_DIR']}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\" to activate'"
end

task :show_simulator do
  Rake::Task['activate_simulator'].invoke
  sh "/usr/bin/osascript -e 'tell application \"RubyMine\" to activate'"
end

task :xamarin do
  exec 'xamarin-build.sh'
end

task :tag_report do
  sh 'cucumber -d -f Cucumber::Formatter::ListTags'
end

def bundle_id
  'com.lesspainful.example.LPSimpleExample-cal'
end


def read_device_info (device, kind)
  kind = kind.to_sym
  kinds = [:ip, :udid, :serial]
  unless kinds.include?(kind)
    raise "#{kind} must be one of '#{kinds}'"
  end
  cmd = "cat ~/.xamarin/devices/#{device}/#{kind} | tr -d '\n'"
  `#{cmd}`
end

# controls the launching of the simulator
# iOS 5 is no longer supported in Instruments
def sdk_versions
  {:ios6 => '6.1',
   :ios7 => '7.0'}
end


def default_device_opts
  bundle_path = `which bundle`
  use_bundler = (not bundle_path.eql?(''))
  {:bundle =>  use_bundler,
  :sdk_version => sdk_versions[:ios7] }
end

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

  env << "IRBRC='./.irbrc'"
  env << 'bundle exec' if opts[:bundle]
  env << 'irb'
  env.join(' ')
end


def ios_irb (device, opts={})
  default_opts = default_device_opts()
  opts = default_opts.merge(opts)
  exec "#{ios_console_cmd(device, opts)}"
end

# calabash simulator consoles

task :sim6 do ios_irb(:simulator, {:sdk_version => sdk_versions[:ios6]}) end
task :sim7 do ios_irb(:simulator, {:sdk_version => sdk_versions[:ios7]}) end

def simulator_hash
  {:iphone => 'iPhone Retina (3.5-inch)',
   :iphone_4in => 'iPhone Retina (4-inch)',
   :iphone_4in_64 => 'iPhone Retina (4-inch 64-bit)',
   :ipad => 'iPad',
   :ipad_r => 'iPad Retina',
   :ipad_r_64 => 'iPad Retina (64-bit)'}
end

def default_simulated_device
  res = `defaults read com.apple.iphonesimulator "SimulateDevice"`.chomp
  simulator_hash.each { |key, value|
    return key if res.eql?(value)
  }
  raise "could not find '#{res}' in hash values '#{simulator_hash}'"
end

def kill_simulator
  sh "/usr/bin/osascript -e 'tell application \"#{ENV['DEVELOPER_DIR']}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\" to quit'"
end

def set_default_simulator(device_key)
  hash = simulator_hash
  unless hash[device_key]
    raise "#{device_key} was not one of '#{hash.keys}'"
  end

  current_device = default_simulated_device()
  unless current_device.eql?(device_key)
    value = hash[device_key]
    puts "setting default simulator to '#{value}' using device key '#{device_key}'"
    `defaults write com.apple.iphonesimulator "SimulateDevice" '"#{value}"'`
    kill_simulator
  end
end


task :default_simulator do puts "#{default_simulated_device()}" end

task :set_simulator, :device_key do |t, args|
  key = args.device_key().to_sym
  set_default_simulator(key)
end

namespace :moody do

  # calabash device consoles
  task :venus do ios_irb('venus') end
  task :neptune do ios_irb('neptune') end
  task :earp do ios_irb('earp') end
  task :pluto do ios_irb('pluto') end

  def ideviceinstaller(device, cmd)
    cmds = [:install, :uninstall, :reinstall]
    raise "#{cmd} must be one of '#{cmds}'" unless cmds.include? cmd
    udid =  read_device_info(device, :udid)
    bin_dir='~/bin/libimobiledevice'

    if cmd == :install
      ipa='./xamarin/Briar-cal.ipa'
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
    device_set = '604f58c7' if device_set.eql?('mixed')
    profile = args.profile
    profile = 'xtc_wip' if profile.eql?('wip')

    ipa = 'LPSimpleExample-cal.ipa'
    # this will not work like you expect it to
    #sh 'cd xamarin; bundle update'
    sh "bundle exec test-cloud submit ./xamarin/#{ipa} #{api_key} -d #{device_set} --config cucumber.yml --profile #{profile}"
  end

end

