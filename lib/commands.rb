require_relative "./emittable"
require_relative "./commands/base"
require_relative "./commands/block"
require_relative "./commands/command"
require_relative "./commands/copy"
require_relative "./commands/mkdir"

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
