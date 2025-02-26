# GradeBot Development Notes

## What We've Accomplished

### Admin User Functionality
- Added `admin` boolean field to the `users` table
- Implemented `admin?` method in the User model
- Created `Admin::BaseController` with access control for admin users
- Implemented `Admin::FeatureFlagsController` for managing feature flags
- Created a rake task `admin:seed` to set admin privileges based on the `ADMIN_EMAIL` environment variable
- Updated deployment configuration to include `ADMIN_EMAIL` in the secret environment variables
- Created a post-deploy hook to automatically run the `admin:seed` task after deployment

### Test Environment Improvements
- Reduced test output noise by setting log level to `:warn` in the test environment
- Silenced warnings about `STATS_DIRECTORIES` by setting `$VERBOSE = nil`
- Fixed the `LoggingHelper` to not reset the logger to STDOUT in test environment
- Configured Capybara to run silently without showing server startup messages
- Modified the admin rake task to not print messages during tests
- Added comprehensive Capybara configuration to improve test performance and reduce noise

### Code Quality
- Fixed code style issues using RuboCop
- Ensured consistent string literal style (double quotes)
- Removed trailing whitespace
- Fixed duplicate Capybara server configuration

## Next Steps

### Admin Interface
1. **Create Admin Dashboard**: Implement a central dashboard for admin users with links to various administrative functions
2. **Enhance Feature Flags UI**: Build out the feature flags management interface with a user-friendly UI
3. **User Management**: Add functionality for admins to view, manage, and potentially impersonate users for support purposes

### Testing and Documentation
1. **Admin Documentation**: Create documentation for admin features and how to use them
2. **Test Admin Features**: Add more comprehensive tests for admin functionality
3. **Create Admin User Guide**: Develop a guide for admin users explaining available features and how to use them

### Deployment and Monitoring
1. **Verify Admin Seeding**: After deployment, verify that the `admin:seed` task runs correctly
2. **Monitor Admin Actions**: Implement logging for important admin actions for audit purposes
3. **Add Admin Analytics**: Create analytics dashboard for admins to monitor application usage

### Future Enhancements
1. **Role-Based Access Control**: Consider expanding the admin system to support multiple roles with different permissions
2. **Admin Notifications**: Implement a notification system for admins about important system events
3. **Bulk Operations**: Add functionality for admins to perform bulk operations on users or other resources

# Prompts to work through
Prompt 4: Feature Flag Service
CopyLet's implement the feature flag service. First, write a test for the FeatureFlags::FlagService class that:
1. Returns false for non-existent flags
2. Returns the enabled state for existing flags
3. Can enable and disable flags
4. Records who made the change
5. Supports context-based flag evaluation (even if the initial implementation is simple)
6. Can list all flags
7. Ensures predefined flags exist in the database
After writing and seeing the test fail:
CopyNow implement the FeatureFlags::FlagService class. The implementation should:
1. Define class methods for checking flag status
2. Support enabling and disabling flags
3. Support simple context evaluation (can be expanded later)
4. Include methods for listing and seeding flags
5. Handle error cases gracefully
After implementation:
CopyLet's refactor the feature flag service. Consider:
1. Improving method organization
2. Optimizing database queries
3. Adding caching for frequently accessed flags
4. Ensuring clear documentation for future expansion

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 5: Student Submission Model
CopyLet's implement the StudentSubmission model. First, write a test that:
1. Validates the model belongs to a GradingTask
2. Validates original_doc_id is present
3. Has a status enum with states: pending, processing, completed, failed
4. Restricts status transitions appropriately
5. Has methods for checking each status
6. Handles validation of grades based on status
7. Associates with criterion_grades
After writing and seeing the test fail:
CopyNow implement the StudentSubmission model. The implementation should:
1. Define the appropriate validations
2. Set up the status enum
3. Add validations for status transitions
4. Include helper methods for status checking
5. Set up the association with GradingTask and criterion_grades
After implementation:
CopyLet's refactor the StudentSubmission model. Consider:
1. Extracting status-related logic to a concern if complex
2. Improving documentation
3. Adding useful scopes for common queries
4. Ensuring validation error messages are helpful

