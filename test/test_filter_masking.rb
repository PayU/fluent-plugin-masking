# test/plugin/test_filter_your_own.rb

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

  sub_test_case 'configured with invalid configuration' do
    test 'empty configuration' do
      assert_raise(Fluent::ConfigError) do
         create_driver('')
      end
    end

    test 'param1 should reject too short string' do
      conf = %[
        param1 a
      ]
      assert_raise(Fluent::ConfigError) do
         create_driver(conf)
      end
    end
  end

  sub_test_case 'plugin will mask all fields that need masking' do
    test 'mask first_name and last_name' do
      conf = CONFIG
      messages = [
        { "first_name" => "mickey", "last_name" => "the-dog" }
      ]
      expected = [
        { "first_name" => MASK_STRING, "last_name" => MASK_STRING }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask only email' do
      conf = CONFIG
      messages = [
        { "not_masked_field" => "mickey-the-dog", "email" => "mickey-the-dog@zooz.com" }
      ]
      expected = [
        { "not_masked_field" => "mickey-the-dog", "email" => MASK_STRING }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask nothing' do
      conf = CONFIG
      messages = [
        { "not_masked_field_1" => "mickey-the-dog", "not_masked_field_2" => "nully_the_carpet" }
      ]
      expected = [
        { "not_masked_field_1" => "mickey-the-dog", "not_masked_field_2" => "nully_the_carpet" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end
  end
end
