module Barista
  module Emittable
    attr_reader :on_output, :on_error

    def on_output(&block)
      if block.nil?
        @on_output
      else
        @on_output = block
      end
    end

    def on_error(&block)
      if block.nil?
        @on_error
      else
        @on_error = block
      end
    end

    def forward_output(&block)
      on_output do |str|
        block.call(str)
      end

      self
    end

    def forward_error(&block)
      on_error do |str|
        block.call(str)
      end

      self
    end

    def collect_output(arr)
      on_output do |str|
        arr << str
      end
    end

    def collect_error(arr)
      on_error do |str|
        arr << str
      end
    end
  end
end
module Barista
  module Commands
    class Base
      include Emittable

      def execute
        raise Barista::Error.new("#{self.class}#execute must be implemented")
      end

      def description
        raise Barista::Error.new("#{self.class}#description must be implemented")
      end
    end
  end
end

module Barista
  module Commands
    class Command < Base
      attr_reader :command, :chdir, :env
      
      def initialize(command, chdir: nil, env: {})
        @command = command
        @chdir = chdir
        @env = env
      end

      def execute
        on_output.call("running command: #{command}")
        dir = chdir || "."
        IO.popen("cd #{dir} && #{command}", File::NONBLOCK | File::RDONLY) do |io|
          io.nonblock!
          loop do
            begin
              while res = io.readline
                on_output.call(res.chomp)
              end
            rescue Errno::EAGAIN => ex
              Fiber.yield
            rescue EOFError
              break
            rescue StandardError => ex
              puts "WTF: #{ex}"
            end
          end
        end

        code = $?
        raise Barista::Error.new("command #{command} failed with exit #{code}") unless code == 0
      end

      def description
        <<~EOF
        #{command}#{chdir}#{env.to_s}
        EOF
      end
    end
  end
end

module Barista
  class GraphCyclicalError < StandardError; end

  class Graph
    attr_reader :nodes, :vertices

    def initialize(nodes = [], vertices = {})
      @nodes = nodes
      @vertices = vertices
    end

    def add(node)
      if vertex = vertices[node]
        return vertex
      end

      vertex = Vertex.new(name: node)
      vertices[node] = vertex
      nodes << node

      vertex
    end

    def add_edge(from, to)
      return if from == to

      from_vertex = add(from)
      to_vertex = add(to)

      return if to_vertex.incoming[from]

      Graph::Visitor.visit(vertex: from_vertex, callback: ensure_non_cylical(to))

      from_vertex.has_outgoing = true

      to_vertex.incoming[from] = from_vertex
      to_vertex.incoming_names << from

      vertices[from] = from_vertex
      vertices[to] = to_vertex
    end

    def filter(names, result = names.dup)
      return result.uniq if names.empty?

      name = names.shift
      vertex = vertices[name]
      result = (result + vertex.incoming_names)

      result.concat filter((vertex.incoming_names - names), result)
      filter(names, result)
    end

    def ensure_non_cylical(to)
      ->(vertex, path) do
        if vertex.name == to
          raise GraphCyclicalError.new("Cyclical reference detected: #{to} <- #{path.join(" <- ")}")
        end
      end
    end
  end

  class Graph::Vertex
    attr_accessor :name, :incoming, :incoming_names, :has_outgoing

    def initialize(name:, incoming: {}, incoming_names: [], has_outgoing: false)
      @name = name
      @incoming = incoming
      @incoming_names = incoming_names
      @has_outgoing = has_outgoing
    end

    def has_outgoing?
      has_outgoing
    end
  end

  class Graph::Visitor
    def self.visit(vertex:, callback:, visited: {}, path: [])
      node = vertex.name
      incoming = vertex.incoming
      incoming_names = vertex.incoming_names

      return if visited[node]

      path << node
      visited[node] = true

      incoming_names.each do |name|
        visit(vertex: incoming[name], callback: callback, visited: visited, path: path)
      end

      callback.call(vertex, path)
      path.pop
    end
  end
end
module Barista
  module Emittable
    attr_reader :on_output, :on_error

    def on_output(&block)
      if block.nil?
        @on_output
      else
        @on_output = block
      end
    end

    def on_error(&block)
      if block.nil?
        @on_error
      else
        @on_error = block
      end
    end

    def forward_output(&block)
      on_output do |str|
        block.call(str)
      end

      self
    end

    def forward_error(&block)
      on_error do |str|
        block.call(str)
      end

      self
    end

    def collect_output(arr)
      on_output do |str|
        arr << str
      end
    end

    def collect_error(arr)
      on_error do |str|
        arr << str
      end
    end
  end