Then run Rubocop to ensure it meets Ruby style guidelines.
Phase 2: LLM Integration
Prompt 6: LLM Configuration
CopyLet's implement the LLM configuration class. First, write a test for LLM::Configuration that:
1. Returns the appropriate model for different task types
2. Uses feature flags to determine which model to use
3. Returns default models when feature flags are disabled
4. Has methods for checking if specific features are enabled
5. Works with environment variables for default configuration
After writing and seeing the test fail:
CopyNow implement the LLM::Configuration class. The implementation should:
1. Define methods for determining models by task type
2. Check feature flags for model selection
3. Use environment variables as fallbacks
4. Include helper methods for checking feature status
5. Be easy to extend for future models
After implementation:
CopyLet's refactor the LLM configuration. Consider:
1. Improving method organization
2. Optimizing flag checks
3. Making the interface more consistent
4. Ensuring good documentation

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 7: LLM Client Factory
CopyLet's implement the LLM client factory. First, write a test for LLM::ClientFactory that:
1. Creates different client types based on model names
2. Returns an OpenAiClient for gpt* models
3. Returns an AnthropicClient for claude* models
4. Raises an error for unsupported models
5. Passes the model name to the created client
After writing and seeing the test fail:
CopyNow implement the LLM::ClientFactory class. The implementation should:
1. Define a create method that takes a model name
2. Create the appropriate client based on the model prefix
3. Handle error cases for unsupported models
4. Pass necessary configuration to clients
After implementation:
CopyLet's refactor the client factory. Consider:
1. Making the factory more extensible for future providers
2. Improving error messages
3. Adding documentation
4. Ensuring efficient operation

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 8: Base LLM Client
CopyLet's implement the base LLM client. First, write a test for LLM::BaseClient that:
1. Can be initialized with a model name
2. Has a generate method that tracks operations
3. Delegates to an execute_request method
4. Logs performance metrics and cost estimates
5. Raises NotImplementedError for execute_request
After writing and seeing the test fail:
CopyNow implement the LLM::BaseClient class. The implementation should:
1. Store the model name
2. Set up logging
3. Implement the generate method with operation tracking
4. Include token counting and cost estimation
5. Define but don't implement execute_request
After implementation:
CopyLet's refactor the base client. Consider:
1. Improving the token counting logic
2. Enhancing the cost calculation
3. Making the logging more descriptive
4. Ensuring the interface is easy to implement

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 9: OpenAI Client Implementation
CopyLet's implement the OpenAI client. First, write a test for LLM::OpenAiClient that:
1. Inherits from BaseClient
2. Implements execute_request to call the OpenAI API
3. Properly formats the prompt for the OpenAI API
4. Extracts the response content correctly
5. Handles API errors appropriately
After writing and seeing the test fail:
CopyNow implement the LLM::OpenAiClient class. The implementation should:
1. Inherit from BaseClient
2. Override execute_request to call the OpenAI API
3. Format parameters according to the OpenAI API
4. Extract text from the response
5. Handle and log errors appropriately
After implementation:
CopyLet's refactor the OpenAI client. Consider:
1. Improving error handling
2. Adding retry logic
3. Enhancing parameter handling
4. Ensuring efficient operation

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 10: Anthropic Client Implementation
CopyLet's implement the Anthropic client. First, write a test for LLM::AnthropicClient that:
1. Inherits from BaseClient
2. Implements execute_request to call the Anthropic API
3. Properly formats the prompt for the Anthropic API
4. Extracts the response content correctly
5. Handles API errors appropriately
After writing and seeing the test fail:
CopyNow implement the LLM::AnthropicClient class. The implementation should:
1. Inherit from BaseClient
2. Override execute_request to call the Anthropic API
3. Format parameters according to the Anthropic API
4. Extract text from the response
5. Handle and log errors appropriately
After implementation:
CopyLet's refactor the Anthropic client. Consider:
1. Improving error handling
2. Adding retry logic
3. Enhancing parameter handling
4. Ensuring efficient operation

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 11: Prompt Templates
CopyLet's implement the prompt template system. First, write a test for LLM::PromptTemplates::Grading that:
1. Has a render method that takes assignment_prompt, rubric, and submission_content
2. Formats these inputs into a structured prompt
3. Includes clear instructions for the LLM
4. Specifies the expected output format
After writing and seeing the test fail:
CopyNow implement the LLM::PromptTemplates::Grading class. The implementation should:
1. Define a render method that creates a formatted prompt
2. Include clear instructions for the grading task
3. Specify the JSON response format
4. Handle various input types gracefully
After implementation:
CopyLet's refactor the prompt template. Consider:
1. Improving the prompt structure
2. Adding variation based on feature flags
3. Making the template more maintainable
4. Adding documentation for prompt design decisions

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 12: Response Parser
CopyLet's implement the response parser. First, write a test for LLM::ResponseParsers::GradingParser that:
1. Can parse well-formatted JSON responses
2. Has fallback parsing for non-JSON responses
3. Extracts criteria grades, overall score, and feedback
4. Handles missing or malformed data gracefully
After writing and seeing the test fail:
CopyNow implement the LLM::ResponseParsers::GradingParser class. The implementation should:
1. Define a parse method that handles JSON responses
2. Include fallback parsing for text responses
3. Extract and format all required fields
4. Handle errors and edge cases appropriately
After implementation:
CopyLet's refactor the response parser. Consider:
1. Improving the fallback parsing logic
2. Adding more robust error handling
3. Ensuring all field types are consistent
4. Making the parser more resilient to variations

