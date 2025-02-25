# GradeBot Implementation Plan

## Overview

This implementation plan breaks down the GradeBot project into discrete, testable steps that build upon each other. Each step is designed to be implemented via test-driven development and includes specific prompts for code generation.

## Phase 1: Core Infrastructure

### Step 1: Project Setup and Basic Models
**Goal**: Set up the Rails project with initial testing infrastructure and core models

```
Create a new Rails application for GradeBot with the following requirements:
- Ruby on Rails 8
- SQLite database
- Minitest for testing
- Fixtures for test data
- Devise for authentication
- Stimulus for JavaScript
- Tailwind CSS for styling

Generate the initial User model with:
- email (string)
- google_uid (string)
- access_token (string)
- refresh_token (string)
- token_expires_at (datetime)
- timestamps

Create the Session model with:
- user_id (references users)
- ip_address (string)
- user_agent (string)
- timestamps
- index on user_id

Implement session management:
- Create sessions on successful authentication
- Track user sessions with IP and user agent
- Support multiple concurrent sessions
- Clean up expired sessions

Write comprehensive model tests for:
- Validations
- Associations
- OAuth-related methods

Implement the model and ensure all tests pass.
```

### Step 2: GradingTask Model
**Goal**: Implement the core grading job model with validations and state management

```
Create the GradingTask model with:
- status (enum: pending, processing, completed, failed)
- folder_id (string)
- assignment_prompt (text)
- rubric (text)
- error_message (text)
- completed_at (datetime)
- belongs_to :user association

Write tests for:
- All validations
- Status transitions
- Association with User
- Basic scope methods (pending, processing, etc.)
- Helper methods for status management

Implement the model ensuring:
- Proper enum configuration
- Status transition validations
- Callback hooks for status changes
- Association setup
```

### Step 3: StudentSubmission Model
**Goal**: Add the submission model to track individual assignments

```
Create the StudentSubmission model with:
- original_doc_id (string)
- graded_doc_id (string)
- overall_grade (decimal)
- feedback (text)
- status (string, enum: pending, processed, error)
- error_message (text)
- belongs_to :grading_task association

Write tests for:
- Validations
- Status management
- Association with GradingTask
- Grade calculations
- Error handling methods

Implement the model with:
- Proper validations
- Status transition logic
- Grade calculation methods
- Error handling capabilities
```

## Phase 2: Google Drive Integration

### Step 4: Google OAuth Setup
**Goal**: Implement Google OAuth authentication

```
Set up Google OAuth authentication:
- Configure Devise with OmniAuth Google
- Add necessary environment variables
- Create OAuth callback controller
- Implement sign in/out functionality

Write tests for:
- OAuth callback handling
- Token refresh logic
- Session management
- Error scenarios

Implement:
- OmniAuth strategy configuration
- Token management
- User creation/update from OAuth data
- Basic error handling
```

### Step 5: Drive Picker Controller
**Goal**: Create the Google Drive folder picker interface

```
Create a Stimulus controller for the Google Drive picker:
- Initialize Google Picker API
- Handle folder selection
- Update form with selected folder
- Show loading states

Write tests for:
- Controller initialization
- Folder selection handling
- Form updates
- Error states

Implement:
- Picker initialization
- Folder selection logic
- Form updates
- Error handling
```

## Phase 3: Job Processing Infrastructure

### Step 6: Background Job Setup
**Goal**: Set up Solid Queue for background processing

```
Configure Solid Queue:
- Add necessary gems
- Set up configuration
- Create base job class
- Implement job monitoring

Write tests for:
- Job queueing
- Job execution
- Error handling
- Retry logic

Implement:
- Queue configuration
- Base job class
- Error handling
- Monitoring setup
```

### Step 7: Document Processing Job
**Goal**: Create job for processing Google Doc submissions