end
module Barista
  module Commands
    class Base
      include Emittable

      def execute
        raise Barista::Error.new("#{self.class}#execute must be implemented")
      end

      def description
        raise Barista::Error.new("#{self.class}#description must be implemented")
      end
    end
  end
end

module Barista
  module Commands
    class Block < Base
      attr_reader :block
    
      def initialize(&block)
        @block = block
      end

      def execute
        block.call
      end
    end
  end
end

module Barista
  module Commands
    class Command < Base
      attr_reader :command, :chdir, :env
      
      def initialize(command, chdir: nil, env: {})
        @command = command
        @chdir = chdir
        @env = env
      end

      def execute
        on_output.call("running command: #{command}")
        dir = chdir || "."
        IO.popen("cd #{dir} && #{command}", File::NONBLOCK | File::RDONLY) do |io|
          io.nonblock!
          loop do
            begin
              while res = io.readline
                on_output.call(res.chomp)
              end
            rescue Errno::EAGAIN => ex
              Fiber.yield
            rescue EOFError
              break
            rescue StandardError => ex
              puts "WTF: #{ex}"
            end
          end
        end

        code = $?
        raise Barista::Error.new("command #{command} failed with exit #{code}") unless code == 0
      end

      def description
        <<~EOF
        #{command}#{chdir}#{env.to_s}
        EOF
      end
    end
  end
end

module Barista
  module Commands
    class Copy < Base
      attr_reader :src, :dest, :chdir, :env
    
      def initialize(src, dest, chdir: nil, env: {})
        @src = src
        @dest = dest
        @chdir = chdir
        @env = env
      end

      def execute
        cmd = File.directory?(src) ? "cp -R #{src} #{dest}" : "cp #{src} #{dest}"  

        Command.new(cmd, chdir: chdir, env: env)
          .forward_output(&on_output)
          .forward_error(&on_error)
          .execute
      end
    end
  end
end

module Barista
  module Commands
    class Mkdir < Base
      attr_reader :directory, :parent, :args

      def initialize(directory, parent: true, **args)
        @directory = directory
        @parent = parent
        @args = args
      end

      def execute
        cmd = parent ? "mkdir -p #{directory}" : "mdkir #{directory}"  

        Command.new(cmd, **args)
          .forward_output(&on_output)
          .forward_error(&on_error)
          .execute
      end
    end
  end
end


module Barista
  module Commands
    include Emittable

    def command(str, **args)
      args[:chdir] = File.join(path, args[:chdir] || ".")

      push_command(Commands::Command.new(str, **args)
        .forward_output(&on_output)
        .forward_error(&on_error))
    end

    def copy(src, dest, **args)
      push_command(Commands::Copy.new(src, dest, **args)
        .forward_output(&on_output)
        .forward_error(&on_error))
    end

    def mkdir(dir, **args)
      push_command(Commands::Mkdir.new(dir, **args)
        .forward_output(&on_output)
        .forward_error(&on_error))
    end

    def ruby(name = nil, &block)
      push_command(Commands::Block.new(&block)
        .forward_output(&on_output)
        .forward_error(&on_error))
    end

    def build
    end

    private

    def push_command(command)
      @commands ||= []
      @commands << command
      command
    end
  end
end

module Barista
  class GitResolver
    attr_reader :location, :branch

    def initialize(**args)
      @location = args[:git]
      @branch = args[:branch]
    end

    def id
      location
    end
    
    def resolve!

    end
  end
end

module Barista
  class GithubResolver
    attr_reader :repo, :branch

    def initialize(**args)
      @repo = args[:github]
      @branch = args[:branch]
    end

    def location
      "https://github.com/#{repo}"
    end

    def id
      repo
    end

    def resolve!
      IO.popen("git clone #{location}")
    end
  end
end

module Barista
  class LocalResolver
    attr_reader :location

    def initialize(**args)
      @location = args[:path]
    end

    def id
      location
    end

    def path
      @location
    end
    
    def resolve
      # no op
    end
  end
end

module Barista
  class HTTPResolver
    attr_reader :location

    def initialize(**args)
      @location = args[:http]
    end

    def id
      location
    end

    def resolve!

    end
  end
end

module Barista
  class NoResolver
    def location
      Dir.pwd
    end

    def resolve!

    end
  end
