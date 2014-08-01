# Vert

**keep your data clean**

Vert is a library for verifying and validating data. Vert wraps common
data verfication and vaildation tests into two two high level
functions, *verify* and *validate*. Use *validate* when you need to
validate teh shape of your hashes and ensure that keys are present.
Use `verify` when you need stronger data integrity guarantees. If your
data is specified in JSON, Vert can use Avro schemas to enforce the
correctness of typed data.

Vert supports validation of keyed data in hash maps
and JSON. Vert supports verification of data types using Avro schemas only.

All JSON functions have *_json* at the end. 

Validate performs the following checks:

1. data is not empty
1. data is not malformed
1. data is shaped correctly 

You can use validate to ensure that the shape of your hash map or JSON
is correct.

Given the following hash map:

```ruby
h =
{:clothing=>
   [{:shoes=>
      {:brand=>"Nike", 
       :size=>9}, 
     :watch=> "Casio"
   ]}
```

You can check the shape of the entire hash map.

```ruby
if Vert.validate(h, {array_keys: [:clothing]})
    if Vert.validate(h[:data].first, {value_keys: [:watch], hash_keys: [:shoes]})
        Vert.validate(h[:dataunits].first[:shoes], {value_keys: [:brand, :size]})
    end
end
=> true
```

If your hash map is also supposed to have a jewelry hash. This call
will fail

```ruby
Vert.validate(h, {array_keys: [:jewelry]})
=> {:errors=>[{:type=>"Vert::ValidationError", :message=>"The hash map either does not contain key/s provided or the keys are present but do not have array as its value. {missing_keys: [:jewelry]}"}]}
```
