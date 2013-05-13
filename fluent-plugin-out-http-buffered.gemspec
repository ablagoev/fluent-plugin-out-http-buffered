# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'fluent-plugin-out-http-buffered'
  s.version     = File.read("VERSION").strip
  s.date        = '2013-05-13'
  s.summary     = "Fluentd http buffered output plugin"
  s.description = "Send fluent buffered logs to an http endpoint"
  s.authors     = ["Alexander Blagoev"]
  s.email       = 'alexander.i.blagoev@gmail.com'
  s.homepage    =
    'http://github.com/ablagoev/fluent-plugin-out-http-buffered'

  s.files       = [
    "lib/fluent/plugin/out_http_buffered.rb",
    "Gemfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "fluent-plugin-out-http-buffered.gemspec",
    "test/helper.rb",
    "test/fluent/plugin/test_out_http_buffered.rb",
  ]

  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.licenses = ["MIT"]

  s.require_paths = ['lib']

  s.add_dependency "fluentd", "~> 0.10.0"
  s.add_development_dependency "rake", ">= 0.9.2"
  s.add_development_dependency "rspec-mocks", ">= 2.13.0"
  s.add_development_dependency "bundler", ">= 1.3.4"
end