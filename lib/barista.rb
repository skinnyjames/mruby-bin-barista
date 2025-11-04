require_relative "./emittable"
require_relative "./commands/base"
require_relative "./commands/command"
require_relative "./graph"
require_relative "./task"
require_relative "./registry"
require_relative "./orchestrator"
require_relative "./spec"
require_relative "./time"

module Barista
  class Error < StandardError; end
  
  module System
    def os
      Barista.os
    end
  end
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
