#Changes between 0.2.1 and 0.3.0

##Breaking changes.
- The `:keys` array for testing required keys has been changed from `:value_keys` to `:required_keys`.

```ruby
> person = {:firstname => "Daria", :lastname => "James"}
> required_keys = {:required_keys => [:firstname, :lastname]}
> Vert.validate?(person, :keys => required_keys)
#=> true
```

##Minor changes
- Error message for `:absent_key_error` has been tidied up.
- Avro 1.7.7 required as 1.7.5 has issues on Ruby 2.0 and up	
	
