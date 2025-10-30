module Barista
  module Emittable
    attr_reader :on_output, :on_error

    def on_output(&block)
      if block.nil?
        @on_output
      else
        @on_output = block
      end
    end

    def on_error(&block)
      if block.nil?
        @on_error
      else
        @on_error = block
      end
    end

    def forward_output(&block)
      on_output do |str|
        block.call(str)
      end

      self
    end

    def forward_error(&block)
      on_error do |str|
        block.call(str)
      end

      self
    end

    def collect_output(arr)
      on_output do |str|
        arr << str
      end
    end

    def collect_error(arr)
      on_error do |str|
        arr << str
      end
    end
  end
end