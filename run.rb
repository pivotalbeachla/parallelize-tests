require 'xcodeproj'
require 'sshkit'
require 'sshkit/dsl'
require 'concurrent'
include SSHKit::DSL


timestamp = Time.now.strftime("%Y%m%d_%H%M")
logger = Logger.new("ios-parallel-tests-#{timestamp}.log")

###
### Fetching test files
###

project_path = 'UnitTest.xcodeproj'
project = Xcodeproj::Project.open(project_path)

test_targets = project.targets.find_all { |target| target.name =~ /(?:Tests|Specs)$/ }

puts "### Fetching test files..."
logger.debug "Fetching test files"
list_of_tests = Concurrent::Array.new
test_targets.each do |target|
  target.source_build_phase.files.each do |file|
    basename = File.basename(file.file_ref.real_path.to_s, ".*")
    if basename =~ /(?:test(?:s)?|spec)$/i
      list_of_tests << target.name + "/" + basename
      puts "\t#{list_of_tests.last}"
    end
  end
end
list_of_tests.reverse!
logger.debug "Test files fetched"



###
### Executing tests in parallel
###

tests_results = Concurrent::Array.new

puts "### Running tests"

on %w{parallel-ios-testbox-1.local parallel-ios-testbox-2.local parallel-ios-testbox-3.local }, in: :parallel, wait: 5 do |host|
  as :pivotal  do
    within "workspace/parallelize-tests" do
      capture(:git, "pull")
      capture(:xcodebuild, "-scheme UnitTest build-for-testing -destination \"platform=iOS Simulator,name=iPhone 7\"")
      while !list_of_tests.empty? do
        if nextTest = list_of_tests.pop
          begin
            print "\n\t#{nextTest} \t\t-- #{host.hostname} :: Started"
            logger.info "\t#{nextTest} \t\t-- #{host.hostname} :: Started"
            test_run_result = capture(:xcodebuild, "-scheme UnitTest test-without-building -destination \"platform=iOS Simulator,name=iPhone 7\" -only-testing:#{nextTest}")
            tests_results << { name: nextTest, success: true, output: test_run_result, hostname: host.hostname }
            print "\n\t#{nextTest} \t\t-- #{host.hostname} :: Completed"
            logger.info "\t#{nextTest} \t\t-- #{host.hostname} :: Completed"
          rescue Exception => e
            if e.to_s =~ /is installing or uninstalling, and cannot be launched/
              logger.info "Flaky(?) test failure. Requeuing #{nextTest} -- #{host.hostname}"
              puts "retrying #{nextTest}"
              list_of_tests << nextTest
            else
              logger.info "\t#{nextTest} \t\t-- #{host.hostname} :: Failed"
              puts "\t#{nextTest} \t\t-- #{host.hostname} :: Failed"
              tests_results << { name: nextTest, success: false, output: e.inspect, hostname: host.hostname }
            end
          end
        end
      end
    end
  end
end



###
### Collecting tests results
###

File.open("test_results.data",'w') {|f| f.write(Marshal.dump(tests_results)) }

failing_tests = tests_results.inject([]) do |arr, result|
  begin
    if !result[:success]
      failing = result[:output][/Failing tests:.+\n\*\*/m].scan(/(-\[.+\])/)
      arr << failing if failing
    end
    arr
  rescue NoMethodError => error
    puts "Error parsing test failure #{error.to_s}"
    logger.error "Error parsing test failure #{error.to_s}"
    File.open("failing_error.data", 'w') {|f| f.write(Marshal.dump(result)) }
  end
end

unless failing_tests.empty?
  puts "\nFailing tests:\n\t#{failing_tests.join("\n\t")}\n** TEST FAILED **"
  logger.info "\nFailing tests:\n\t#{failing_tests.join("\n\t")}\n** TEST FAILED **"
end