Then run Rubocop to ensure it meets Ruby style guidelines.
Phase 3: Commands for Core Operations
Prompt 13: Create Command for GradingTasks
CopyLet's implement the GradingTasks::Create command. First, write a test that:
1. Initializes with user and params arguments
2. Creates a new GradingTask belonging to the user
3. Returns the created task on success
4. Returns errors on failure
5. Logs the operation
After writing and seeing the test fail:
CopyNow implement the GradingTasks::Create command that inherits from BaseCommand. The implementation should:
1. Store user and params from initialization
2. Override execute to create a GradingTask
3. Capture and handle validation errors
4. Use the logger for operation tracking
After implementation:
CopyLet's refactor the create command. Consider:
1. Improving validation handling
2. Enhancing error messages
3. Adding more comprehensive logging
4. Ensuring the command is reusable

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 14: Process Folder Command
CopyLet's implement the GradingTasks::ProcessFolder command. First, write a test that:
1. Initializes with a grading_task_id
2. Updates the grading task status to processing
3. Uses the Google Drive service to list files
4. Creates StudentSubmission records for each document
5. Returns the created submissions
6. Logs the operation
After writing and seeing the test fail:
CopyNow implement the GradingTasks::ProcessFolder command. The implementation should:
1. Find the grading task by ID
2. Update its status
3. Fetch files from Google Drive
4. Create submissions for each document
5. Use the logger for operation tracking
6. Handle errors appropriately
After implementation:
CopyLet's refactor the process folder command. Consider:
1. Improving file filtering
2. Enhancing error handling
3. Adding more detailed logging
4. Optimizing database operations

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 15: Process Submission Command
CopyLet's implement the StudentSubmissions::ProcessSubmission command. First, write a test that:
1. Initializes with a submission_id
2. Updates the submission status to processing
3. Fetches document content from Google Drive
4. Uses the LLM::GradingService to grade the submission
5. Updates the submission with results
6. Creates CriterionGrade records
7. Broadcasts updates using the broadcaster
After writing and seeing the test fail:
CopyNow implement the StudentSubmissions::ProcessSubmission command. The implementation should:
1. Find the submission by ID
2. Update its status
3. Fetch document content
4. Use the grading service
5. Update the submission with results
6. Create criterion grades
7. Use the broadcaster for updates
8. Handle errors appropriately
After implementation:
CopyLet's refactor the process submission command. Consider:
1. Improving error handling
2. Enhancing broadcasting
3. Adding more detailed logging
4. Optimizing service interactions

