require 'oj'
require 'avro'

module Vert

  extend self

  ValidationError = Class.new(StandardError)
  VerificationError = Class.new(StandardError)

  #error messages for hash
  NOT_A_HASH_ERROR = "Not a hash." 
  EMPTY_ERROR = "The hash is empty." 
  ABSENT_KEY_ERROR = "The data does not contain the following key/s"  

  #error messages for json
  EMPTY_JSON_ERROR = "The JSON string is empty."
  EMPTY_JSON_OBJECT_ERROR = "The JSON object is empty."
  MALFORMED_JSON_ERROR = "The JSON string is malformed."
  ABSENT_JSON_ERROR = "JSON keys absent."

  #error messages for avro
  INVALID_AVRO_SCHEMA_ERROR = "The avro schema is invalid."
  INVALID_AVRO_DATUM_ERROR = "The hash provided is not an instance of the schema:"
  
  TYPE_ENUM = {array_keys: Array, hash_keys: Hash}

  def validate(hash, keys = {}) 
    raise_when_not_hash(hash)
    raise_when_empty(hash) 
    unless keys.empty?
      raise_when_keys_absent(hash, keys, :value_keys) if keys[:value_keys]
      raise_when_keys_absent(hash, keys, :array_keys) if keys[:array_keys]
      raise_when_keys_do_not_match_type(hash, keys, :array_keys) if keys[:array_keys] 
      raise_when_keys_absent(hash, keys, :hash_keys) if keys[:hash_keys] 
      raise_when_keys_do_not_match_type(hash, keys, :hash_keys) if keys[:hash_keys] 
    end
  rescue ValidationError => exception 
    build_error_output(exception) 
  else
    nil
  end

  def raise_when_empty(hash) 
    raise ValidationError, EMPTY_ERROR if hash.empty? 
  end

  def raise_when_not_hash(hash) 
    raise ValidationError, NOT_A_HASH_ERROR unless hash.is_a?(Hash) 
  end

  def raise_when_keys_absent(hash, keys, key_type)
    missing_keys = get_missing_keys(hash, keys, key_type)
    raise ValidationError, build_missing_key_error(missing_keys) unless test_criteria_met?(missing_keys) 
  end

  def get_missing_keys(hash, keys, key_type)
    keys[key_type] - hash.keys
  end

  def build_missing_key_error(missing_keys_array)
    "#{ABSENT_KEY_ERROR} :- #{missing_keys_array*", "}"
  end

  def test_criteria_met?(key_array) 
    key_array.empty? 
  end

  def raise_when_keys_do_not_match_type(hash, keys, key_type)
    non_matched_type_keys = get_non_matched_type_keys(hash, keys, key_type)
  end
  
  def get_non_matched_type_keys(hash, keys, key_type)
    missing_keys = get_missing_keys(hash, keys, key_type)
    non_matched_type_keys = (keys[key_type] - missing_keys).find_all do
      |key| hash[key].is_a?(TYPE_ENUM[key_type]) == false
    end
    raise ValidationError, build_non_matched_type_keys_error(non_matched_type_keys, key_type) unless test_criteria_met?(non_matched_type_keys)
  end

  def build_non_matched_type_keys_error(non_matched_type_keys_array, key_type)
    "The following key/s do not have #{TYPE_ENUM[key_type]} type values :- #{non_matched_type_keys_array*", "}"
  end

  def build_error_output(custom_exception) 
    {errors: [{type: custom_exception.class.to_s, message: custom_exception.message}]}
  end

  def validate?(hash, keys = {})
    validate(hash, keys).nil? ? true : false 
  end

  def validate_json(json, keys = {})
    hash = parse_json(json)
  rescue ValidationError => exception
    build_error_output(exception)
  else
    validate(hash, keys)
  end

  def validate_json?(json, keys = {})
    validate_json(json, keys).nil? ? true : false 
  end

  def parse_json(json)
    hash = Oj.load(json)
    raise ValidationError, EMPTY_JSON_ERROR if hash.nil?
    raise ValidationError, EMPTY_JSON_OBJECT_ERROR if hash.empty?
  rescue Oj::ParseError => exception
    raise ValidationError, "#{MALFORMED_JSON_ERROR} #{exception.message.gsub( /\[.+\]/, "").rstrip}."
  else
    hash
  end

  def verify(data, schema)
    schema_object = parse_avro_schema(schema)
    raise VerificationError, INVALID_AVRO_DATUM_ERROR unless Avro::Schema.validate(schema_object, data)
  rescue VerificationError => exception
    build_error_output(exception)
  else
    nil
  end

  def parse_avro_schema(schema_string)
    schema = Avro::Schema.parse(schema_string)
  rescue Avro::SchemaParseError => exception
    raise VerificationError, "#{INVALID_AVRO_SCHEMA_ERROR} #{exception}"
  else
    schema
  end

  def verify?(data, schema)
    verify(data, schema).nil? ? true : false 
  end

end
