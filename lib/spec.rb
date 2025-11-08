
module Barista
  class Spec
    class ::String
      # colorization
      def colorize(color_code)
        "\e[#{color_code}m#{self}\e[0m"
      end

      def red
        colorize(31)
      end

      def green
        colorize(32)
      end

      def yellow
        colorize(33)
      end

      def blue
        colorize(34)
      end

      def pink
        colorize(35)
      end

      def light_blue
        colorize(36)
      end
    end

    class CConfig
      attr_accessor :gcc, :ar, :libs, :objs, :includes,
                    :defines, :linker_flags, :linker_library_paths,
                    :flags, :mrbfiles

      def initialize
        @gcc = "gcc"
        @ar = "ar"
        @libs = []
        @objs = []
        @includes = []
        @defines = []
        @linker_flags = []
        @linker_library_paths = []
        @flags = []
        @mrbfiles = []
      end

      def gcc
        "#{@gcc} #{@defines.map{ |d| "-D#{d}" }.join(" ")}"
      end
    end

    class Config
      attr_accessor :version, :author, :gems, :cc, :bins

      def initialize
        @version = nil
        @author = nil
        @gems = {}
        @cc = CConfig.new
      end
    end

    attr_reader :name, :registry, :gems, :tasks, :config, :root, :path

    def initialize(name, config, path = ".", registry = Barista::Registry.new)
      @name = name
      @registry = registry
      @tasks = []
      @gems = []
      @config = config
      @path = path
      @root = Barista::Task.new("#{name}-task-root")
    end

    def scan_args(str)
      parts = str.split(":")
      task = parts.shift
      args = {}

      while part = parts.shift
        k, v = part.split("=")

        value = ""

        if v =~ /\d+/
          value = v.to_i
        elsif v =~ /\d+\.\d*/
          value = v.to_f
        elsif v == "true" || v == "false"
          value = (v == "true")
        else
          value = v
        end

        args[k.to_sym] = value
      end

      [task, args]
    end

    def execute(argstr = "", locked = {})
      tasks = {}
      locked = {}

      if File.exists?("barista.lock")
        file = File.read("barista.lock")
        begin
          locked = JSON.parse(file)
        rescue
          locked = {}
        end
      end

      argstr.split(" ").each do |foo|
        task, hash = scan_args(foo)
        tasks[task] = hash
      end

      fibers = gemspecs.map do |gemspec|
        Fiber.new do
          gemspec.execute
        end
      end
      
      colors = [:yellow, :blue, :pink, :light_blue]
      registry.tasks.each do |task|
        args = tasks[task.name]
        task.load(args || {})

        color = colors.shift
        task.on_output do |output|
          puts "#{name}::#{task.name} - #{output}".send(color)
        end

        colors << color
      end

      filtered = tasks.map {|k, t| registry[k].name }

      orchestrator = Barista::Orchestrator.new(registry, workers: 2, locked: locked, filter: filtered)

      orchestrator.on_run_start do
        puts "#{name} run started"
      end

      orchestrator.on_task_start do |task|
        puts "#{name}::#{task} started"
      end

      orchestrator.on_task_failed do |task, ex|
        puts "#{name}::#{task} failed #{ex}".red
      end

      orchestrator.on_task_succeed do |task|
        puts "#{name}::#{task} did the damn thing".green

        registry.dependents(task).each do |dependent|
          dep = dependent.dependencies.find { |d| d.name == task }
          dep.write(locked)
        end

        ::File.open("barista.lock", "w") { |io| io << locked.to_json }


        Fiber.yield
      end

      orchestrator.on_run_finished do
        ::File.open("barista.lock", "w") { |io| io << locked.to_json }
      end

      # orchestrator.on_unblocked do |unblock|
      #   puts unblock.to_s
      # end

      fibers << Fiber.new do
        orchestrator.execute
      end

      while fiber = fibers.shift 
        if fiber.alive?
          fiber.resume
          fibers << fiber
        end
      end
    end

    def task(name, **args, &block)
      task = Barista::Task.new(name, path, **args, &block)
      root.dependency task.name
      registry << task
    end

    def import(name = nil, **args, &block)
      args[:path] = File.join(path, args[:path]) if args[:path]
      gems << Gem.new(config, **args, &block)
    end

    def spec(name, &block)
      conf = Barista::Spec::Config.new
      conf.cc = config.cc
      conf.gems = config.gems

      # location is dynamically set from task.rb
      spec = Barista::Spec.new(name, conf, location)
      spec.instance_exec(spec, config) do |obj, config|
        if !block.parameters.empty? && block.parameters.first
          Object.define_method(block.parameters.first.last) do
            config
          end
        end

        obj.instance_exec(config, &block)
        obj
      end

      spec
    end

    def gemspecs
      @gemspecs ||= begin
        stack = gems.dup
        specs = []

        while gem = stack.shift
          next if config.gems[gem.id]

          spec = gem.resolve(self)
          next if config.gems[spec.name]

          specs.unshift spec

          config.gems[gem.id] = true
          config.gems[spec.name] = spec

          stack.concat spec.gems
        end

        specs
      end
    end
  end
end