```
Create DocumentProcessingJob:
- Fetch document content from Google Drive
- Parse document content
- Create StudentSubmission records
- Handle errors and retries

Write tests for:
- Document fetching
- Content parsing
- Record creation
- Error scenarios

Implement:
- Google Drive API integration
- Document parsing
- Record creation
- Error handling
```

## Phase 4: LLM Integration

### Step 8: LLM Service Setup
**Goal**: Create service for LLM interactions

```
Create LLMService:
- Configure API client
- Implement prompt templates
- Add retry logic
- Handle rate limiting

Write tests for:
- API interactions
- Prompt generation
- Response parsing
- Error handling

Implement:
- API client setup
- Prompt management
- Response handling
- Error recovery
```

### Step 9: Grading Logic
**Goal**: Implement core grading functionality

```
Create GradingService:
- Parse rubric structure
- Generate grading prompts
- Process LLM responses
- Update submission records

Write tests for:
- Rubric parsing
- Prompt generation
- Response processing
- Grade calculation

Implement:
- Rubric parser
- Prompt generator
- Response processor
- Grade calculator
```

## Phase 5: Frontend Implementation

### Step 10: Basic UI
**Goal**: Create initial user interface

```
Create basic UI components:
- Landing page
- Job submission form
- Progress tracking
- Results display

Write tests for:
- Page rendering
- Form submission
- Progress updates
- Results display

Implement:
- Page layouts
- Form components
- Progress display
- Results view
```

### Step 11: Progress Tracking
**Goal**: Add real-time progress updates

```
Create progress tracking system:
- Add Turbo Streams
- Create progress controller
- Implement status updates
- Add error handling

Write tests for:
- Stream updates
- Progress calculations
- Status changes
- Error displays

Implement:
- Stream configuration
- Progress updates
- Status management
- Error handling
```

## Phase 6: Output Generation

### Step 12: Report Generation
**Goal**: Implement report generation system

```
Create ReportGenerator:
- Generate individual feedback
- Create class summary
- Format spreadsheet output
- Handle error cases

Write tests for:
- Feedback generation
- Summary creation
- Spreadsheet formatting
- Error handling

Implement:
- Feedback generator
- Summary creator
- Spreadsheet formatter
- Error handler
```

### Step 13: Email Notifications
**Goal**: Add email notification system

```
Create NotificationService:
- Configure Action Mailer
- Create email templates
- Add delivery logic
- Handle errors

Write tests for:
- Email generation
- Delivery timing
- Content formatting
- Error scenarios

Implement:
- Mailer setup
- Template creation
- Delivery logic
- Error handling
```

## Phase 7: Integration and Polish

### Step 14: System Integration
**Goal**: Wire all components together

```
Create JobCoordinator:
- Coordinate all services
- Manage job flow
- Handle error recovery
- Provide status updates

Write tests for:
- End-to-end flow
- Error recovery
- Status management
- Performance metrics

Implement:
- Service coordination
- Flow management
- Error recovery
- Status tracking
```

### Step 15: UI Polish and Error Handling
**Goal**: Improve user experience and error handling

```
Enhance UI and error handling:
- Add loading states
- Improve error messages
- Add retry capabilities
- Polish transitions

Write tests for:
- Loading states
- Error displays
- Retry functionality
- UI transitions

Implement:
- Loading indicators
- Error displays
- Retry mechanisms
- Transition effects
```

## Testing Strategy

Each prompt includes specific testing requirements. General testing principles:

1. Unit tests for all models and services
2. Integration tests for controllers and jobs
3. System tests for end-to-end flows
4. Performance tests for critical paths
5. Security tests for OAuth and file access

## Implementation Notes

1. Each step should be completed with full test coverage before moving to the next
2. All code should be reviewed for security implications
3. Performance should be monitored throughout
4. Documentation should be updated with each step

## Deployment Strategy

1. Set up staging environment after Step 3
2. Deploy to staging after each major phase
3. Run performance tests in staging
4. Document deployment process