Then run Rubocop to ensure it meets Ruby style guidelines.
Phase 4: Background Jobs
Prompt 16: Process Grading Task Job
CopyLet's implement the ProcessGradingTaskJob. First, write a test that:
1. Enqueues to the default queue
2. Calls the GradingTasks::ProcessFolder command
3. Handles command success and failure
4. Updates the grading task on failure
5. Logs the job execution
After writing and seeing the test fail:
CopyNow implement the ProcessGradingTaskJob class. The implementation should:
1. Inherit from ApplicationJob
2. Specify the queue
3. Implement perform to call the ProcessFolder command
4. Handle and log failures
5. Update the grading task status appropriately
After implementation:
CopyLet's refactor the job. Consider:
1. Improving error handling
2. Adding retry configuration
3. Enhancing logging
4. Ensuring idempotence

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 17: Process Student Submission Job
CopyLet's implement the ProcessStudentSubmissionJob. First, write a test that:
1. Enqueues to the grading queue
2. Includes retry configuration
3. Calls the StudentSubmissions::ProcessSubmission command
4. Handles command success and failure
5. Updates the submission on failure
6. Logs the job execution
After writing and seeing the test fail:
CopyNow implement the ProcessStudentSubmissionJob class. The implementation should:
1. Inherit from ApplicationJob
2. Specify the queue
3. Configure retries
4. Implement perform to call the ProcessSubmission command
5. Handle and log failures
6. Update the submission status appropriately
After implementation:
CopyLet's refactor the job. Consider:
1. Improving retry configuration
2. Enhancing error handling
3. Adding more detailed logging
4. Ensuring idempotence

Then run Rubocop to ensure it meets Ruby style guidelines.
Phase 5: Broadcasting and Real-time Updates
Prompt 18: Student Submission Broadcaster
CopyLet's implement the broadcaster for student submissions. First, write a test for Broadcasters::StudentSubmissionBroadcaster that:
1. Initializes with a submission
2. Has a broadcast_update method
3. Calls Turbo::StreamsChannel.broadcast_replace_to with the right parameters
4. Also broadcasts to the parent grading task
After writing and seeing the test fail:
CopyNow implement the Broadcasters::StudentSubmissionBroadcaster class. The implementation should:
1. Store the submission from initialization
2. Implement broadcast_update to call Turbo StreamsChannel
3. Use the right target and partial
4. Also update the parent grading task
After implementation:
CopyLet's refactor the broadcaster. Consider:
1. Improving the target naming
2. Adding more broadcast options
3. Enhancing error handling
4. Ensuring efficient operation

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 19: Grading Task Broadcaster
CopyLet's implement the broadcaster for grading tasks. First, write a test for Broadcasters::GradingTaskBroadcaster that:
1. Initializes with a grading task
2. Has a broadcast_update method
3. Broadcasts both the task and progress updates
4. Uses the right targets and partials
After writing and seeing the test fail:
CopyNow implement the Broadcasters::GradingTaskBroadcaster class. The implementation should:
1. Store the grading task from initialization
2. Implement broadcast_update to broadcast multiple updates
3. Use descriptive targets
4. Handle potential errors
After implementation:
CopyLet's refactor the broadcaster. Consider:
1. Improving the broadcasting strategy
2. Adding more broadcast types
3. Enhancing error handling
4. Ensuring efficient operation