end
module Barista
  class Resolver
    def self.locate(**args)
      if args.empty?
        NoResolver.new(**args)
      elsif args[:github]
        GithubResolver.new(**args)
      elsif args[:git]
        GitResolver.new(**args)
      elsif args[:path]
        LocalResolver.new(**args)
      elsif args[:http]
        HTTPResolver.new(**args)
      end
    end
  end
end

module Barista
  class Dependency
    attr_reader :name, :block

    def initialize(name, path = ".", &block)
      @name = name
      @path = path
      @block = block.nil? ? Proc.new {} : block
      @files = {}
    end

    def files(*list)
      list.each do |file|
        @files[file] = File.exist?(file) ? File::Stat.new(file).mtime : nil
      end
    end

    def write(hash)
      @files.each do |fname, mtime|
        raise "File not found for #{name} -> #{fname}" unless File.exist?(fname)

        hash[fname] = File::Stat.new(fname).mtime.to_s
      end
    end

    # the dependency is active if
    # the dependent files do not exist and
    # the dependent files are newer or on par with the locked version of those files
    def active(locked = {})
      instance_eval(&block)

      @files.any? do |file, time|
        if !time
          true
        elsif locked[file].nil?
          true
        elsif time.to_i > Time.parse(locked[file]).to_i
          true
        else
          false
        end
      end
    end 
  end
end

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

module Barista
  class Registry
    attr_reader :tasks, :inverted

    def initialize(tasks = [])
      @tasks = tasks
      @inverted = false
    end

    def <<(task)
      tasks << task if self[task.name].nil?
    end

    def invert
      @inverted = true
      
      self
    end

    def dag(lock = {})
      graph = Graph.new
      
      tasks.dup.each do |task|
        graph.add(task.name)

        task.dependencies.each do |dependency|
          unless dependency.active(lock)
            next
          end

          if inverted
            graph.add_edge(task.name, dependency.name)
          else
            graph.add_edge(dependency.name, task.name)
          end
        end
      end

      graph
    end

    def [](name)
      to_groups[name]
    end

    def reset
      @tasks = []
      @inverted = false

      self
    end

    def upstreams(task)
      lookup = to_groups
      filtered = dag.filter([task])
      (filtered - [task]).sort.map do |name|
        lookup[name]
      end
    end

    def dependents(task)
      lookup = to_groups
      tasks.reduce([]) do |memo, itask|
        if itask.dependencies.map(&:name).include?(task)
          memo << lookup[itask.name]
        end

        memo
      end
    end

    private 

    def to_groups
      tasks.reduce({}) do |memo, task|
        memo[task.name] = task
        memo
      end
    end
  end
end

