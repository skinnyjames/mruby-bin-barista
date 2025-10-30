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
