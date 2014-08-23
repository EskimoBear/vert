Gem::Specification.new do |s|
  s.name   = 'vert'
  s.version = '0.2.1'
  s.date = '2014-08-23'
  s.summary = "Keep your data clean"
  s.description = "Vert is a library for verifying and validating data."     
  
  s.authors = ["Eskimo Bear"]
  s.email = 'dev@eskimobear.com'
  s.homepage = 'https://github.com/EskimoBear/Vert/'
  
  s.files = ["lib/vert.rb"]     
  s.platform = Gem::Platform::RUBY
  s.require_paths =["lib"]
  s.license = 'MIT'      
  
  s.add_dependency 'avro', '~>1.7.5'
  s.add_dependency 'oj', '~>2.10.2'
end                    
