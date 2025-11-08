MRuby::Gem::Specification.new('mruby-bin-barista') do |spec|
  spec.license = 'MIT'
  spec.author  = 'skinnyjames'
  spec.summary = 'mruby build tool'
  spec.version = '0.2.5'
  spec.add_dependency "mruby-class-ext"
  spec.add_dependency 'mruby-metaprog'
  spec.add_dependency 'mruby-file-stat'
  spec.add_dependency 'mruby-dir'
  spec.add_dependency 'mruby-dir-glob'
  spec.add_dependency 'mruby-iijson'
  spec.add_dependency 'mruby-bin-theorem', '> 0.1.0', github: "skinnyjames/mruby-bin-theorem", branch: "main"
  spec.add_dependency 'mruby-time'
  spec.add_dependency 'mruby-env', github: 'iij/mruby-env'
  spec.add_dependency 'mruby-erb'
  spec.bins = ["barista"]
end