require "test_helper"

class GradingTask::AssignmentPromptFormatterServiceTest < ActiveSupport::TestCase
  def setup
    @grading_task = mock("GradingTask")
    @grading_task.stubs(:id).returns(123)
    @grading_task.stubs(:assignment_prompt).returns("Write an essay about climate change")
    @grading_task.stubs(:user).returns(users(:teacher))

    @service = GradingTask::AssignmentPromptFormatterService.new
  end

  test "formats assignment prompt using LLM" do
    formatted_html = "<div><h1>Assignment</h1><p>Write an essay</p></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:reload).returns(@grading_task)
    @service.expects(:update_with_retry).with(@grading_task, formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "handles empty assignment prompt" do
    @grading_task.stubs(:assignment_prompt).returns("")
    formatted_html = "<div><p>No assignment provided</p></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:reload).returns(@grading_task)
    @service.expects(:update_with_retry).with(@grading_task, formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "preserves original assignment prompt while adding formatted version" do
    original_prompt = "Write an essay about cats"
    @grading_task.stubs(:assignment_prompt).returns(original_prompt)
    formatted_html = "<div><p>#{original_prompt}</p></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:reload).returns(@grading_task)
    @service.expects(:update_with_retry).with(@grading_task, formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "retries update on optimistic locking error" do
    # Create a mock grading task for this test
    grading_task = mock("GradingTask")

    # Mock the service with a real instance but stub the private method
    service = GradingTask::AssignmentPromptFormatterService.new

    # Set up the sequence of events for the update_with_retry method
    update_sequence = sequence("update_sequence")

    # First update attempt fails with StaleObjectError
    grading_task.expects(:update)
                .with(formatted_assignment_prompt: "formatted content")
                .raises(ActiveRecord::StaleObjectError.new(grading_task, "update"))
                .in_sequence(update_sequence)

    # Reload is called
    grading_task.expects(:reload).returns(grading_task).in_sequence(update_sequence)

    # Second update attempt succeeds
    grading_task.expects(:update)
                .with(formatted_assignment_prompt: "formatted content")
                .returns(true)
                .in_sequence(update_sequence)

    # Call the private method directly for testing
    result = service.send(:update_with_retry, grading_task, "formatted content")

    # Verify the result
    assert result
  end
end
