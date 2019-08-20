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

  sub_test_case 'plugin will mask all fields that need masking' do
    test 'mask field in hash object' do
      conf = CONFIG
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
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\",\"address\":\"{\"street\":\"*******\",\"number\":\"*******\"}\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end
  end
end