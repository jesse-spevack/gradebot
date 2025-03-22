require "test_helper"

class CreateStudentSubmissionsCommandTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
  end
end