module Barista
  class OrchestrationInfo
    attr_reader :unblocked, :blocked, :building, :built, :active_sequences

    def initialize(unblocked: [], blocked: [], building: [], built: [], active_sequences: [])
      @unblocked = unblocked
      @blocked = blocked
      @building = building
      @built = built
      @active_sequences = active_sequences
    end
    
    def to_s
      [
        "Unblocked #{format(unblocked)}",
        "Blocked  #{format(blocked)}",
        "Building #{format(building)}",
        "Built #{format(built)}",
        "Active Sequences #{format(format_tuples(active_sequences))}"
      ].join("\n")
    end

    private def format(arr)
      arr.empty? ? "None" : arr.join(", ")
    end

    private def format_tuples(arr)
      return [] if arr.nil? || arr.empty?

      arr.map do |k, v|
        "{ #{k}, #{v} }"
      end
    end
  end

  class Orchestrator
    attr_reader :registry, :workers, :filter, :locked
    attr_reader :build_list, :building, :built
    attr_accessor :unblocker_fiber

    attr_accessor :on_run_start_cb, :on_run_finished_cb, :on_task_start_cb, 
                  :on_task_succeed_cb, :on_task_failed_cb, :on_task_finished_cb, :on_unblocked_cb

    def initialize(registry, workers: 1, filter: [], locked: {})
      @registry = registry
      @workers = workers
      @filter = filter.empty? ? nil : filter
      @locked = locked
      

      @building = []
      @built = []

      @build_list = !filter.empty? ? registry.dag(locked).filter(filter) : registry.dag(locked).nodes.dup
      @unblocker_fiber = nil
    end

    [:on_run_start, :on_run_finished, :on_task_start, :on_task_succeed, :on_task_failed, :on_task_finished, :on_unblocked].each do |sym|
      define_method("#{sym}") do |&block|
        self.send "#{sym}_cb=", block

        self
      end
    end

    def execute
      @ex = nil
      manager = nil
      @resume = false
    
      self.unblocker_fiber = Fiber.new do |initial|
        built_task = initial
        loop do
          break if built_task.nil?

          if built_task.is_a?(StandardError)
            @ex = built_task
            break
          end

          obj = registry[built_task]

          built << built_task
          building.delete(built_task)

          built_task = Fiber.yield
        end
      
        raise "Build raised excpetion: #{@ex}" unless @ex.nil?
      end

      on_run_start_cb&.call

      while build_list.size != built.size
        build_next
        Fiber.yield
      end

      on_run_finished_cb&.call
    end

    def build_next
      tasks = unblocked_queue.reduce([]) do |accepted, name|
        break(accepted) if at_capacity?
  
        task = registry[name]

        accepted << name
        building << name

        accepted
      end

      orchestration_info = OrchestrationInfo.new(
        unblocked: tasks.clone,
        blocked: build_list.dup - (building.dup + built.dup),
        building: building.clone,
        built: built.clone
      )

      on_unblocked_cb&.call(orchestration_info)

      fibers = []
      tasks.each do |task|
        fibers << Fiber.new do 
          work(task)
        end
      end

      while fiber = fibers.shift
        if fiber.alive?
          fiber.resume 
          fibers << fiber
        end
      end
    end

    def work(task)
      software = registry[task]
      on_task_start_cb&.call(task)

      begin
        software.execute
        on_task_succeed_cb&.call(task)
        res = unblocker_fiber.resume(task)
      rescue StandardError => ex
        on_task_failed_cb&.call(task, ex.to_s)
        res = unblocker_fiber.resume(ex)
      ensure
        on_task_finished_cb&.call(task)
      end
    end

    def unblocked_queue
      unblocked = build_list.select do |name|
        task = registry[name]
        vertex = registry.dag(locked).vertices[name]

        (vertex.incoming_names - built).size.zero? && 
          !built.include?(name) && 
            !building.include?(name)
      end

      unblocked
    end

    def at_capacity?
      building.size >= workers
    end

    def exit_on_failure?
      true
    end
  end
end


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

class Time
  def self.parse(input)
    if input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d+)Z/
      Time.utc($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, $7.to_i)
    elsif input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-]\d{2}:?\d{2})/
      year = $1.to_i
      month = $2.to_i
      day = $3.to_i
      hour = $4.to_i
      min = $5.to_i
      sec = $6.to_i
      utc_offset = $7
      offset = 0
      if utc_offset =~ /^-(\d{2}):?(\d{2})/
        offset = - $1.to_i * 60 * 60 + $2.to_i * 60
      elsif utc_offset =~ /^+(\d{2}):?(\d{2})/
        offset = $1.to_i * 60 * 60 + $2.to_i * 60
      end
      Time.new(year, month, day, hour, min, sec, offset)
    elsif input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\s+([+-]\d{2}:?\d{2})/
      year = $1.to_i
      month = $2.to_i
      day = $3.to_i
      hour = $4.to_i
      min = $5.to_i
      sec = $6.to_i
      utc_offset = $7

      if utc_offset =~ /^-(\d{2}):?(\d{2})/
        offset = - $1.to_i * 60 * 60 + $2.to_i * 60
      elsif utc_offset =~ /^\+(\d{2}):?(\d{2})/
        offset = $1.to_i * 60 * 60 + $2.to_i * 60
      end

      # only interested in this scenario
      Time.mktime(year, month, day, hour, min, sec)
    elsif input.upcase =~ /^(\d{4})-(\d{2})-(\d{2})/
      # YYYY-MM-DD
      Time.local($1.to_i, $2.to_i, $3.to_i)
    elsif input.upcase =~ /^(\d{4})(\d{2})(\d{2})/
      # YYYYMMDD as a fallback
      Time.local($1.to_i, $2.to_i, $3.to_i)
    else
      raise ArgumentError, "Failed to parse: <#{input}>"
    end
  end
end

module Barista
  class Error < StandardError; end
end


def spec(name, config = Barista::Spec::Config.new, gems = [], &block)
  spec = Barista::Spec.new(name, config)
  spec.instance_exec(spec, config) do |obj, config|
    if !block.parameters.empty? && block.parameters.first
      Object.define_method(block.parameters.first.last) do
        config
      end
    end

    obj.instance_exec(config, &block)
  end

  spec
end
