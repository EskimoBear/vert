require 'oj'
require 'avro'

module Vert

  extend self

  InputError = Class.new(StandardError)
  ValidationError = Class.new(StandardError)

  #error messages for hash validation
  NOT_A_HASH_ERROR = "Not a hash." 
  NOT_A_HASH_ERROR_KEY = :not_a_hash

  EMPTY_ERROR = "The hash is empty." 
  EMPTY_ERROR_KEY = :empty

  ABSENT_KEY_ERROR = "The data does not contain one or more required keys."  
  ABSENT_KEY_ERROR_KEY = :absent_key
 
  ARRAY_TYPE_ERROR = "The following key/s do not have Array type values." 
  ARRAY_TYPE_ERROR_KEY = :array_type

  HASH_TYPE_ERROR = "The following key/s do not have Hash type values." 
  HASH_TYPE_ERROR_KEY = :hash_type

  ARRAY_EMPTY_ERROR = "The following array key/s are empty."
  ARRAY_EMPTY_ERROR_KEY = :array_empty

  HASH_EMPTY_ERROR = "The following hash key/s are empty."
  HASH_EMPTY_ERROR_KEY = :hash_empty

  #error messages for JSON validation
  NOT_A_STRING_ERROR = "Not a JSON string."
  NOT_A_STRING_ERROR_KEY = :not_a_string

  EMPTY_JSON_ERROR = "The JSON string is empty."
  EMPTY_JSON_ERROR_KEY = :empty_json

  EMPTY_JSON_OBJECT_ERROR = "The JSON object is empty."
  EMPTY_JSON_OBJECT_ERROR_KEY = :empty_json_object

  MALFORMED_JSON_ERROR = "The JSON string is malformed"
  MALFORMED_JSON_ERROR_KEY = :malformed_json

  #error messages for avro verification
  INVALID_AVRO_SCHEMA_ERROR = "The avro schema is invalid"
  INVALID_AVRO_SCHEMA_ERROR_KEY = :invalid_avro_schema

  INVALID_AVRO_DATUM_ERROR = "The JSON provided is not an instance of the schema."
  INVALID_AVRO_DATUM_ERROR_KEY = :invalid_avro_datum

  #Enums 
  TYPE_ENUM = {array_keys: Array, hash_keys: Hash}
  OPTIONS_HASH_ENUM = [:keys, :custom_errors]
  OPTIONS_JSON_HASH_ENUM = [:schema, :custom_errors]
  KEYS_ENUM = [:required_keys, :array_keys, :hash_keys]
  ERROR_KEY_ENUM = {
    NOT_A_HASH_ERROR_KEY => NOT_A_HASH_ERROR,
    EMPTY_ERROR_KEY => EMPTY_ERROR,
    ABSENT_KEY_ERROR_KEY =>  ABSENT_KEY_ERROR,
    ARRAY_TYPE_ERROR_KEY =>  ARRAY_TYPE_ERROR,
    HASH_TYPE_ERROR_KEY => HASH_TYPE_ERROR,
    ARRAY_EMPTY_ERROR_KEY => ARRAY_EMPTY_ERROR,
    HASH_EMPTY_ERROR_KEY => HASH_EMPTY_ERROR,
    NOT_A_STRING_ERROR_KEY => NOT_A_STRING_ERROR,
    EMPTY_JSON_ERROR_KEY => EMPTY_JSON_ERROR,
    EMPTY_JSON_OBJECT_ERROR_KEY => EMPTY_JSON_OBJECT_ERROR,
    MALFORMED_JSON_ERROR_KEY => MALFORMED_JSON_ERROR,
    INVALID_AVRO_SCHEMA_ERROR_KEY => INVALID_AVRO_SCHEMA_ERROR,
    INVALID_AVRO_DATUM_ERROR_KEY => INVALID_AVRO_DATUM_ERROR
  }

  #input validation
  OPTIONS_HASH_EMPTY = "The options hash must contain keys"
  OPTIONS_NOT_A_HASH = "The options parameter must be a hash"
  OPTIONS_HASH_FORMAT = "{:keys => {}, :custom_errors => {}}"
  OPTIONS_JSON_HASH_FORMAT = "{:schema => \"avro shcema\", :custom_errors => {}}"
  OPTIONS_HASH_MISSING_VALID_KEYS = "The options hash contains no valid keys. The valid symbol keys are - "
  KEYS_HASH_MISSING_VALID_KEYS = "The options hash contains no valid keys for the :keys hash. The valid symbol keys are - "
  CUSTOM_ERRORS_HASH_MISSING_VALID_KEYS = "The options hash contains no valid keys for the :custom_errors hash. The valid symbol keys are - "
  SCHEMA_NOT_A_STRING = "The options hash contains a :schema value which is not a string."
  SCHEMA_NOT_JSON = "The options hash contains a :schema value which is not a JSON string"

  def validate(hash, options = nil) 
    unless options.nil?
      check_options_format(options, OPTIONS_HASH_FORMAT)
      check_options(options)
    end
    test_validations(hash, options)
  rescue InputError => exception
    build_error_output(exception) 
  end

  def validate?(hash, options = nil)
    check_options(options) unless options.nil?
    test_validations(hash, options).nil? ? true : false 
  rescue InputError => exception
    false
  end

  def validate_json?(json, options = nil)
    check_json_options(options) unless options.nil?
    validate_json(json, options).nil? ? true : false 
  rescue InputError => exception
    false
  end

  def validate_json(json, options = nil)
    unless options.nil?
      check_options_format(options, OPTIONS_JSON_HASH_FORMAT)
      check_json_options(options) 
    end
    test_validations_json(json, options)
  rescue InputError => exception
    build_error_output(exception)
  end

  def get_error_keys
    pp ERROR_KEY_ENUM
  end

  private

  def check_options(options)
    raise_when_all_keys_missing(options, OPTIONS_HASH_MISSING_VALID_KEYS, OPTIONS_HASH_ENUM)
    if options.keys.include?(:keys)
      raise_when_all_keys_missing(options[:keys], KEYS_HASH_MISSING_VALID_KEYS, KEYS_ENUM)
    end
  end  

  def raise_when_all_keys_missing(hash, message, key_enum_array)
    test_result = any_keys_present?(hash, key_enum_array)
    raise InputError, "#{message}#{key_enum_array*", "}" unless test_result
  end

  def any_keys_present?(hash, key_array)
    test_result = key_array.inject(false) do |memo, entry|
      memo || hash.keys.include?(entry)
    end
  end

  def check_options_format(options, options_format) 
    raise InputError, "#{OPTIONS_NOT_A_HASH}. The options hash has the following format:- #{options_format}" unless options.is_a?(Hash)
    raise InputError, OPTIONS_HASH_EMPTY if options.empty?
    if options.keys.include?(:custom_errors)
      raise_when_all_keys_missing(options[:custom_errors], CUSTOM_ERRORS_HASH_MISSING_VALID_KEYS, ERROR_KEY_ENUM.keys)
    end
  end

  def test_validations(hash, options)
    test_for_default_hash_errors(hash, options)
    if options_key_types_present?(options, :required_keys)
      raise_when_keys_absent(hash, options, :required_keys) 
    elsif options_key_types_present?(options, :array_keys)
      test_for_array_key_errors(hash, options)
    elsif options_key_types_present?(options, :hash_keys)
      test_for_hash_key_errors(hash, options)
    end 
  rescue ValidationError => exception 
    build_error_output(exception) 
  else
    nil
  end

  def check_json_options(options)
    raise_when_all_keys_missing(options, OPTIONS_HASH_MISSING_VALID_KEYS, OPTIONS_JSON_HASH_ENUM)
    if options.keys.include?(:schema)
      test_options = {custom_errors: {not_a_string: SCHEMA_NOT_A_STRING, malformed_json: SCHEMA_NOT_JSON}}
      unless Vert.validate_json?(options[:schema], test_options)
        test =  Vert.validate_json(options[:schema], test_options)
        raise InputError, test if test.include?(SCHEMA_NOT_JSON)
        raise InputError, test if test.include?(SCHEMA_NOT_A_STRING)  
      end
    end
  end

  def test_validations_json(json, options)
    test_for_default_json_errors(json, options)
    if options_schema_present?(options)
      validate_with_avro(json, options) 
    end
  rescue ValidationError => exception
    build_error_output(exception)
  else
    nil
  end

  def test_for_default_hash_errors(hash, options)
    raise_when_not_hash(hash, options)
    raise_when_empty(hash, options)
  end 

  def raise_when_not_hash(hash, options) 
    raise_custom_error(hash, options, NOT_A_HASH_ERROR_KEY) {|hash| !hash.is_a?(Hash)}
  end

  def raise_custom_error(data, options, error_key)
    test = yield data
    message = options_errors_present?(options, error_key) ? get_options_custom_error(options, error_key) : ERROR_KEY_ENUM[error_key]
    raise ValidationError, message if test
  end

  def options_errors_present?(options, error_key)
    if options.nil?
      false
    elsif options.include?(:custom_errors)
      options[:custom_errors].include?(error_key) ? true : false
    else
      false
    end
  end

  def get_options_custom_error(options, error_key)
    options[:custom_errors][error_key]
  end

  def raise_when_empty(hash, options) 
    raise_custom_error(hash, options, EMPTY_ERROR_KEY) {|hash| hash.empty?}
  end

  def options_key_types_present?(options, key_type)
    if options.nil?
      false
    elsif options.include?(:keys)
      options[:keys].include?(key_type) ? true : false
    else
      false
    end
  end

  def test_for_array_key_errors(hash, options)
    test_for_collection_key_errors(hash, options, :array_keys)
  end
  
  def test_for_hash_key_errors(hash, options)
    test_for_collection_key_errors(hash, options, :hash_keys)
  end

  def test_for_collection_key_errors(hash, options, key_type)
    raise_when_keys_absent(hash, options, key_type)
    raise_when_keys_do_not_match_type(hash, options, key_type) 
    raise_when_collection_keys_empty(hash, options, key_type) 
  end

  def raise_when_keys_absent(hash, options, key_type)
    missing_keys = get_missing_keys(hash, options, key_type)
    raise_error(nil, options, build_missing_key_error(options, missing_keys)) {!missing_keys.empty?}
  end

  def get_missing_keys(hash, options, key_type)
    get_options_keys_array(options, key_type) - hash.keys
  end

  def raise_error(data, options, message)
    test = yield data
    raise ValidationError, message if test
  end

  def build_missing_key_error(options, missing_keys_array)
    "#{build_error_message(options, ABSENT_KEY_ERROR_KEY)}\nMissing key/s: #{missing_keys_array*", "}"
  end

  def build_error_message(options, error_key)
    options_errors_present?(options, error_key) ? get_options_custom_error(options, error_key) : ERROR_KEY_ENUM[error_key]
  end

   def test_criteria_met?(key_array) 
    key_array.empty? 
  end

  def raise_when_keys_do_not_match_type(hash, options, key_type)
    non_matched_type_keys = get_non_matched_type_keys(hash, options, key_type)
    raise_error(nil, options, build_non_matched_type_error_message(options, non_matched_type_keys, key_type)) {!test_criteria_met?(non_matched_type_keys)}  
  end
  
  def get_non_matched_type_keys(hash, options, key_type)
    missing_keys = get_missing_keys(hash, options, key_type)
    non_matched_type_keys = (get_options_keys_array(options, key_type) - missing_keys).find_all do
      |key| hash[key].is_a?(TYPE_ENUM[key_type]) == false
    end
  end

  def get_options_keys_array(options, key_type)
    options[:keys][key_type] 
  end

  def build_non_matched_type_error_message(options, non_matched_type_keys_array, key_type)
    case key_type
    when :array_keys
      "#{build_error_message(options, ARRAY_TYPE_ERROR_KEY)} Not Array type keys:- #{non_matched_type_keys_array*","}"
    when :hash_keys
      "#{build_error_message(options, HASH_TYPE_ERROR_KEY)} Not Hash type keys:- #{non_matched_type_keys_array*","}"
    end
  end

  def raise_when_collection_keys_empty(hash, options, key_type)
    if get_non_matched_type_keys(hash, options, key_type).empty?
      empty_collection_keys = get_empty_collection_keys(hash, options, key_type)
      raise_error(nil, options, build_empty_collection_error_message(options, empty_collection_keys, key_type)) {!test_criteria_met?(empty_collection_keys)}
    end
  end

  def get_empty_collection_keys(hash, options, key_type)
    get_options_keys_array(options, key_type).find_all do |item|
      hash[item].empty?
    end
  end

  def build_empty_collection_error_message(options, empty_collection_keys_array, key_type)
    case key_type
    when :array_keys
      "#{build_error_message(options, ARRAY_EMPTY_ERROR_KEY)} Empty array keys:- #{empty_collection_keys_array*","}"
    when :hash_keys
      "#{build_error_message(options, HASH_EMPTY_ERROR_KEY)} Empty hash keys:- #{empty_collection_keys_array*","}"
    end
  end

  def build_error_output(custom_exception) 
    custom_exception.message
  end

  def test_for_default_json_errors(json, options)
    raise_when_not_string(json, options)
    hash = try_parse_json(json, options)
  end

  def options_schema_present?(options)
    if options.nil?
      false
    elsif options.include?(:schema) 
      true
    else
      false
    end
  end

  def get_options_schema(options)
    options[:schema]
  end  

  def raise_when_not_string(json, options)
    raise_custom_error(json, options, NOT_A_STRING_ERROR_KEY){|json| !json.is_a?(String)}
  end

  def try_parse_json(json, options)
    hash = Oj.load(json)
    raise_custom_error(hash, options, EMPTY_JSON_ERROR_KEY){|hash| hash.nil?}
    raise_custom_error(hash, options, EMPTY_JSON_OBJECT_ERROR_KEY){|hash| hash.empty?}
  rescue Oj::ParseError => exception
    detail = "#{exception.message.gsub( /\[.+\]/, "").rstrip}."
    raise ValidationError, "#{build_error_message(options, MALFORMED_JSON_ERROR_KEY)}, #{detail}"
  else
    hash
  end

  def validate_with_avro(json, options)
    schema_object = parse_avro_schema(options)
    message = build_error_message(options, INVALID_AVRO_DATUM_ERROR_KEY)
    raise_error(json, options, message){|json| !Avro::Schema.validate(schema_object, Oj.load(json))}
  end

  def parse_avro_schema(options)
    schema = Avro::Schema.parse(get_options_schema(options))
  rescue Avro::SchemaParseError => exception
    raise ValidationError, "#{build_error_message(options, INVALID_AVRO_SCHEMA_ERROR_KEY)}. #{exception.to_s}"
  else
    schema
  end

end
