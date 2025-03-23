require "test_helper"

class GradingTask::GradingRubricFormatterServiceTest < ActiveSupport::TestCase
  def setup
    @grading_task = grading_tasks(:one)
    @service = GradingTask::GradingRubricFormatterService.new
  end

  test "formats grading rubric using LLM" do
    formatted_html = "<div><h1>Rubric</h1><ul><li>Grammar: 20%</li></ul></div>"

    # Create a mock LLM client
    mock_client = mock
    mock_client.stubs(:generate).returns({
      content: formatted_html,
      finish_reason: "stop",
      model: "claude-3-5-haiku",
      response_id: "test-response-id"
    })

    # Stub the LLM::Client.new method
    LLM::Client.stubs(:new).returns(mock_client)

    # Stub the private method
    @service.stubs(:update_with_retry).returns(true)

    # Stub the reload method to avoid database interactions
    @grading_task.stubs(:reload).returns(@grading_task)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "handles empty grading rubric" do
    # Save original rubric
    original_rubric = @grading_task.grading_rubric
    @grading_task.update(grading_rubric: "")

    formatted_html = "<div><p>No rubric provided</p></div>"

    # Create a mock LLM client
    mock_client = mock
    mock_client.stubs(:generate).returns({
      content: formatted_html,
      finish_reason: "stop",
      model: "claude-3-5-haiku",
      response_id: "test-response-id"
    })

    # Stub the LLM::Client.new method
    LLM::Client.stubs(:new).returns(mock_client)

    # Stub the private method
    @service.stubs(:update_with_retry).returns(true)

    # Stub the reload method to avoid database interactions
    @grading_task.stubs(:reload).returns(@grading_task)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result

    # Restore original rubric
    @grading_task.update(grading_rubric: original_rubric)
  end

  test "preserves original grading rubric while adding formatted version" do
    original_rubric = @grading_task.grading_rubric
    formatted_html = "<div><ul><li>Grammar: 20%</li><li>Content: 80%</li></ul></div>"

    # Create a mock LLM client
    mock_client = mock
    mock_client.stubs(:generate).returns({
      content: formatted_html,
      finish_reason: "stop",
      model: "claude-3-5-haiku",
      response_id: "test-response-id"
    })

    # Stub the LLM::Client.new method
    LLM::Client.stubs(:new).returns(mock_client)

    # Stub the private method
    @service.stubs(:update_with_retry).returns(true)

    # Stub the reload method to avoid database interactions
    @grading_task.stubs(:reload).returns(@grading_task)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
    assert_equal original_rubric, @grading_task.grading_rubric
  end

  test "retries update on optimistic locking error" do
    # Use a real grading task from fixtures
    grading_task = @grading_task.dup

    # Create a service instance
    service = GradingTask::GradingRubricFormatterService.new

    # Stub the update! method to fail once then succeed
    update_called = 0
    grading_task.define_singleton_method(:update!) do |*args|
      update_called += 1
      if update_called == 1
        raise ActiveRecord::StaleObjectError.new(self, "update")
      else
        true
      end
    end

    # Stub reload to return self
    grading_task.define_singleton_method(:reload) do
      self
    end

    # Stub sleep to avoid actual sleeping
    service.stubs(:sleep)

    # Call the private method
    result = service.send(:update_with_retry, grading_task, "formatted content")

    # Verify the result
    assert result
    assert_equal 2, update_called
  end
end
