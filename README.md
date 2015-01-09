# Vert
Validate Ruby hashes and JSON data.

**The public API is not yet stable and methods are subject to change.**

##Rationale
Vert was created to eliminate repetitive boilerplate validation code for Ruby data.
Vert supports validations on hashes for internal data and JSON for external data. Vert will perform standard tests on your data but you can also declare additional tests that will check the format of your data.

Vert also eliminates boilerplate code for producing error messages by allowing you to declare application specific error messages for each failing test. 

## Installation

Install the gem

```ruby
gem install vert
```

Vert has been tested on MRI Ruby 1.9.3 and 2.1.

##Usage

###Hash validation

Use `validate` for validating hashes

```ruby
Vert.validate({ :key => "value"})
#=> nil
#returns nil when all tests pass
Vert.validate(0)
#=> "Not a hash."
#returns error message for failing test
```

`validate` performs the following default tests on hashes:

1. Validates that data is a hash
1. Validates that data is a non-empty hash

Use `validate?` instead when you need boolean outputs. You should use this
method when you don't require the error message.

```ruby
Vert.validate?({ :key => "value"})
#=> true
#returns true when all tests pass
Vert.validate?(0)
#=> false
#returns false when tests fail
```

Passing the `:key` hash with `validate` allows you to test for the presence of keys. In the case of keys which map to collections like hashes and arrays, you can also test that they are non-empty.

Given the following `person` hash

```ruby
> person = {:firstname=>"Daria", :lastname=>"James", :address=>{:street=>"Potter Lane", :town=>"Dereon"}}
```

We can create a `keys` hash which tests for the presence of keys. This way we are warned that the person hash does not contain an `:age` key.

```ruby
> keys = {:required_keys=>[:firstname, :lastname, :age], :hash_keys=>[:address]}
> Vert.validate(person, :keys => keys)
#=> "The data does not contain one or more required keys.
#    Missing keys:- age"
```

Say we've added `:age` to person to correct this mistake, we now get all tests passing for person.

```ruby
> person[:age] = 22
> Vert.validate(person, :keys => keys)
#=> nil
```

We can go further and make use of `validate?` to also test the nested `:address` hash.

```ruby
> nested_keys = {:required_keys=>[:street, :town, :country]}
>  if Vert.validate?(person, :keys => keys)
*   Vert.validate(person[:address], :keys => nested_keys)
* end
#=> "The data does not contain one or more required keys.
#    Missing keys:- country"
```

Using the `keys` hash, `validate` performs these additional tests:

1. Keys specified in the `:required_keys` array exists
1. Keys specified in the `:array_keys` array exists and is a non-empty array 
1. Keys specified in the `:hash_keys` array exists and is a non-empty hash

###JSON validation
You can use `validate_json` if your data is specified in JSON. 

```ruby
> json = "{\"key\" : \"value\"}\n"
> Vert.validate_json(json)
#=> nil
#returns nil when all tests pass
```

`validate_json` performs the following default tests on JSON data.

1. Validates that data is a string and non-empty
1. Validates that data is not empty JSON
1. Validates that data is not malformed JSON

You can test for a wider array of data integrity guarantees than `validate` if you specify an Avro schema to match against your JSON data. This will test both the presence and types of values in your JSON data.
hashes.

Given the JSON string `user_json` and the matchihng Avro schema, `user_schema` we can specify a `:schema` with `validate_json?`.

```ruby
> user_json = <<-json
 {"name": "Jacob Smith",
  "email": "jasmith@jsmith.com",
  "username": "jasmith"}
json
> user_schema = <<-json
 {"type": "record",
  "name": "User",
  "fields": [
    {
      "name": "name",
      "type": "string"
    },
    {
      "name": "email",
      "type": "string"
    },
    {
      "name": "username",
      "type": "string"
    }
	]}
json
	
> Vert.validate_json?(user_json, :schema => user_schema)
#=> true
# The JSON data matches the Avro schema provided.
```

According to the schema above, `name`, `email` and `username` are required JSON keys and they must all be strings. Since these criteria are met by `user_json` the `validate_json?` call returns true.

The Avro schema is relatively easy to construct and allows you to reject data that does not meet precise requirements. Read more about Avro's JSON schema specification [here](https://avro.apache.org/docs/current/spec.html).

###Custom error handling 

You may find yourself wanting more than the default error
messages that Vert provides, especially when you want to produce application
specific error messages. To make this process easy, you can specify
a custom error to be thrown for any of Vert's validation tests. This
way you can give your program helpful error messages wihtout
re-implementing any of Vert's validations.

```ruby
> user = {
# => {:name=>"Jacob Smith", :email=>"jasmith@jsmith.com"}
```

Given that the `user` hash also requires a `:username` key as well, we can throw a custom error when validating this hash.

```ruby
#Specify a :keys hash with the required keys
> user_keys = {:required_keys=>[:name, :email, :username]}

#Specify a :custom_errors hash with the custom error we would like
#to throw when a key is missing
> custom_errors = {:absent_key=>"User must have name, email and username."}

> Vert.validate(user, :keys => user_keys, :custom_errors => custom_errors)
#=> "User must have name, email and username.
#    Missing keys:- username"
```

The options hash throws the custom error provided instead of the
default :absent_key error as well as a list of the missing keys.

You can get the list of all error keys you can override this way using `get_error_keys`.

```ruby
> Vert.get_error_keys
#=>  {:not_a_hash=>"Not a hash.",
#     :empty=>"The hash is empty.",
#     :absent_key=>"The data does not contain one or more required keys.",
#     :array_type=>"The following key/s do not have Array type values.",
#     :hash_type=>"The following key/s do not have Hash type values.",
#     :array_empty=>"The following array key/s are empty.",
#     :hash_empty=>"The following hash key/s are empty.",
#     :not_a_string=>"Not a JSON string.",
#     :empty_json=>"The JSON string is empty.",
#     :empty_json_object=>"The JSON object is empty.",
#     :malformed_json=>"The JSON string is malformed",
#     :invalid_avro_schema=>"The avro schema is invalid",
#     :invalid_avro_datum=>"The JSON provided is not an instance of the schema."}
```

##Use as a mixin 

You can mixin the Vert methods directly instead of calling the methods on the gem.

```ruby
require 'vert'

class ClassThatExtendsVert
  extends Vert
end
```

---

Licensed under the [MIT Licence](http://opensource.org/licenses/MIT). See LICENSE.txt.
