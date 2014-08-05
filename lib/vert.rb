module Vert

  extend self

  ValidationError = Class.new(StandardError)

  NOT_A_HASH_ERROR = "Not a hash." 
  EMPTY_ERROR = "The hash is empty." 
  ABSENT_KEY_ERROR = "The hash does not contain the following key/s"  
  HASH_KEY_ERROR = "The hash map either does not contain key/s provided or the keys are present but do not have hash map as its value."

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

  def validated?(hash, keys = {})
    validate(hash, keys).nil? ? true: false 
  end

end
