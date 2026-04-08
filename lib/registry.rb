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

    def dag
      graph = Graph.new
      
      tasks.dup.each do |task|
        graph.add(task.name)

        task.dependencies.each do |dependency|
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

    # given `barista cli raylib:ok=true`
    def filter(names, lock = {})
      lookup = to_groups
      results = []

      reduced = names.reduce do |first, second|
        if dag.upstreams(first).include?(second)
          first
        else dag.upstreams(second).include?(first)
          second
        end
      end

      results << lookup[reduced]

      stack = names.clone

      while name = stack.shift
        task = lookup[name]
        active = false
        intern = []

        task.dependencies.each do |dep|
          missing = dep.missing(lock.dig(task.name, dep.name) || {})
          isactive = dep.active(lock.dig(task.name, dep.name) || {})

          if missing || isactive && !lock.dig(task.name, dep.name).nil?
            active = true
          end

          if isactive
            intern << lookup[dep.name]
          end

          stack.unshift dep.name
        end

        if active
          results << task
        end

        results.concat(intern)
      end

      results.map(&:name).uniq
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
