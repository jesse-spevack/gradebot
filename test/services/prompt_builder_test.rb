# frozen_string_literal: true

require "test_helper"

class PromptBuilderTest < ActiveSupport::TestCase
  test "builds grading prompt" do
    params = {
      document_content: "test content",
      assignment_prompt: "test prompt",
      grading_rubric: "test rubric"
    }

    PromptTemplate.expects(:render).with(:grading, params).returns("test prompt")

    prompt = PromptBuilder.build(:grading, params)
    assert_equal "test prompt", prompt
  end

  test "raises error when prompt building fails" do
    params = { document_content: "test" }

    PromptTemplate.expects(:render).raises(StandardError.new("test error"))

    assert_raises StandardError do
      PromptBuilder.build(:grading, params)
    end
  end
end
