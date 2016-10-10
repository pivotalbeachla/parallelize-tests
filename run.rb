require 'xcodeproj'
require 'sshkit'
require 'sshkit/dsl'
require 'concurrent'
require 'colorize'

include SSHKit::DSL

###
### Validate required inputs
###

begin
  list_of_vms = ENV.fetch('LIST_OF_VMS').split(' ')
  project_path = ENV.fetch('PROJECT_FILE')
  scheme = ENV.fetch('SCHEME')
  vm_project_directory = ENV.fetch('VM_PROJECT_DIRECTORY') # ie. "workspace/parallelize-tests"
  destination = ENV.fetch('DESTINATION') # ie. \"platform=iOS Simulator,name=iPhone 7\"
rescue
  puts "!!! ERROR".red
  puts "Please provide all the following environment variables:".red
  puts 'LIST_OF_VMS ~> space separated list of VMs IPs or DNS ie. LIST_OF_VMS="parallel-ios-testbox-1.local parallel-ios-testbox-2.local parallel-ios-testbox-3.local"'
  puts 'PROJECT_FILE'
  puts 'SCHEME'
  puts 'VM_PROJECT_DIRECTORY'
  puts 'DESTINATION ie. DESTINATION="platform=iOS Simulator,name=iPhone 7"'
  exit
end


#list_of_vms = %w{parallel-ios-testbox-1.local parallel-ios-testbox-2.local parallel-ios-testbox-3.local }
timestamp = Time.now.strftime("%Y%m%d_%H%M")
logger = Logger.new("ios-parallel-tests-#{timestamp}.log")

###
### Fetching test files
###

project = Xcodeproj::Project.open(project_path)
test_targets = project.targets.find_all { |target| target.name =~ /(?:Tests|Specs)$/ }

logger.debug "Fetching test files"
list_of_tests = Concurrent::Array.new
test_targets.each do |target|
  target.source_build_phase.files.each do |file|
    basename = File.basename(file.file_ref.real_path.to_s, ".*")
    if basename =~ /(?:test(?:s)?|spec)$/i
      list_of_tests << target.name + "/" + basename
    end
  end
end

puts ">> Detected #{list_of_tests.count} test files."
logger.debug "Detected #{list_of_tests.count} test files: #{list_of_tests.join(', ')}"


###
### Executing tests in parallel
###

tests_results = Concurrent::Array.new

puts ">> Parallelizing tests on #{list_of_vms.count} virtual machines"

on list_of_vms, in: :parallel, wait: 5 do |host|
  as :pivotal  do
    within vm_project_directory  do
      capture(:git, "pull")
      capture(:xcodebuild, "-scheme #{scheme} build-for-testing -destination \"#{destination}\"")
      while !list_of_tests.empty? do
        if nextTest = list_of_tests.pop
          begin
            logger.debug "#{nextTest} -- #{host.hostname} :: Started"
            test_run_result = capture(:xcodebuild, "-scheme #{scheme} test-without-building -destination \"#{destination}\" -only-testing:#{nextTest}")
            tests_results << { name: nextTest, success: true, output: test_run_result, hostname: host.hostname }
            logger.debug "#{nextTest} -- #{host.hostname} #{test_run_result}"
            logger.info "#{nextTest} -- #{host.hostname} :: Completed"
            print ".".colorize(:green)
          rescue Exception => e
            if e.to_s =~ /is installing or uninstalling, and cannot be launched/
              logger.info "Flaky(?) test failure. Requeuing #{nextTest} -- #{host.hostname}"
              print "R".colorize(:orange)
              list_of_tests << nextTest
            else
              print "F".colorize(:red)
              logger.info "#{nextTest} -- #{host.hostname} :: Failed"
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

failing_tests = tests_results.inject([]) do |arr, result|
  if !result[:success]
    failing = result[:output][/Failing tests:.+\n\*\*/m].scan(/(-\[.+\])/)
    arr << failing if failing
  end
  arr
end

unless failing_tests.empty?
  puts ">> Failing tests:\n\t#{failing_tests.join("\n\t")}\n** TEST FAILED **"
  logger.info "\nFailing tests:\n#{failing_tests.join("\n")}\n** TEST FAILED **"
end

puts ">> FINISHED"
