# test/zeitwerk/autoloading_test.rb
require "test_helper"

class AutoloadingTest < ActiveSupport::TestCase
  test "zeitwerk autoloading works correctly" do
    assert_nothing_raised do
      Rails.autoloaders.main.eager_load
    end
  end
end