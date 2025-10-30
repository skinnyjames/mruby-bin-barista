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
