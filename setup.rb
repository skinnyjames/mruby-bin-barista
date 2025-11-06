#!/usr/bin/env ruby

require "pathname"

# thanks: https://github.com/iij/mruby-dir/blob/master/run_test.rb
gemname = File.basename(File.dirname(File.expand_path __FILE__))

if __FILE__ == $0
  repository, dir = 'https://github.com/mruby/mruby.git', File.join("tmp", "mruby")
  build_args = ARGV
  build_args = ['clean', 'all']  if build_args.nil? or build_args.empty?

  Dir.mkdir 'tmp' unless Dir.exist?('tmp')
  unless File.exist?(dir)
    system "git clone #{repository} #{dir}"
  end

  config = "#{__dir__}/build_config.rb"

  exit system(%Q[ruby resolve.rb && cd #{dir} && git checkout stable && MRUBY_CONFIG=#{config} rake #{build_args.join(' ')}])
end
