module Barista
  class Dependency
    attr_reader :name, :block

    def initialize(name, path = ".", &block)
      @name = name
      @path = path
      @block = block
      @files = {}
    end

    def files(*list)
      list.each do |file|
        @files[file] = File.exist?(file) ? File::Stat.new(file).mtime : nil
      end
    end

    def write(hash)
      @files.each do |fname, mtime|
        raise "File not found for #{name} -> #{fname}" unless File.exist?(fname)

        hash[fname] = File::Stat.new(fname).mtime.to_s
      end
    end

    # the dependency is active if
    # the dependent files do not exist and
    # the dependent files are newer or on par with the locked version of those files
    def active(locked = {})
      return true if block.nil?

      instance_eval(&block)

      @files.any? do |file, time|
        if !time
          true
        elsif locked[file].nil?
          true
        elsif time.to_i > Time.parse(locked[file]).to_i
          true
        else
          false
        end
      end
    end 
  end
end