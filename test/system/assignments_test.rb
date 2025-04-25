require "application_system_test_case"
require "active_job/test_helper" # Include Active Job helpers

class AssignmentsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:teacher) # Use the available teacher fixture
    login_as @user # Assumes you have a login_as helper in your test setup
  end

  test "creating a new assignment" do
    # Prepare assignment data
    assignment_title = "System Test Assignment #{Time.now.to_i}"
    assignment_subject = "System Testing"
    assignment_grade_level = "10"

    # Prepare document data (simulating Google Picker selection)
    selected_docs = [
      { id: "doc_id_1", name: "Student Work 1.gdoc", url: "https://docs.google.com/document/d/doc_id_1/edit" },
      { id: "doc_id_2", name: "Student Work 2.gdoc", url: "https://docs.google.com/document/d/doc_id_2/edit" }
    ]
    document_data_json = selected_docs.to_json

    # Exercise
    visit new_assignment_path

    fill_in "Title", with: assignment_title
    fill_in "Subject", with: assignment_subject
    select assignment_grade_level, from: "Grade level"
    fill_in "Description", with: "This is a test description."
    fill_in "Instructions", with: "Follow these instructions carefully."
    # Assuming default rubric option is 'generate' or we don't need to interact with it for happy path

    # Simulate filling the hidden field updated by the Stimulus controller
    # Note: Capybara might need `execute_script` if `fill_in` with `visible: :hidden` doesn't work reliably
    # fill_in "assignment_document_data", with: document_data_json, visible: :hidden
    # Alternative using execute_script:
    page.execute_script(
      "document.getElementById('assignment_document_data').value = arguments[0];",
      document_data_json
    )
    # Optional: Trigger change event if needed by Stimulus/JS
    # page.execute_script("document.getElementById('assignment_document_data').dispatchEvent(new Event('change'))")

    # Verify initial state before submit (optional but good practice)
    assert_equal 0, Assignment.where(title: assignment_title).count
    initial_selected_doc_count = SelectedDocument.count
    initial_student_work_count = StudentWork.count

    assert_enqueued_jobs 1, only: AssignmentProcessingJob do
      click_on "Submit for grading" # Verify this button text/id is correct
    end

    # Verify
    # 1. Redirection and flash message
    assert_current_path assignment_path(Assignment.last)
    assert_text "Assignment was successfully created."

    # 2. Assignment details on the page
    assert_selector "h1", text: assignment_title # Assuming show page has h1 with title
    assert_text assignment_subject
    assert_text "Grade Level: #{assignment_grade_level}" # Adjust selector as needed

    # 3. Database records created
    created_assignment = Assignment.find_by(title: assignment_title)
    assert_not_nil created_assignment
    assert_equal @user, created_assignment.user
    assert_equal selected_docs.count, created_assignment.selected_documents.count
    assert_equal selected_docs.count, created_assignment.student_works.count

    assert_equal initial_selected_doc_count + selected_docs.count, SelectedDocument.count
    assert_equal initial_student_work_count + selected_docs.count, StudentWork.count

    # Verify selected document details (optional but recommended)
    created_assignment.selected_documents.order(:google_doc_id).each_with_index do |doc, index|
      assert_equal selected_docs[index][:id], doc.google_doc_id
      assert_equal selected_docs[index][:name], doc.title
      assert_equal selected_docs[index][:url], doc.url
    end
  end
end
