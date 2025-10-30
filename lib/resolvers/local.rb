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
