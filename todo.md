# GradeBot Implementation Checklist

## Phase 1: Core Infrastructure

### Project Setup
- [x] Create new Rails 8 application
- [x] Configure SQLite database
- [x] Set up Minitest
- [x] Install and configure Tailwind CSS
- [x] Set up Git repository
- [x] Create initial README.md
- [x] Configure CI/CD pipeline
- [x] Configure Google OAuth2

### User Model
- [x] Generate User model with required fields
- [x] Write model specs
  - [x] Email validation
  - [x] OAuth token handling
  - [x] Association tests
- [x] Implement model
- [x] Add necessary indexes
- [x] Create factories
- [x] Test OAuth-related methods
- [x] Document model

### GradingJob Model
- [ ] Generate GradingJob model
- [ ] Write model specs
  - [ ] Status enum tests
  - [ ] Validation tests
  - [ ] Association tests
  - [ ] Scope tests
- [ ] Implement status transitions
- [ ] Add callback hooks
- [ ] Create factories
- [ ] Add helper methods
- [ ] Document model and methods

### StudentSubmission Model
- [ ] Generate StudentSubmission model
- [ ] Write model specs
  - [ ] Validation tests
  - [ ] Status management tests
  - [ ] Grade calculation tests
  - [ ] Association tests
- [ ] Implement model
- [ ] Create factories
- [ ] Add helper methods
- [ ] Document model

## Phase 2: Google Integration

### Google OAuth
- [x] Register application with Google
- [x] Configure OAuth credentials
- [x] Set up environment variables with Kamal secrets
- [x] Configure OmniAuth with Google OAuth2
- [x] Write OAuth controller specs
- [x] Implement OAuth controller
- [x] Add token refresh logic
- [x] Test error scenarios
- [x] Document OAuth setup

### Drive Picker
- [x] Create Drive Picker Stimulus controller
- [x] Implement Google Picker API
- [x] Add folder selection logic
- [x] Create picker UI
- [x] Implement file counting
- [x] Add loading states
- [x] Basic error handling

### Grading Job Page
- [ ] Implement folder validation
- [ ] Add well designed UI components to represent folder structure
- [ ] Add validation if folder contains too many files or files are not google docs.
- [ ] Add an input field for the assignment text. 
- [ ] Add an input field for the rubric text.
- [ ] Allow user to submit folder with assignment and rubric. This will create a grading job.
- [ ] After the user creates a grading job, they should be redirected to the grading job page which shows that the job is "processing". 

## Phase 3: Job Processing

### Solid Queue Setup
- [ ] Install Solid Queue
- [ ] Configure queues
- [ ] Set up job monitoring
- [ ] Create base job class
- [ ] Write job specs
- [ ] Implement retry logic
- [ ] Add error handling
- [ ] Document job system

### Document Processing
- [ ] Create DocumentProcessingJob
- [ ] Write job specs
- [ ] Implement Google Drive API calls
- [ ] Add document parsing
- [ ] Create record management
- [ ] Implement error handling
- [ ] Add retry logic
- [ ] Document processing flow

## Phase 4: LLM Integration

### LLM Service
- [ ] Create LLMService class
- [ ] Configure API client
- [ ] Write service specs
- [ ] Create prompt templates
- [ ] Implement rate limiting
- [ ] Add retry logic
- [ ] Create error handling
- [ ] Document service

### Grading Logic
- [ ] Create GradingService class
- [ ] Write service specs
- [ ] Implement rubric parser
- [ ] Create prompt generator
- [ ] Add response processor
- [ ] Implement grade calculator
- [ ] Add error handling
- [ ] Document grading system

## Phase 5: Frontend

### Basic UI
- [x] Create layout templates
- [x] Design landing page
- [ ] Build submission form
- [ ] Add progress display
- [ ] Create results view
- [x] Write view specs
- [x] Add error displays
- [ ] Document UI components

### Progress Tracking
- [ ] Set up Turbo Streams
- [ ] Create progress controller
- [ ] Write controller specs
- [ ] Implement status updates
- [ ] Add progress calculations
- [ ] Create error handling
- [ ] Document progress system

## Phase 6: Output Generation

### Report Generation
- [ ] Create ReportGenerator class
- [ ] Write generator specs
- [ ] Implement feedback generation
- [ ] Add class summary creation
- [ ] Create spreadsheet formatter
- [ ] Add error handling
- [ ] Document report system

### Email Notifications
- [ ] Configure Action Mailer
- [ ] Create email templates
- [ ] Write mailer specs
- [ ] Implement delivery logic
- [ ] Add error handling
- [ ] Test all email scenarios
- [ ] Document notification system

## Phase 7: Integration and Polish

### System Integration
- [ ] Create JobCoordinator class
- [ ] Write coordinator specs
- [ ] Implement service coordination
- [ ] Add flow management
- [ ] Create error recovery
- [ ] Implement status tracking
- [ ] Write integration tests
- [ ] Document system flow

### UI Polish
- [ ] Add loading states
- [ ] Improve error messages
- [ ] Implement retry UI
- [ ] Polish transitions
- [ ] Write UI tests
- [ ] Test error scenarios
- [ ] Document UI features

## Final Steps

### Testing
- [ ] Run full test suite
- [ ] Check test coverage
- [ ] Performance testing
- [ ] Security testing
- [ ] Load testing
- [ ] Document test coverage

### Documentation
- [ ] Update README
- [ ] Create setup guide
- [ ] Write API documentation
- [ ] Add usage examples
- [ ] Document deployment process
- [ ] Create troubleshooting guide

### Deployment
- [ ] Set up staging environment
- [ ] Deploy to staging
- [ ] Run staging tests
- [ ] Configure production environment
- [ ] Create deployment scripts
- [ ] Document deployment process

### Performance
- [ ] Run performance profiling
- [ ] Optimize slow queries
- [ ] Add caching where needed
- [ ] Configure background jobs
- [ ] Document performance baselines

### Security
- [ ] Run security audit
- [ ] Check OAuth implementation
- [ ] Review file access security
- [ ] Test error handling
- [ ] Document security measures

Note: Check off items as they are completed. This list may need to be updated as implementation details are refined.