module Barista
  class OptionParser
    def initialize(str)
      parts = task.split(":")
      task = parts.shift
      args = {}

      while part = parts.shift
        k, v = part.split("=")
        args[k] = v
      end

      [task, args]
    end 
  end
end
