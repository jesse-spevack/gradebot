# frozen_string_literal: true

require "test_helper"

class DataCollectionServiceTest < ActiveSupport::TestCase
  test "should collect student work data" do
    # Setup
    student_work = Minitest::Mock.new
    assignment = Minitest::Mock.new
    rubric = Minitest::Mock.new

    assignment.expect(:title, "Essay Assignment")
    assignment.expect(:description, "Write an essay about climate change")
    assignment.expect(:instructions, "Instructions for the essay")
    assignment.expect(:grade_level, "11th Grade")
    assignment.expect(:subject, "English")
    assignment.expect(:rubric, rubric)

    student_work.expect(:assignment, assignment)
    student_work.expect(:content, "This is my essay about climate change...")

    rubric.expect(:to_prompt, { criteria: [] })

    # Exercise
    result = DataCollectionService.collect_student_work_data(student_work)

    # Verify
    assert_equal "Essay Assignment", result[:title]
    assert_equal "Write an essay about climate change", result[:description]
    assert_equal "Instructions for the essay", result[:instructions]
    assert_equal "11th Grade", result[:grade_level]
    assert_equal "English", result[:subject]
    assert_equal({ criteria: [] }, result[:rubric])
    assert_equal "This is my essay about climate change...", result[:student_work]

    # Verify mocks
    assert_mock student_work
    assert_mock assignment
    assert_mock rubric
  end

  test "should collect rubric data" do
    # Setup
    rubric = Minitest::Mock.new
    assignment = Minitest::Mock.new

    assignment.expect(:title, "Essay Assignment")
    assignment.expect(:description, "Write an essay about climate change")
    assignment.expect(:instructions, "Instructions for the essay")
    assignment.expect(:grade_level, "11th Grade")
    assignment.expect(:subject, "English")
    assignment.expect(:raw_rubric_text, "Grading criteria: Content, Style, Format")
    assignment.expect(:raw_rubric_text, "Grading criteria: Content, Style, Format")

    rubric.expect(:assignment, assignment)

    # Exercise
    result = DataCollectionService.collect_rubric_data(rubric)

    # Verify
    assert_equal "Essay Assignment", result[:title]
    assert_equal "Write an essay about climate change", result[:description]
    assert_equal "Instructions for the essay", result[:instructions]
    assert_equal "11th Grade", result[:grade_level]
    assert_equal "English", result[:subject]
    assert_equal "Grading criteria: Content, Style, Format", result[:raw_rubric_text]

    # Verify mocks
    assert_mock rubric
    assert_mock assignment
  end

  test "should collect assignment summary data" do
    # Setup
    assignment = Minitest::Mock.new
    rubric = Minitest::Mock.new
    student_works = [ 1, 2, 3 ] # Mock student works array

    assignment.expect(:title, "Essay Assignment")
    assignment.expect(:description, "Write an essay about climate change")
    assignment.expect(:instructions, "Instructions for the essay")
    assignment.expect(:grade_level, "11th Grade")
    assignment.expect(:subject, "English")
    assignment.expect(:rubric, rubric)
    assignment.expect(:student_works, student_works)

    rubric.expect(:to_prompt, { criteria: [] })

    # Exercise
    result = DataCollectionService.collect_assignment_summary_data(assignment)

    # Verify
    assert_equal "Essay Assignment", result[:title]
    assert_equal "Write an essay about climate change", result[:description]
    assert_equal "Instructions for the essay", result[:instructions]
    assert_equal "11th Grade", result[:grade_level]
    assert_equal "English", result[:subject]
    assert_equal({ criteria: [] }, result[:rubric])
    assert_equal [ 1, 2, 3 ], result[:student_works]

    # Verify mocks
    assert_mock assignment
    assert_mock rubric
  end

  test "should raise ArgumentError for unsupported combination" do
    # Setup
    unsupported_object = Object.new

    # Exercise & Verify
    assert_raises ArgumentError do
      DataCollectionService.for(unsupported_object, "unknown_process_type")
    end
  end

  test "should delegate to correct collection method" do
    # Setup - create a properly mocked class object
    student_work_class = Object.new
    def student_work_class.name
      "StudentWork"
    end

    student_work = Minitest::Mock.new
    student_work.expect(:class, student_work_class)

    # Need to stub the for method and verify it calls collect_student_work_data
    DataCollectionService.stub :collect_student_work_data, ->(_) { "student_work_data" } do
      # Exercise
      result = DataCollectionService.for(student_work, "grade_student_work")

      # Verify
      assert_equal "student_work_data", result
      assert_mock student_work
    end
  end
end
