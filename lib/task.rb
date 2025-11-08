require_relative "./commands"
require_relative "./resolver"
require_relative "./dependency"

module Barista
  class Gem
    attr_reader :resolver, :override

    def initialize(config, **args, &override)
      @config = config
      @resolver = Resolver.locate(**args)
      @override = override
    end

    def resolve(parent)
      resolver.resolve

      file = File.read(File.join(resolver.path, "Brewfile"))
      spec = parent.instance_exec(resolver) do |res|
        Object.define_method(:location) do
          res.path
        end

        instance_eval(file)
      end

      spec
    end

    def id
      resolver.id
    end
  end

  class Task
    include Commands

    attr_reader :name, :resolver, :block, :dependencies, :path

    def initialize(name, path = ".", **args, &block)
      @name = name
      @path = path
      @resolver = Resolver.locate(**args)
      @block = block
      @dependencies = []
      @commands = []
      @task_args = {}
    end

    def detected_os
      Barista.os
    end

    def mac?
      detected_os == "MacOS"
    end
  
    def linux?
      detected_os == "Linux"
    end

    def windows?
      detected_os == "Windows"
    end

    def include(mod)
      self.class.include(mod)
    end

    def dependency(name, &block)  
      self.dependencies << Dependency.new(name, &block)
    end

    def execute
      build
  
      @commands.each(&:execute)
    end

    # we might want an immediate return value from processing a template 
    # so let's make a convience method
    def erb(src, string: false, vars: {})
      template_str = string ? src : File.read(src)
      erb = ERB.new(template_str)

      obj = Object.new
      vars.each do |k, v|
        obj.define_singleton_method(k) do
          v
        end
      end

      erb.result(obj)
    end

    def ruby_file(path)
      RubyResolver.new(path).code
    end

    # possible bug or misunderstanding
    # can't pass hash to instance_exec
    def load(hash)
      @task_args = hash
      # resolver.resolve!
      unless block.nil?
        instance_exec(self) do |obj|
          if block.parameters.first
            Object.define_method(block.parameters.first.last) do
              @task_args
            end
          end

          obj.instance_exec(@task_args, &block)
        end
      end
    end
  end
end
