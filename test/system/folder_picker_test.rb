require "test_helper"
require "application_system_test_case"

class FolderPickerTest < ApplicationSystemTestCase
  def setup
    super
  end

  def mock_google_picker
    # Mock the Google Picker API with minimal implementation
    page.evaluate_script(<<~JS)
      window.gapi = { load: function(api, callback) { callback(); } };
      window.google = { picker: { Action: { PICKED: 'picked' } } };
    JS
  end

  test "basic folder picker flow" do
    # Test core authentication flow
    visit grading_job_path
    assert_current_path new_session_path # Redirects to sign in when not authenticated
    assert_no_selector "[data-testid='folder-picker']"

    sign_in_with_google
    assert_current_path grading_job_path
    assert_selector "[data-testid='folder-picker']", text: "Select Folder"

    # Test folder selection
    mock_google_picker
    find('[data-testid="folder-picker"]').click

    # Simulate folder selection
    page.execute_script(<<~JS)
      const pickerInstance = document.querySelector('[data-controller="folder-picker"]')
      const controller = window.Stimulus.getControllerForElementAndIdentifier(pickerInstance, 'folder-picker')
      controller.handlePickerResponse({
        action: 'picked',
        docs: [{
          id: 'test_folder_123',
          name: 'Test Assignment Folder'
        }]
      })
    JS

    assert_selector "[data-testid='selected-folder']", text: "Loading folder details..."
  end
end
