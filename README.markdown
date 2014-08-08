# Vert

**Check the correctness of data**

Vert is a convenient library for verifying and validating data. Vert supports validation of keyed data in hash maps
and JSON. Vert supports verification of data types using Avro schemas only. Use Vert in your test suites 
or for data checks on inputs and outputs at system boundaries.

Use `validate` when you need to validate the 'format' of complicated hashes and
ensure that keys are present. While validate can check array types and
hash types you should use `verify` when you need stronger data
integrity guarantees. If your data is specified in JSON, `verify` can use
matching Avro schemas to enforce the correctness of typed data.

Vert wraps common data verfication and vaildation tests into two two high level
functions, `verify` and `validate`. These methods output an error hash
with descriptive errors, if you require boolean outputs you can use
the `verify?` and `validate?` methods instead.

`validate` performs the following checks on hash:

1. Is not a hash
1. Is empty
1. Is formatted correctly 

If `validate_json` is used checks will also be done for malformed JSON.
 
`verify` performs the following checks on JSON strings:
1. Is empty or an empty object
2. Is not an example of Avro schema. Note that an error will be thrown when the provided schema is invalid.

## Usage

You can use `validate` to ensure that the shape of your hash map or JSON
is correct.

Given the following hash map:

```ruby
outfit =
{:clothing=>
   [{:shoes=>
      {:brand=>"Nike", 
       :size=>9}, 
     :watch=> "Casio"
   }]}
```

You can check the shape of the entire hash map.

```ruby
if Vert.validate(outfit, {array_keys: [:clothing]})
    if Vert.validate(outfit[:clothing].first, {value_keys: [:watch], hash_keys: [:shoes]})
        Vert.validate(outfit[:clothing].first[:shoes], {value_keys: [:brand, :size]})
    end
end
=> nil
```

If your hash map should have a jewelry key. This call will produce an
error message.

```ruby
Vert.validate(outfit, {value_keys: [:jewelry]})
=>{:errors=>
  [{:type=>"Vert::ValidationError",
    :message=>"The hash does not contain the following key/s :- jewelry"}]}
```

Using `validate?` instead gives you a boolean which is useful
for runtime validation checks.

```ruby
Vert.validate?(outfit, {value_keys: [:jewelry]})
=> false
```

You can perform all the above validations with JSON data, just use `validate_json` with a JSON string.

If you have defined an Avro schema for the *outift* hash you can use `verify` instead. This will have the added benefit of checking that the *brand* and *watch* keys are always provided as Strings. 

```ruby
Vert.verify?(outfit, outfit_avro_schema)
=> true
```

Read more about Avro's JSON schema specification [here](https://avro.apache.org/docs/1.7.6/spec.html#schemas).
