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
