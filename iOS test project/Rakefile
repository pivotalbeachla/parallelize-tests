require 'rubygems'
require 'bundler'
Bundler.require(:default)
require 'benchmark'

$stdout.sync = true
$stderr.sync = true

if ENV['TRAVIS']
  SimCtl.default_timeout = 300
end

task :default => 'test'
desc 'Execute tests in multiple simulators'
task :test, [:specific_test] do |t, args|
  exit_code = 0

  args.with_defaults(:specific_test => :all)
  if args[:specific_test] != :all
    test_scope = args.extras.inject("-only #{args[:specific_test]}") do |tests, test|
      tests + ',' + test
    end
  else
    test_scope = nil
  end

  time = Benchmark.measure do
    xcodebuild = "xcodebuild -derivedDataPath '#{File.join(Dir.pwd, 'build')}' -scheme UnitTest -sdk iphonesimulator"

    # Destroy and create devices for given name, type and os version
    devices = [
      { simulator: SimCtl.reset_device('SampleApp iPhone', SimCtl.devicetype(name: 'iPhone 5s'),    SimCtl.runtime(name: 'iOS 10.0')), testFilter: 'UnitTestUITests/UnitTestUITests/testOne' },
      { simulator: SimCtl.reset_device('SampleApp iPad',   SimCtl.devicetype(name: 'iPhone 6'), SimCtl.runtime(name: 'iOS 10.0')), testFilter: 'UnitTestUITests/UnitTestUITests/testTwo' }
    ]
    devices.each do |device|
      # This is necessary because Travis seems to be slow...
      device[:simulator].wait!{|d| File.exists?(d.path.device_plist)}
      device[:simulator].launch!
    end

    # Build tests once
    sh "#{xcodebuild} build"

    threads = []

    # Run tests on each device in a separate thread
    devices.each do |device|
      threads << Thread.new do
        simulator = device[:simulator]
        testFilter = device[:testFilter]

        test_log = File.join(Dir.pwd, 'build', "#{simulator.name}.log")
        junit_xml = File.join(Dir.pwd, 'build', "#{simulator.name}.junit.xml")

        #cmd = "xcodebuild -scheme UnitTest test -sdk iphonesimulator -destination 'id=EB049490-ECAC-4D68-B00B-4ADEF709C656' -only-testing:UnitTestUITests/UnitTestUITests/testOne"
        #cmd = "#{xctool} run-tests  -only #{testFilter} -destination 'id=#{simulator.udid}' -reporter pretty -reporter plain:'#{test_log}' -reporter junit:'#{junit_xml}'"
        cmd = "#{xcodebuild} test -only-testing:#{testFilter} -destination 'id=#{simulator.udid}'"
        system cmd

        Thread.current[:result] = $?
        simulator.kill!
        simulator.wait! {|d| d.state == :shutdown}
        simulator.delete!
      end
    end

    # Wait for all threads to finish
    threads.each do |thread|
      thread.join
      exit_code |= thread[:result].to_i
    end
  end

  puts "Total time: #{time.real}s"

  exit exit_code
end

desc 'Launch app in multiple simulators'
task :launch do
  devices = [
    SimCtl.reset_device('SampleApp iPhone', SimCtl.devicetype(name: 'iPhone 5'),    SimCtl::Runtime.latest(:ios)),
    SimCtl.reset_device('SampleApp iPad',   SimCtl.devicetype(name: 'iPad Retina'), SimCtl::Runtime.latest(:ios)),
  ]
  devices.each { |device| device.launch! }

  build_path = File.join(Dir.pwd, 'build')
  xctool = File.join(Dir.pwd, 'xctool', 'xctool.sh')
  xctool = "#{xctool} -derivedDataPath '#{build_path}' -scheme SampleApp -sdk iphonesimulator -workspace SampleApp.xcworkspace"
  sh "#{xctool} build"

  devices.each do |device|
    device.install!(File.join(build_path, 'Build/Products/Debug-iphonesimulator/SampleApp.app'))
    device.launch_app!('com.plunien.SampleApp')
  end
end
