require 'minitest/autorun'
require 'minitest/pride'
require 'pp'

require_relative '../lib/vert'

class VertTest < MiniTest::Unit::TestCase

  def setup
    setup_hash_data
    setup_json_data
    setup_avro_data
    setup_custom_errors
    setup_validate_options_errors
    setup_validate_json_options_errors
  end 

  def setup_hash_data
    @valid_data = {value_key_1: "valid", value_key_2: "data", array_key_1: ["a", "b"], array_key_2: 5, empty_array_key: [], hash_key_1: {a: 1, b: 2}, hash_key_2: [4], empty_hash_key: {}}
    @empty_data = {}
    @invalid_data = []
  end
  
  def setup_json_data
    @empty_json = " "
    @empty_json_object = "{}"
    @malformed_json = "{"
    @valid_json = <<-JSON
    {"username": "Krakoa", "age": 9} 
    JSON

    @invalid_json = <<-JSON
    {"user": 9389, "age": "nine"}
    JSON
  end

  def setup_avro_data
    @invalid_schema = "{}"
    @schema = <<-JSON
    { "type": "record",
      "name": "User",
      "fields": [
        {"name": "username", "type":"string"},
        {"name": "age", "type": "int"}
    ]}
    JSON
  end
  
  def setup_custom_errors
    @custom_empty_error = "It's empty"
    @custom_not_a_hash_error = "It's not a hash"
    @custom_absent_key_error = "Key not present"
    @custom_array_type_error = "Key is not an array"
    @custom_hash_type_error = "Key is not a hash"
    @custom_array_empty_error = "Array value is empty"
    @custom_hash_empty_error = "Hash value is empty"
    @custom_not_a_string_error = "Expected JSON is not a string"
    @custom_empty_json_error = "Not a string"
    @custom_empty_json_object_error = "Empty JSON object"
    @custom_malformed_json_error = "malformed JSON"
    @custom_invalid_avro_schema_error = "invalid schema"
    @custom_invalid_avro_datum_error = "invalid datum"
  end

  def setup_validate_options_errors
    @valid_options = {keys: {value_keys: [:value_key_1, :value_key_2]}, custom_errors: {empty: "It's empty"}}
    @invalid_options_keys_hash = {keys: {val_keys: [3], arr_keys: [4], has_keys: [5]}}
    @invalid_options_custom_errors_hash = {keys: {value_keys: [3, 4]}, custom_errors: {thisisempty: "It's empty"}}
    @invalid_options = {key: {}, errors: {}}
  end

  def setup_validate_json_options_errors
    @valid_json_options = {schema: @schema, custom_errors: {empty_json: "That json is empty"}}
    @invalid_json_options_string_schema = {schema: [], custom_errors: {empty_json: "That json is empty"}}
    @invalid_json_options_json_schema = {schema: "{\"a\"}", custom_errors: {empty_json: "That json is empty"}}
    @invalid_json_options_errors_schema = {schema: @schema, custom_errors: {no_a_key: "This shouldn't be here"}}
    @invalid_json_options = {scheme: {}, errors: {}}
  end
  
  def error_message_helper(result)
    result
  end

  def test_input_options_hash_errors
    options_hash_test = Vert.validate(@valid_data, [])
    assert_match(/#{Vert::OPTIONS_NOT_A_HASH}/, options_hash_test,
                 "Expects that a hash is passed for the options parameter")
    options_hash_empty_test = Vert.validate(@valid_data, {})
    assert_match(/#{Vert::OPTIONS_HASH_EMPTY}/, options_hash_empty_test,
                 "Expects that the options hash contains keys if present")
  end

  def test_validate_options_errors
    success_test = Vert.validate?(@valid_data, @valid_options) 
    assert(success_test, "Expects that options hash is valid")
    fail_key_test = Vert.validate(@valid_data, @invalid_options_keys_hash)
    assert_match(/#{Vert::KEYS_HASH_MISSING_VALID_KEYS}/, fail_key_test, "Expects that error thrown when keys hash in options hash is missing valid keys")
    fail_error_test = Vert.validate(@valid_data, @invalid_options_custom_errors_hash)
    assert_match(/#{Vert::CUSTOM_ERRORS_HASH_MISSING_VALID_KEYS}/, fail_error_test,"Expects that error thrown when custom errors hash in option hash is missing valid keys")
    fail_invalid_test = Vert.validate(@valid_data, @invalid_options)
    assert_match(/#{Vert::OPTIONS_HASH_MISSING_VALID_KEYS}/, fail_invalid_test, "Expects that error thrown when both keys and custom_errors missing from options hash")
  end

  def test_validate_successful
    assert(Vert.validate(@valid_data).nil?, "Expects that the data structures passes all validation tests")
  end

  def test_validate?
    assert(Vert.validate?(@valid_data), "Expects true when a data structure passess all validation tests")
    refute(Vert.validate?(@invalid_data), "Expects false when a data structure fails validation tests")
  end

  def test_validate_throws_error_when_not_hash
    result = Vert.validate(@invalid_data)
    assert_match(error_message_helper(result), Vert::NOT_A_HASH_ERROR, "Expects that the data structure is a hash")
  end

  def test_validate_throws_custom_error_when_not_hash
    result = Vert.validate(@invalid_data, {custom_errors: {not_a_hash: @custom_not_a_hash_error }})
    assert_equal(@custom_not_a_hash_error, error_message_helper(result), "Expects that custom error message for not a hash error to be thrown")
  end

  def test_validate_throws_error_when_empty
    result = Vert.validate(@empty_data)
    assert_equal(error_message_helper(result), Vert::EMPTY_ERROR, "Expects that an error is thrown when the hash is empty")
  end

  def test_validate_throws_custom_error_when_empty
    result = Vert.validate(@empty_data, {custom_errors: {empty: @custom_empty_error}})
    assert_equal(@custom_empty_error, error_message_helper(result), "Expects custom error message for empty error to be thrown")
  end

  def test_validate_throws_error_when_value_keys_not_found
    result = Vert.validate(@valid_data, {keys: {value_keys: [:value_key_1, :absent_value_key]}})
    assert_match( /#{Vert::ABSENT_KEY_ERROR}/,error_message_helper(result), "Expects that the specified value keys exist in the hash")
  end

  def test_validate_throws_custom_error_when_value_keys_not_found
    result = Vert.validate(@valid_data, {keys: {value_keys: [:value_key_1, :absent_value_key]}, custom_errors: {absent_key: @custom_absent_key_error}})
    assert_match( /#{@custom_absent_key_error}/,error_message_helper(result), "Expects that a custom error is given when the specified value keys do not exist")
  end

  def test_validate_throws_error_when_array_keys_not_found
    result = Vert.validate(@valid_data, {keys: {array_keys: [:array_key_1, :array_key_2, :absent_array_key]}})
    assert_match( /#{Vert::ABSENT_KEY_ERROR}/, error_message_helper(result), "Expects that the specified array keys exist in the hash")
  end

  def test_validate_throws_custom_error_when_array_keys_not_found
    result = Vert.validate(@valid_data, {keys: {array_keys: [:array_key_1, :array_key_2, :absent_array_key]}, custom_errors: {absent_key: @custom_absent_key_error}})
    assert_match( /#{@custom_absent_key_error}/,error_message_helper(result), "Expects that a custom error is given when the specified array keys do not exist")
  end

  def test_validate_throws_error_when_hash_keys_not_found
    result = Vert.validate(@valid_data, {keys: {hash_keys: [:hash_key_1, :hash_key_2, :absent_hash_key]}})
    assert_match(/#{Vert::ABSENT_KEY_ERROR}/, error_message_helper(result), "Expects that some specified hash keys are absent from the hash")
  end

  def test_validate_throws_custom_error_when_hash_keys_not_found
    result = Vert.validate(@valid_data, {keys: {hash_keys: [:hash_key_1, :hash_key_2, :absent_hash_key]}, custom_errors: {absent_key: @custom_absent_key_error}})
    assert_match(/#{@custom_absent_key_error}/,error_message_helper(result), "Expects that a custom error is given when the specified hash keys do not exist")
  end

  def test_validate_throws_error_when_array_kays_are_not_arrays
    result = Vert.validate(@valid_data, {keys: {array_keys: [:array_key_1, :array_key_2]}})
    assert_match(/#{Vert::ARRAY_TYPE_ERROR}/, error_message_helper(result), "Expects that the specified array keys are arrays") 
  end

  def test_validate_throws_custom_error_when_array_keys_are_not_arrays
    result = Vert.validate(@valid_data, {keys: {array_keys: [:array_key_1, :array_key_2]}, custom_errors: {array_type: @custom_array_type_error}})
    assert_match(/#{@custom_array_type_error}/, error_message_helper(result), "Expects that a custom error is given when the specified array is not an array")
  end

  def test_validate_throws_error_when_hash_keys_are_not_hashes
    result = Vert.validate(@valid_data, {keys: {hash_keys: [:hash_key_1, :hash_key_2]}})
    assert_match(/#{Vert::HASH_TYPE_ERROR}/, error_message_helper(result), "Expects that the specified hash keys are hashes")  
  end

  def test_validate_throws_custom_error_when_hash_keys_are_not_hashes
    result = Vert.validate(@valid_data, {keys: {hash_keys: [:hash_key_1, :hash_key_2]}, custom_errors: {hash_type: @custom_hash_type_error}})
    assert_match(/#{@custom_hash_type_error}/, error_message_helper(result), "Expects that a custom error is given when the specified hash key is not a hash")
  end

  def test_validate_throws_error_when_array_keys_are_empty
    result = Vert.validate(@valid_data, {keys: {array_keys: [:array_key_1, :empty_array_key]}})
    assert_match(/#{Vert::ARRAY_EMPTY_ERROR}/, error_message_helper(result), "Expects that an error is returned when array keys are empty")
  end

  def test_validate_throws_custom_error_when_array_keys_are_empty
    result = Vert.validate(@valid_data, {keys: {array_keys: [:array_key_1, :empty_array_key]}, custom_errors: {array_empty: @custom_array_empty_error}})
    assert_match(/#{@custom_array_empty_error}/, error_message_helper(result), "Expects that a custom error is returned when the specified array keys are not empty")
  end

  def test_validate_throws_error_when_hash_keys_are_empty
    result = Vert.validate(@valid_data, {keys: {hash_keys: [:hash_key_1, :empty_hash_key]}})
    assert_match(/#{Vert::HASH_EMPTY_ERROR}/, error_message_helper(result), "Expects that the specified hash keys are not empty")
  end

  def test_validate_throws_custom_error_when_hash_keys_are_empty
    result = Vert.validate(@valid_data, {keys: {hash_keys: [:hash_key_1, :empty_hash_key]}, custom_errors: {hash_empty: @custom_hash_empty_error}})
    assert_match(/#{@custom_hash_empty_error}/, error_message_helper(result), "Expects that a custom error is returned when the specified array keys are not empty")
  end

  def test_validate_json_options
    success_test = Vert.validate_json?(@valid_json, @valid_json_options)
    assert(success_test, "Expects that the options hash has both valid keys")
    fail_schema_string_test = Vert.validate_json(@valid_json, @invalid_json_options_string_schema)
    assert_equal(Vert::SCHEMA_NOT_A_STRING, fail_schema_string_test, 
                 "Expects that the schema value is a string when present")
    fail_schema_not_json_test = Vert.validate_json(@valid_json, @invalid_json_options_json_schema)
    assert_match(/#{Vert::SCHEMA_NOT_JSON}/, fail_schema_not_json_test,
                 "Expects that the schema value is a JSON string when present")
    fail_custom_errors_test = Vert.validate_json(@valid_json, @invalid_json_options_errors_schema)
    assert_match(/#{Vert::CUSTOM_ERRORS_HASH_MISSING_VALID_KEYS}/, fail_custom_errors_test,
                 "Expects that the custom errors hash has valid keys")    
    fail_options_test = Vert.validate_json(@valid_json, @invalid_json_options)
    assert_match(/#{Vert::OPTIONS_HASH_MISSING_VALID_KEYS}/, fail_options_test,
                 "Expects that the options hash contains at least one valid key when present")
  end

  def test_validate_json_default_successful
    assert(Vert.validate_json(@valid_json).nil?, "Expects that the json passes validation tests")
  end

  def test_validate_json_schema_check_successful?
    result = Vert.validate_json?(@valid_json, {schema: @schema})
    assert(result, "Expects true when validation against Avro schema is successful")
  end

  def test_validate_json_throws_error_when_not_a_string
    result = Vert.validate_json([])
    assert_match(/#{Vert::NOT_A_STRING_ERROR}/, error_message_helper(result), "Expects that a non-string is caught")
  end

  def test_validate_json_throws_custom_error_when_not_a_string
    result = Vert.validate_json([], {custom_errors: {not_a_string: @custom_not_a_string_error}})
    assert_match(/#{@custom_not_a_string_error}/, error_message_helper(result), "Expects that a custom error for a non-string is caught")
  end

  def test_validate_json_throws_error_when_json_is_empty
    result = Vert.validate_json(@empty_json)
    assert_match(/#{Vert::EMPTY_JSON_ERROR}/, error_message_helper(result), "Expects that an empty string is caught")
  end

  def test_validate_json_throws_custom_error_when_json_is_empty
    result = Vert.validate_json(@empty_json, {custom_errors: {empty_json: @custom_empty_json_error}})
    assert_match(/#{@custom_empty_json_error}/, error_message_helper(result), "Expects that acustom empty string error is returned")
  end

  def test_validate_json_throws_error_when_json_object_is_empty
    result = Vert.validate_json(@empty_json_object)
    assert_match(/#{Vert::EMPTY_JSON_OBJECT_ERROR}/, error_message_helper(result), "Expects that an empty JSON object is caught")
  end

  def test_validate_json_throws_custom_error_when_json_object_is_empty
    result = Vert.validate_json(@empty_json_object, {custom_errors: {empty_json_object: @custom_empty_json_object_error}})
    assert_match(/#{@custom_empty_json_object_error}/, error_message_helper(result), "Expects that a custom error is returned for an empty JSON object")
  end

  def test_validate_json_throws_error_when_json_malformed
    result = Vert.validate_json(@malformed_json)
    assert_match(/#{Vert::MALFORMED_JSON_ERROR}/, error_message_helper(result), "Expects malformed JSON is caught")
  end

  def test_validate_json_throws_custom_error_when_json_malformed
    result = Vert.validate_json(@malformed_json, {custom_errors: {malformed_json: @custom_malformed_json_error}})
    assert_match(/#{@custom_malformed_json_error}/, error_message_helper(result), "Expects that a custom error is returned for malformed JSON")
  end

  def test_validate_json_throws_error_for_invalid_schema
    result = Vert.validate_json(@valid_json, {schema: @invalid_schema})
    assert_match(/#{Vert::INVALID_AVRO_SCHEMA_ERROR}/, error_message_helper(result), "Expects that invalid schema is caught") 
  end

  def test_validate_json_throws_custom_error_for_invalid_schema
    result = Vert.validate_json(@valid_json, {schema: @invalid_schema, custom_errors: {invalid_avro_schema: @custom_invalid_avro_schema_error}})
    assert_match(/#{@custom_invalid_avro_schema_error}/, error_message_helper(result), "Expects that custom error is returned when invalid schema is caught") 
  end

  def test_validate_json_throws_error_for_invalid_data
    result = Vert.validate_json(@invalid_json, {schema: @schema})
    assert_match(/#{Vert::INVALID_AVRO_DATUM_ERROR}/, error_message_helper(result),"Expects that invalid data is caught")
  end

  def test_validate_json_throws_custom_error_for_invalid_data
    result = Vert.validate_json(@invalid_json, {schema: @schema, custom_errors: {invalid_avro_datum: @custom_invalid_avro_datum_error}})
    assert_match(/#{@custom_invalid_avro_datum_error}/, error_message_helper(result),"Expects that custom error is returned when invalid data is caught")
  end

end
