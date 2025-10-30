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
