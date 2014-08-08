# Vert

**keep your data clean**

Vert is a library for verifying and validating data. Vert wraps common
data verfication and vaildation tests into two two high level
functions, `verify` and `validate`. These methods output an error hash
with descriptive errors, if you require boolean outputs you can use
the `verify?` and `validate?` methods instead.

Use `validate` when you need to validate the shape of your hashes and
ensure that keys are present. While validate can check array types and
hash types you should use `verify` when you need stronger data
integrity guarantees. If your data is specified in JSON, Vert can use
Avro schemas to enforce the correctness of typed data.

Vert supports validation of keyed data in hash maps
and JSON. Vert supports verification of data types using Avro schemas only.

All JSON functions have `_json` at the end. 

`validate` performs the following checks:

1. data is a hash
1. data is not empty
1. data is not malformed
1. data is shaped correctly 

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
