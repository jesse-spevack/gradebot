require "test_helper"

class AssignmentPromptFormatterServiceTest < ActiveSupport::TestCase
  def setup
    @grading_task = mock("GradingTask")
    @grading_task.stubs(:id).returns(123)
    @grading_task.stubs(:assignment_prompt).returns("Write an essay about climate change")
    @grading_task.stubs(:user).returns(users(:teacher))

    @service = AssignmentPromptFormatterService.new
  end

  test "formats assignment prompt using LLM" do
    formatted_html = "<div><h1>Assignment</h1><p>Write an essay</p></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:update).with(formatted_assignment_prompt: formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "handles empty assignment prompt" do
    @grading_task.stubs(:assignment_prompt).returns("")
    formatted_html = "<div><p>No assignment provided</p></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:update).with(formatted_assignment_prompt: formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "preserves original assignment prompt while adding formatted version" do
    original_prompt = "Write an essay about cats"
    @grading_task.stubs(:assignment_prompt).returns(original_prompt)
    formatted_html = "<div><p>#{original_prompt}</p></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:update).with(formatted_assignment_prompt: formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "creates LLM request with correct parameters" do
    expected_prompt = "test prompt"
    PromptBuilder.expects(:build).with(:format_assignment, { assignment_prompt: @grading_task.assignment_prompt }).returns(expected_prompt)

    # Mock the LLM client and response
    llm_client = mock("LLMClient")
    LLM::Client.expects(:new).returns(llm_client)
    llm_client.expects(:generate).returns({ content: "formatted content" })

    # Expect the update to happen
    @grading_task.expects(:update).with(formatted_assignment_prompt: "formatted content").returns(true)

    @service.format(@grading_task)
  end
end
