Gem::Specification.new do |s|
  s.name        = 'ruby-cleverdome'
  s.version     = '0.1.1'
  s.date        = '2014-04-16'
  s.summary     = "RubyCleverdome"
  s.description = "Ruby client to access CleverDome."
  s.authors     = ["Alex Gorbunov"]
  s.email       = 'sanyo.gorbunov@gmail.com'
  s.files       = ["lib/ruby-cleverdome.rb", "lib/ruby-cleverdome/multipart.rb"]
  s.homepage    =
    'https://github.com/SanyoGorbunov/ruby-cleverdome/'

  s.add_dependency 'savon', ['~> 2.0']
  s.add_dependency 'signed_xml'
  s.add_dependency 'nokogiri'
  s.add_dependency 'uuid'
  s.add_dependency 'mime-types'
  s.add_dependency 'base64'
end