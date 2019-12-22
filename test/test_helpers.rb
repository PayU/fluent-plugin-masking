require "test/unit"
require "./lib/fluent/plugin/helpers.rb"

class HelpersTest < Test::Unit::TestCase
  m = Class.new do
    include Helpers 
  end.new
  sub_test_case "myDig function" do
    test "Call function with nil" do
      t = m.myDig(nil ,[:a])
      assert_equal(t, nil)
    end
    test "Not found" do
      t = m.myDig({:b => "t"},[:a])
      assert_equal(t, nil)
    end
    test "Found symbol" do
      t = m.myDig({:a => "t"},[:a])
      assert_equal(t, "t")
    end
    test "Found string when given symbol" do
      t = m.myDig({"a" => "t"},[:a])
      assert_equal(t, "t")
    end
    test "Found symbol nested" do
      t = m.myDig({:a => {:b => "t"}},[:a, :b])
      assert_equal(t, "t")
    end
    test "Found string when given symbol nested" do
      t = m.myDig({"a" => {"b" => "t"}},[:a, :b])
      assert_equal(t, "t")
    end
    test "Found hybrid string/symbol when given symbol nested" do
      t = m.myDig({"a" => {:b => "t"}},[:a, :b])
      assert_equal(t, "t")
    end
    test "Does not dig in string" do
      t = m.myDig({"a" => {:b => "t"}},[:a, :b, :c])
      assert_equal(t, nil)
    end
  end
end