# Parallelizing iOS tests on virtualized OSX

This is a proof of concept script to divide a time consuming iOS test suite on multiple virtual machines. A quick (~2/3minutes) suite will not benefit from this strategy.

---

## Installation steps:

From now on we will refer to your workstation (or CI server) as the HOST.

On the HOST:
* `git clone https://github.com/pivotalbeachla/parallelize-tests.git`
* `cd parallelize-tests` and then run `bundle`
* install OSX server from the AppStore
* install VmWare Fusion
* create a new VmWare Fusion OSX virtual machine--follow the wizard that will create the OS from the HOST recovery disk
* turn on the virtual machine (refered to as GUEST from now on) and set its name ie. (parallel-ios-tests-1)
* enable the GUEST ssh access from System Preferences -> Sharing

  ### Provisioning GUEST
    * install xcode and necessary simulators
    * enable xcode developer mode
    * install git
    * install SSH certificate to allow git checkout
    * create a `PROJECT_DIRECTORY` and git clone your project--the project directory will be needed when Running the tests from the HOST


  ### Cloning GUEST to create a suite virtual machines
    * turn off the GUEST
    * from VmWare's menu: Virtual Machine -> Create full clone
    * once the new GUEST is turned on change its name
    * repeat this as long as you see your total test time decrease


## Running

Currently all the variables have to be provided via ENV variables ie.

```
LIST_OF_VMS="parallel-ios-testbox-1.local parallel-ios-testbox-2.local parallel-ios-testbox-3.local" PROJECT_FILE=UnitTest.xcodeproj SCHEME=UnitTest VM_PROJECT_DIRECTORY="workspace/parallelize-tests" DESTINATION="platform=iOS Simulator,name=iPhone 7" ruby run.rb
```

You should see green dots as test succeed and red F when they fail ie.

```
>> Detected 20 test files.
>> Parallelizing tests on 3 virtual machines
.................F..>> Failing tests:
  -[ExpectedToFailTests testFalse()]
  -[ExpectedToFailTests testTrue()]
** TEST FAILED **
>> FINISHED
```

## Logs

Each run will create a new timestamped file in the script's directory ie. `ios-parallel-tests-20161010_1026.log`. The log contains the whole xcodebuild outputs.

## Gotcha

We saw occasional test fails related to xcodebuild telling us the simulator "is installing or uninstalling, and cannot be launched". When we catch that you will see a orange R on the screen and we retry that test.
