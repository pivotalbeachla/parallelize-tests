require 'xcodeproj'
project_path = 'UnitTest.xcodeproj'
project = Xcodeproj::Project.open(project_path)

test_targets = project.targets.find_all { |target| target.name =~ /(?:Tests|Specs)$/ }

puts "### Fetching test files..."
list_of_tests = []
test_targets.each do |target|
  target.source_build_phase.files.each do |file|
    basename = File.basename(file.file_ref.real_path.to_s, ".*")
    if basename =~ /(?:test(?:s)?|spec)$/i
      list_of_tests << target.name + "/" + basename
      puts list_of_tests.last
    end
  end
end
puts "### DONE!"

#raise "BOOM"
# --------

require 'sshkit'
require 'sshkit/dsl'
include SSHKit::DSL

tests_results = []

puts "### Running tests"

on %w{parallel-ios-testbox-1.local parallel-ios-testbox-2.local parallel-ios-testbox-3.local }, in: :parallel, wait: 5 do |host|
  as :pivotal  do
    within "workspace/parallelize-tests" do
      capture(:git, "pull")
      capture(:xcodebuild, "-scheme UnitTest build-for-testing -destination \"platform=iOS Simulator,name=iPhone 7\"")
      while !list_of_tests.empty? do
        # TODO: check if it's thread safe
        if nextTest = list_of_tests.pop
          begin
            test_run_result = capture(:xcodebuild, "-scheme UnitTest test-without-building -destination \"platform=iOS Simulator,name=iPhone 7\" -only-testing:#{nextTest}")
            tests_results << { name: nextTest, success: true, output: test_run_result }
          rescue Exception => e
            failed = true
            tests_results << { name: nextTest, success: false, output: e.to_s }
          end
        end
      end
    end
  end
end

failing_tests = tests_results.inject([]) do |arr, result|
  if !result[:success]
    arr += result[:output][/Failing tests:\s+(.+)\n\*\*/].scan(/(-\[.+\])/).flatten
  end
end

unless failing_tests.empty?
  puts "\nFailing tests:\n#{failing_tests.join("\n")}"
end
