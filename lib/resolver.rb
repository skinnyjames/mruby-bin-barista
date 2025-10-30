require_relative "./resolvers/git"
require_relative "./resolvers/github"
require_relative "./resolvers/local"
require_relative "./resolvers/http"
require_relative "./resolvers/no"
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
