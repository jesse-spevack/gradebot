require "test_helper"

class BaseCommandTest < ActiveSupport::TestCase
  class DummyCommand < BaseCommand
    attr_reader :test_arg

    def initialize(test_arg:)
      super
      @test_arg = test_arg
    end

    def execute
      @result = "Success: #{test_arg}"
    end
  end

  class FailingCommand < BaseCommand
    def execute
      raise StandardError, "Something went wrong"
    end
  end

  def test_initialization_with_arbitrary_arguments
    command = DummyCommand.new(test_arg: "hello")
    assert_equal "hello", command.test_arg
  end

  def test_call_executes_and_returns_self
    command = DummyCommand.new(test_arg: "test")
    result = command.call
    assert_equal command, result
    assert_equal "Success: test", command.result
  end

  def test_success_and_failure_states
    command = DummyCommand.new(test_arg: "test")
    command.call
    assert command.success?
    assert_not command.failure?
  end

  def test_handles_exceptions
    command = FailingCommand.new
    command.call
    assert command.failure?
    assert_not command.success?
    assert_equal "Something went wrong", command.errors.first
  end

  def test_initial_state
    command = DummyCommand.new(test_arg: "test")
    assert_nil command.result
    assert_empty command.errors
    assert_not command.success?
    assert command.failure?
  end
end
