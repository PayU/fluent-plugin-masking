require "test-unit"
require "fluent/test"
require "fluent/test/driver/filter"
require "fluent/test/helpers"
require "./lib/fluent/plugin/filter_masking.rb"

MASK_STRING = "*******"

class YourOwnFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup # this is required to setup router and others
  end

  # default configuration for tests
  CONFIG = %[
    fieldsToMaskFilePath test/fields-to-mask
    fieldsToExcludeJSONPaths excludedField,exclude.path.nestedExcludedField
  ]

  # configuration for tests without exclude parameter
  CONFIG_NO_EXCLUDE = %[
    fieldsToMaskFilePath test/fields-to-mask
  ]

  # configuration for tests with case insensitive fields
  CONFIG_CASE_INSENSITIVE = %[
    fieldsToMaskFilePath test/fields-to-mask-insensitive
  ]

  # configuration for special json escaped cases
  CONFIG_SPECIAL_CASES = %[
    fieldsToMaskFilePath test/fields-to-mask
    fieldsToExcludeJSONPaths excludedField,exclude.path.nestedExcludedField
    handleSpecialEscapedJsonCases true
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::MaskingFilter).configure(conf)
  end

  def filter(config, messages)
    d = create_driver(config)
    d.run(default_tag: "input.access") do
      messages.each do |message|
        d.feed(message)
      end
    end
    d.filtered_records
  end

  sub_test_case 'plugin will mask all fields that need masking - case sensitive fields' do
    test 'mask field in hash object' do
      conf = CONFIG_NO_EXCLUDE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :email=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :email=>MASK_STRING}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in json string' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\", \"type\":\"puggle\"}" }
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object and in json string' do
      conf = CONFIG
      messages = [
        { :msg=>"sup", :email=>"mickey-the-dog@zooz.com", :body => "{\"first_name\":\"mickey\", \"type\":\"puggle\", \"last_name\":\"the-dog\"}", :status_code=>201, :password=>"d0g!@"}
      ]
      expected = [
        { :msg=>"sup", :email=>MASK_STRING, :body => "{\"first_name\":\"*******\", \"type\":\"puggle\", \"last_name\":\"*******\"}", :status_code=>201, :password=>MASK_STRING }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in nested json string' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\",\"address\":\"{\"street\":\"Austin\",\"number\":\"89\"}\", \"type\":\"puggle\"}" } 
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\",\"address\":\"{\"street\":\"*******\",\"number\":\"*******\"}\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in nested json escaped string' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\",\"address\":\"{\\\"street\":\\\"Austin\\\",\\\"number\":\\\"89\\\"}\", \"type\":\"puggle\"}" } 
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\",\"address\":\"{\\\"street\\\":\\\"*******\\\",\\\"number\\\":\\\"*******\\\"}\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object with exclude' do
      conf = CONFIG
      messages = [
        {:not_masked_field=>"mickey-the-dog", :email=>"mickey-the-dog@zooz.com", :first_name=>"Micky", :excludedField=>"first_name"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :email=>MASK_STRING, :first_name=>"Micky", :excludedField=>"first_name"}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end
    
    test 'mask field in hash object with nested exclude' do
      conf = CONFIG
      messages = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>"mickey-the-dog@zooz.com", :first_name=>"Micky",  :exclude=>{:path=>{:nestedExcludedField=>"first_name,last_name"}}}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>MASK_STRING, :first_name=>"Micky", :exclude=>{:path=>{:nestedExcludedField=>"first_name,last_name"}}}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object with base and nested exclude' do
      conf = CONFIG
      messages = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>"mickey-the-dog@zooz.com", :first_name=>"Micky", :excludedField=>"first_name", :exclude=>{:path=>{:nestedExcludedField=>"last_name"}}}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>MASK_STRING, :first_name=>"Micky", :excludedField=>"first_name", :exclude=>{:path=>{:nestedExcludedField=>"last_name"}}}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in json string with exclude' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\", \"type\":\"puggle\"}", :excludedField=>"first_name" }
      ]
      expected = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"*******\", \"type\":\"puggle\"}", :excludedField=>"first_name" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

  end

  sub_test_case 'plugin will mask all fields that need masking - case INSENSITIVE fields' do

    test 'mask field in hash object with camel case' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :Email=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :email=>MASK_STRING}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'not mask field in hash object since case not match' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :FIRST_NAME=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :FIRST_NAME=>"mickey-the-dog@zooz.com"}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object with snakecase' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :LaSt_NaMe=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>MASK_STRING}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask case insensitive and case sensitive field in nested json escaped string' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        { :body => "{\"firsT_naMe\":\"mickey\",\"last_NAME\":\"the-dog\",\"address\":\"{\\\"Street\":\\\"Austin\\\",\\\"number\":\\\"89\\\"}\", \"type\":\"puggle\"}" } 
      ]
      expected = [
        { :body => "{\"firsT_naMe\":\"mickey\",\"last_name\":\"*******\",\"address\":\"{\\\"street\\\":\\\"*******\\\",\\\"number\\\":\\\"*******\\\"}\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

  end

  sub_test_case 'plugin will mask all fields that need masking - special json escaped cases' do
    test 'mask field in nested json escaped string when one of the values ends with "," (the value for "some_custom" field)' do
      conf = CONFIG_SPECIAL_CASES
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\",\"address\":\"{\\\"street\":\\\"Austin\\\",\\\"number\":\\\"89\\\"}\", \"type\":\"puggle\", \"cookie\":\"some_custom=,,live,default,,2097403972,2.22.242.38,\", \"city\":\"new york\"}" } 
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\",\"address\":\"{\\\"street\\\":\\\"*******\\\",\\\"number\\\":\\\"*******\\\"}\", \"type\":\"puggle\", \"cookie\":\"*******\", \"city\":\"new york\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end
  end  
end