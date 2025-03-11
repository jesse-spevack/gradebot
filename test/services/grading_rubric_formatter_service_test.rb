require "test_helper"

class GradingRubricFormatterServiceTest < ActiveSupport::TestCase
  def setup
    @grading_task = mock("GradingTask")
    @grading_task.stubs(:id).returns(123)
    @grading_task.stubs(:grading_rubric).returns("Grammar: 20%, Content: 80%")
    @grading_task.stubs(:user).returns(users(:teacher))

    @service = GradingRubricFormatterService.new
  end

  test "formats grading rubric using LLM" do
    formatted_html = "<div><h1>Rubric</h1><ul><li>Grammar: 20%</li></ul></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:update).with(formatted_grading_rubric: formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "handles empty grading rubric" do
    @grading_task.stubs(:grading_rubric).returns("")
    formatted_html = "<div><p>No rubric provided</p></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:update).with(formatted_grading_rubric: formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "preserves original grading rubric while adding formatted version" do
    original_rubric = "Grammar: 20%, Content: 80%"
    @grading_task.stubs(:grading_rubric).returns(original_rubric)
    formatted_html = "<div><ul><li>Grammar: 20%</li><li>Content: 80%</li></ul></div>"
    stub_llm_request(content: formatted_html)

    @grading_task.expects(:update).with(formatted_grading_rubric: formatted_html).returns(true)

    result = @service.format(@grading_task)

    assert_equal @grading_task, result
  end

  test "creates LLM request with correct parameters" do
    expected_prompt = "test prompt"
    PromptBuilder.expects(:build).with(:format_grading_rubric, { grading_rubric: @grading_task.grading_rubric }).returns(expected_prompt)

    # Mock the LLM client and response
    llm_client = mock("LLMClient")
    LLM::Client.expects(:new).returns(llm_client)
    llm_client.expects(:generate).returns({ content: "formatted content" })

    # Expect the update to happen
    @grading_task.expects(:update).with(formatted_grading_rubric: "formatted content").returns(true)

    @service.format(@grading_task)
  end
end
