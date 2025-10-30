# mruby-bin-barista

A ruby build tool to execute a dependency graph of tasks

NOTE: this project is in proof-of-concept phase.  Actively accepting feedback and contributions.

features:

* file tracking
* argument handling
* rudiumentary handling for local and remote imports

# about

I originally made this project to handle processing separate mruby projects with more flexibility but a consistent compilation environment.
I have since moved it into a more generic build system.

running `barista <target>` in a directory will try to locate a `Brewfile` which describes a dependency graph of tasks.

an example:

```ruby
# declare a project spec
spec("new-barista-project") do |config|
  # define a task
  #
  # arguments paseed to this task via the cli will be reachable from the task.
  task "grind" do |args| 
    # the build method will be invoked when running the task
    def build
      # run arbitrary commands using helper methods and any cli arguments
      # this task writes to `beans.txt`
      command("echo 'grind #{args[:type] || 'arabica'} beans' > beans.txt")
    end
  end

  # another task which produces a file
  task "milk" do |args|
    def build
      command("echo 'steaming milk'")
      command("echo 'milk steamed!' > milk.txt")
    end
  end
  
  # a task with dependencies
  task "brew" do |args|
    # depends on the milk task
    #
    # if milk.txt changes, rerun the milk task
    dependency "milk" do
      files "milk.txt"
    end   

    # if beans.txt changes, rerun the grind task
    dependency "grind" do
      files "beans.txt"  
    end
 
    # wrap it up
    def build
      (args[:times] || 1).times do
        command("echo 'drip drip drip'")
      end

      command("echo 'all done!!'")
    end  
  end

  # remove produced files
  task "clean" do |args|
    def build
      command("rm -rf milk.txt && rm -rf beans.txt")
    end
  end
end
```

running `barista brew` will produce the following output.

```
new-barista-project run started
new-barista-project::milk started
new-barista-project::milk - running command: echo 'steaming milk'
new-barista-project::grind started
new-barista-project::grind - running command: echo 'grind arabica beans' > beans.txt
new-barista-project::milk - steaming milk
new-barista-project::milk - running command: echo 'milk steamed!' > milk.txt
new-barista-project::grind did the damn thing
new-barista-project::milk did the damn thing
new-barista-project::brew started
new-barista-project::brew - running command: echo 'drip drip drip'
new-barista-project::brew - drip drip drip
new-barista-project::brew - running command: echo 'all done!!'
new-barista-project::brew - all done!!
new-barista-project::brew did the damn thing
```

running `barista brew` again will produce the following output

```
new-barista-project run started
new-barista-project::brew started
new-barista-project::brew - running command: echo 'drip drip drip'
new-barista-project::brew - drip drip drip
new-barista-project::brew - running command: echo 'all done!!'
new-barista-project::brew - all done!!
new-barista-project::brew did the damn thing
```

`touch beans.txt && barista brew`

```
new-barista-project run started
new-barista-project::grind started
new-barista-project::grind - running command: echo 'grind arabica beans' > beans.txt
new-barista-project::grind did the damn thing
new-barista-project::brew started
new-barista-project::brew - running command: echo 'drip drip drip'
new-barista-project::brew - drip drip drip
new-barista-project::brew - running command: echo 'all done!!'
new-barista-project::brew - all done!!
new-barista-project::brew did the damn thing
```

## arguments

pass arguments to the task with the following syntax

`barista task:key=value:float=1.0:int=4:bool=true`

Let's try it

`barista brew:times=2`

```
new-barista-project run started
new-barista-project::brew started
new-barista-project::brew - running command: echo 'drip drip drip'
new-barista-project::brew - drip drip drip
new-barista-project::brew - running command: echo 'drip drip drip'
new-barista-project::brew - drip drip drip
new-barista-project::brew - running command: echo 'all done!!'
new-barista-project::brew - all done!!
new-barista-project::brew did the damn thing
```

## imports

an rough idea is to resolve imports via git/http/filesystem

```ruby
spec("barista-project") do
  # fetch and run the Brewfile in this project
  import github: "skinnyjames/some-other-barista-project"

  #....
end
```

It currently is tested with local file paths and will run all the tasks in the imported project. 

# dependencies

To build barista, you need ruby, and build tools such as a c compiler/make/git

Barista is built on mruby and should be portable once built.

# installation

`ruby setup.rb` to build and run tests

The `barista` binary will be located in `./tmp/mruby/build/host/bin/barista`

# goals

* implementing portable commands
* more robust imports
  * checksum handling and git fetching via bundled libgit2
* safer evaluation of code (don't run untrusted Brewfile!)
* more dependency resolvers (change in environment, or change in user defined values)

# contributing

This is in POC phase, so I'd love feedback.  There are currently a lot of unhandled edge cases, but feel free to make an issue.

If you have ideas please also make an issue!