Then run Rubocop to ensure it meets Ruby style guidelines.
Phase 6: Google Drive Integration
Prompt 20: Google Drive File Service
CopyLet's implement the Google Drive file service. First, write a test for GoogleDrive::FileService that:
1. Has list_files and fetch_document_content methods
2. Uses GoogleDrive::Client for API interactions
3. Handles folder and file IDs correctly
4. Returns properly formatted results
After writing and seeing the test fail:
CopyNow implement the GoogleDrive::FileService class. The implementation should:
1. Create a client instance
2. Call the appropriate client methods
3. Format the results correctly
4. Handle potential errors
After implementation:
CopyLet's refactor the file service. Consider:
1. Improving error handling
2. Adding caching for common operations
3. Enhancing logging
4. Ensuring efficient client usage

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 21: Google Drive Client
CopyLet's implement the Google Drive client. First, write a test for GoogleDrive::Client that:
1. Can be initialized with optional credentials
2. Has list_files and export_file methods
3. Uses Google::Apis::DriveV3::DriveService
4. Handles API parameters correctly
5. Returns properly formatted results
After writing and seeing the test fail:
CopyNow implement the GoogleDrive::Client class. The implementation should:
1. Initialize a drive service with the provided credentials
2. Implement list_files to query files in a folder
3. Implement export_file to get document content
4. Handle API errors appropriately
5. Return well-formatted responses
After implementation:
CopyLet's refactor the client. Consider:
1. Improving credential handling
2. Adding token refresh logic
3. Enhancing error handling
4. Ensuring efficient API usage

Then run Rubocop to ensure it meets Ruby style guidelines.
Phase 7: Controllers and Views
Prompt 22: Feature Flags Controller
CopyLet's implement the admin feature flags controller. First, write a test for Admin::FeatureFlagsController that:
1. Checks for authentication and authorization
2. Has an index action showing all flags
3. Has a toggle action that enables/disables flags
4. Redirects after toggle with appropriate messages
5. Logs flag changes
After writing and seeing the test fail:
CopyNow implement the Admin::FeatureFlagsController class. The implementation should:
1. Inherit from AdminController
2. Check authentication
3. Implement index to show all flags
4. Implement toggle to change flag state
5. Use the logger for tracking changes
6. Add appropriate flash messages
After implementation:
CopyLet's refactor the controller. Consider:
1. Improving authorization checks
2. Enhancing flash messages
3. Adding more detailed logging
4. Ensuring efficient queries

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 23: Grading Tasks Controller
CopyLet's implement the grading tasks controller. First, write a test for GradingTasksController that:
1. Checks for authentication
2. Has new, create, and show actions
3. Uses the GradingTasks::Create command in the create action
4. Enqueues ProcessGradingTaskJob on successful creation
5. Shows appropriate messages
6. Handles errors gracefully
After writing and seeing the test fail:
CopyNow implement the GradingTasksController class. The implementation should:
1. Check authentication
2. Implement new to show the form
3. Implement create using the command pattern
4. Enqueue the job on success
5. Implement show for real-time updates
6. Handle errors with appropriate messages
After implementation:
CopyLet's refactor the controller. Consider:
1. Improving error handling
2. Enhancing user feedback
3. Adding more detailed logging
4. Optimizing queries

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 24: Student Submissions Controller
CopyLet's implement the student submissions controller. First, write a test for StudentSubmissionsController that:
1. Checks for authentication and authorization
2. Has a retry action for failed submissions
3. Changes status and enqueues the job
4. Supports both HTML and Turbo Stream responses
5. Shows appropriate messages
After writing and seeing the test fail:
CopyNow implement the StudentSubmissionsController class. The implementation should:
1. Check authentication and authorization
2. Implement retry for failed submissions
3. Update status and enqueue the job
4. Respond to different formats
5. Show appropriate messages
After implementation:
CopyLet's refactor the controller. Consider:
1. Improving authorization checks
2. Enhancing response formats
3. Adding more detailed logging
4. Ensuring efficient queries

