# Vert

**Test the correctness of data**

Vert is a convenient library for validating data. Vert supports
validation of keyed data in hash maps and validation of JSON using
Avro schemas. Use Vert in your test suites, or for data checks on
inputs and outputs at system boundaries. Vert provides specific
facilities for handling common data input exceptions and helps you avoid
rewriting boilerplate error handling code. 

Use `validate` when you need to validate the 'format' of complicated
hashes and ensure that keys are present. You can use `validate_json`
if your data is specified in JSON. You can test for stronger data integrity guarantees than `validate` if you specify a matching Avro schema.

Vert wraps common data verfication and vaildation tests into two
high level functions, `validate` and `validate_json`. These methods
output an error hash with descriptive errors, if you require boolean
outputs you can use the `validate?` and `validate_json?` methods instead.

`validate` performs the following default tests on hashes:

1. Is not a hash
1. Is not empty

Passing a `key` hash with `validate` allows you to test for the
existence of keys. In the case of keys which map to values of collections
like hash keys and array keys, `validate` also tests that these
collections are non-empty. You can perform the following tests:

1. Specified key/s exists
1. Specified key/s with non-empty array values exists
1. Specified key/s with non-empty hash values exists

`validate_json` performs the following default tests on JSON string:

1. Is a string
1. Is not an empty string
1. Is not an empty JSON object
1. Is not malformed JSON
 
Passing an Avro JSON schema with `validate_json` performs the following tests on JSON strings:

1. Is not an example of Avro schema. Note that an error will be thrown when the provided schema is invalid.

## Usage

You can use `validate` to ensure that the format of your hash is correct.

Given the following hash:

```ruby
outfit =
{:clothing=>
   [{:shoes=>
      {:brand=>"Nike", 
       :size=>9}, 
     :watch=> "Casio"
   }]}
```

You can test the format of the entire hash, by testing each of the nested
hashes and arrays.

```ruby

if Vert.validate(outfit, {array_keys: [:clothing]})
    if Vert.validate(outfit[:clothing].first, {value_keys: [:watch], hash_keys: [:shoes]})
        Vert.validate(outfit[:clothing].first[:shoes], {value_keys: [:brand, :size]})
    end
end
=> nil
```

If your *outfit* hash was expected to also contain a jewelry key, the
following call will produce an error message:

```ruby
Vert.validate(outfit, {value_keys: [:jewelry]})
=>{:errors=>
  [{:type=>"Vert::ValidationError",
    :message=>"The hash does not contain the following key/s :- jewelry"}]}
```

Using `validate?` instead gives you a boolean which is useful
for runtime validation tests.

```ruby
Vert.validate?(outfit, {value_keys: [:jewelry]})
=> false
```

You can perform all the above validations with JSON data, just use
`validate_json` with a JSON represenation of *outfit* and a matching
JSON Avro schema. This will test all your values, not just arrays and
hashes.

Given the JSON object *outfit_json*.

```JSON
{"clothing":
   [{"shoes":
      {"brand": "Nike", 
       "size": "nine"}, 
     "watch": "Casio"
   }]}
```

and the matchihng Avro schema, *outfit_avro_schema* (Avro schemas are plain JSON).

```JSON
{
  "type": "record",
  "name": "Outfit",
  "fields": [
    {
      "name": "clothing",
      "type": {
        "type": "array",
        "items": {
          "type": "record",
          "name": "clothing_item",
          "fields": [
            {
              "name": "shoes",
              "type": {
                "type": "record",
                "name": "shoe_item",
                "fields": [
                  {
                    "name": "brand",
                    "type": "string"
                  },
                  {
                    "name": "size",
                    "type": "int"
                  }
                ]
              }
            },
            {
              "name": "watch",
              "type": "string"
            }
          ]
        }
      }
    }
  ]
}
```

The `validate_json?` call returns false.

```ruby
Vert.validate_json?(outfit_json, outfit_avro_schema)
=> false
```
According to the schema the size value of the items in the shoe array
must be an integer so the validate_json? call returns false. While the
Avro schema above looks complicated, it is relatively easy to
construct and it allows you to reject data that does not meet your
requirements. Read more about Avro's JSON schema specification [here](https://avro.apache.org/docs/1.7.6/spec.html#schemas).

### Custom Error Handling 

You can also apply custom errors 

---

Licensed under the [MIT Licence](http://opensource.org/licenses/MIT). See LICENSE.txt.
