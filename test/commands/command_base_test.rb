require "test_helper"

class TestCommand < CommandBase
  private

  def execute
    "Result: #{argument_1} and #{argument_2}"
  end
end

class ErrorCommand < CommandBase
  private
  def execute
    raise StandardError, "Something went wrong"
  end
end

class CommandBaseTest < ActiveSupport::TestCase
  test "can be called with class method" do
    command = TestCommand.call(argument_1: 1, argument_2: "y")

    assert_equal "Result: 1 and y", command.result
    assert command.success?
    refute command.failure?
  end

  test "can not be called with positional arguments" do
    assert_raises ArgumentError do
      TestCommand.call(1, "y")
    end
  end

  test "handles errors" do
    command = ErrorCommand.call

    assert command.failure?
    refute command.success?
    assert_equal [ "Something went wrong" ], command.errors
    assert_nil command.result
  end
end