Then run Rubocop to ensure it meets Ruby style guidelines.
Phase 8: System Integration
Prompt 25: Feature Flag Initializer
CopyLet's implement the feature flags initializer. First, write a test that:
1. Ensures all predefined flags exist in the database
2. Doesn't duplicate existing flags
3. Updates descriptions of existing flags
4. Calls FeatureFlags::FlagService.ensure_flags_exist
After writing and seeing the test fail:
CopyNow implement the feature flags initializer. The implementation should:
1. Run after application initialization
2. Call FeatureFlags::FlagService.ensure_flags_exist
3. Handle potential errors
4. Not block application startup
After implementation:
CopyLet's refactor the initializer. Consider:
1. Improving error handling
2. Adding logging
3. Making initialization more efficient
4. Ensuring it works in all environments

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 26: LLM Grading Service
CopyLet's implement the LLM grading service. First, write a test for LLM::GradingService that:
1. Initializes with content, prompt, and rubric
2. Uses the configuration to determine grading approach
3. Uses the client factory to get the right client
4. Logs the grading operation
5. Returns structured grading results
After writing and seeing the test fail:
CopyNow implement the LLM::GradingService class. The implementation should:
1. Store the inputs from initialization
2. Use the configuration to check features
3. Implement single and two-pass grading approaches
4. Generate appropriate prompts
5. Use the client and parser
6. Log operations and results
After implementation:
CopyLet's refactor the grading service. Consider:
1. Improving prompt generation
2. Enhancing result handling
3. Optimizing token usage
4. Adding more detailed logging

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 27: Student Submission Partial
CopyLet's implement the student submission partial. First, write a test that:
1. Renders the student submission details
2. Shows the current status
3. Displays the grade when completed
4. Shows action buttons based on status
5. Links to the graded document when available
After writing and seeing the test fail:
CopyNow implement the _student_submission.html.erb partial. The implementation should:
1. Show the submission name
2. Display the current status with appropriate styling
3. Show the grade for completed submissions
4. Include action buttons based on status
5. Link to the graded document when available
After implementation:
CopyLet's refactor the partial. Consider:
1. Improving the HTML structure
2. Enhancing accessibility
3. Optimizing for different statuses
4. Making the display more informative

Then check for any HTML/CSS linting issues.
Prompt 28: Grading Task Show View
CopyLet's implement the grading task show view. First, write a test that:
1. Sets up a Turbo Stream for updates
2. Shows task details and status
3. Displays a progress bar
4. Lists all student submissions
5. Updates dynamically as submissions are processed
After writing and seeing the test fail:
CopyNow implement the grading_tasks/show.html.erb view. The implementation should:
1. Set up the Turbo Stream
2. Show task details
3. Include a progress bar
4. List all submissions using the partial
5. Support dynamic updates
After implementation:
CopyLet's refactor the view. Consider:
1. Improving the layout
2. Enhancing visual feedback
3. Adding more status information
4. Optimizing for different screen sizes

Then check for any HTML/CSS linting issues.
Final System Integration
Prompt 29: Application Job Base Class
CopyLet's implement the application job base class. First, write a test that:
1. Ensures logging is set up for all jobs
2. Verifies retry configuration is available
3. Checks that around_perform callbacks work
4. Ensures job execution is tracked
After writing and seeing the test fail:
CopyNow implement the ApplicationJob class. The implementation should:
1. Inherit from ActiveJob::Base
2. Set up logging around job execution
3. Include common retry configuration
4. Track job execution timing
After implementation:
CopyLet's refactor the application job. Consider:
1. Improving logging
2. Enhancing retry strategies
3. Adding more execution context
4. Ensuring efficient operation

Then run Rubocop to ensure it meets Ruby style guidelines.
Prompt 30: System Integration Test
CopyLet's write a system integration test that:
1. Signs in a user
2. Creates a new grading task
3. Mocks Google Drive API calls
4. Verifies the grading task show page updates
5. Checks that submissions are processed
6. Confirms the final state is correct
After writing and seeing the test fail:
CopyNow set up the necessary mocks and fixtures for the integration test:
1. Create user and session fixtures
2. Mock Google Drive API responses
3. Mock LLM API responses
4. Simulate job execution
5. Check for correct UI updates
After implementation:
CopyLet's refactor the integration test. Consider:
1. Improving test organization
2. Enhancing assertions
3. Making mocks more realistic
4. Ensuring the test is stable

Then run Rubocop to ensure it meets Ruby style guidelines.