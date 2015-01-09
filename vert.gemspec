Gem::Specification.new do |s|
  s.name   = 'vert'
  s.version = '0.3.0'
  s.date = '2015-01-09'
  s.summary = "Keep your data clean without the boilerplate"
  s.description = "Validate hashes and JSON data and output custom errors"     
  
  s.authors = ["Eskimo Bear"]
  s.email = 'dev@eskimobear.com'
  s.homepage = 'https://github.com/EskimoBear/vert/'
  
  s.files = ["lib/vert.rb"]     
  s.platform = Gem::Platform::RUBY
  s.require_paths =["lib"]
  s.license = 'MIT'      
  
  s.add_dependency 'avro', '~>1.7.7'
  s.add_dependency 'oj'
end                    
