# Technical Specification: Grade Bot (grade-bot.ai)
*Automated Assignment Grading System for Teachers*

## 1. System Overview
The Automated Assignment Grading System is a web-based tool that enables teachers to automatically grade and provide feedback on student assignments using LLM technology. The system processes Google Docs assignments, generates individualized feedback, creates detailed grade reports, and provides class-wide analysis.

## 2. Technical Requirements

### 2.1 Frontend Requirements
- Single page web application
- Google Drive folder selector integration
- Text input fields for assignment prompt and rubric
- Progress indicator for async processing
- Error message display capability
- Mobile-responsive design
- No authentication system (relies on Google OAuth)

### 2.2 Backend Requirements
- Async job processing system
- Google Drive API integration
- LLM integration
- Email notification system
- File processing pipeline
- SQLite database for job tracking and user management
- Solid Queue for job processing
- Solid Cache for caching layer
- Secure credential storage

### 2.3 LLM Integration Requirements

- Two-pass grading system:
  - Initial grading pass
  - Consistency check pass

- Micro-batch processing (5 assignments per batch)
- Cost control mechanisms
- Fallback strategies for failures
- Monitoring and analytics
- Prompt management system for easy prompt iteration
- Token usage optimization

### 2.4 Integration Requirements

- Google Drive API
  - Read access to selected file
  - Write access for creating graded copy
  - Document content extraction
- LLM API with cost tracking
- SMTP/Email service for notifications

## 3. Detailed Functionality

### 3.1 Google Drive Integration
- OAuth 2.0 authentication flow
- Folder selection interface
- Permission scopes required:
  - drive.file (read/write access to selected files)
  - drive.metadata.readonly (file listing)

#### 3.1.1 Folder Picker Implementation
1. **Test Infrastructure**
   - System tests for picker modal interaction
   - Mock Google Picker API responses
   - Test folder selection workflow

2. **API Configuration**
   - Configure required OAuth scopes:
     - drive.readonly (view files)
     - drive.file (access selected files)
   - Load Google Picker API scripts
   - Initialize API client

3. **Frontend Components**
   - Stimulus controller for picker interaction
   - Loading states and error handling
   - Selected folder display
   - Folder validation

4. **Backend Infrastructure**
   - Database fields for folder tracking
   - API endpoint for folder selection
   - Folder permission validation
   - Token refresh handling

5. **Error Handling**
   - API loading failures
   - Picker initialization errors
   - Selection cancellation
   - Permission issues
   - Token expiration

6. **Performance Optimization**
   - Folder metadata caching
   - Minimize API calls
   - Handle large folder structures

### 3.2 Document Processing
- Input validation:
  - Verify all files are Google Docs
  - Check file accessibility
  - Validate document content exists
- Document copying:
  - Create copies with prefix "Graded -"
  - Maintain original document structure
  - Write feedback to copied documents
- Text extraction:
  - Support documents from 1 paragraph to 5 pages
  - Strip formatting
  - Extract plain text content

### 3.3 Grading System
- Input handling:
  - Free-form text field for assignment prompt
  - Free-form text field for rubric (supports pasted tables)
  - Maximum assignment length validation
- Cost Management:
  - Per-assignment cost ceiling ($2-3)
  - Batch cost estimation
  - Usage tracking and reporting
- LLM Processing:
  - Parse rubric structure
  - Grade according to criteria
  - Generate constructive feedback
  - Create class-wide analysis
- Initial grading pass:
  - Rubric-based scoring
  - Evidence-based feedback
  - Confidence scoring
- Consistency check pass:
  - Cross-assignment comparison
  - Anomaly detection
  - Grade adjustment recommendations
- Fallback Strategy:
  - Full grading with detailed feedback
  - Basic grading with minimal feedback
  - Manual review flagging
- Error Handling:
  - Maximum 3 retries per assignment
  - Graceful degradation of service
  - Clear error reporting
- Performance Optimization:
  - Feedback pattern caching
  - Token usage optimization
  - Micro-batch processing

### 3.4 Prompt Management
- Base prompt templates:
  - Initial grading prompt
  - Consistency check prompt
  - Fallback grading prompt
- Dynamic prompt construction:
  - Assignment context injection
  - Rubric parsing and formatting
  - Student submission preparation
- Response Format:
```json
{
  "criteria_grades": [
    {
      "criterion": "string",
      "score": number,
      "evidence": "string",
      "feedback": "string"
    }
  ],
  "overall_score": number,
  "feedback": "string",
  "confidence_score": number
}
```

### 3.5 Output Generation
- Spreadsheet creation:
  - One row per student
  - Columns for each rubric criterion
  - Score columns
  - Comment columns
  - Summary feedback column
- Class report generation:
  - Aggregate performance analysis
  - Common strengths/weaknesses
  - Statistical outliers (high/low performers)
  - Next steps recommendations
- Individual feedback:
  - Positive aspects first
  - 1-2 specific improvement areas
  - Motivational, constructive tone

### 3.6 Monitoring and Analytics
- Cost Metrics:
  - Cost per assignment
  - Processing costs
  - Monthly trends
- Performance Metrics:
  - Processing time
  - Retry rates
  - Confidence scores
  - Error rates
- Quality Metrics:
  - Teacher satisfaction rate
  - Feedback effectiveness
  - Grading consistency
  - Prompt performance

## 4. Privacy and Security

### 4.1 Data Handling
- No persistent storage of student data
- PII redaction in all generated reports
- Secure file processing
- Temporary storage only during processing
- Automatic cleanup after delivery

### 4.2 Session Management
- Persistent session storage in database
- Session tracking with user_id, IP address, and user agent
- Session-based authentication for all requests
- Automatic session cleanup for inactive users
- Multiple concurrent sessions support per user

### 4.3 Error Handling
- Validation errors:
  - Clear error messages
  - Processing stops on first error
  - File-specific error reporting
- Processing errors:
  - Graceful failure handling
  - Error notification to teacher
  - Cleanup of partial results

## 5. User Flow

1. Landing Page
   - Google Drive button
   - Clear instructions

2. Folder Selection
   - Google Drive picker interface
   - Folder-only selection

3. Assignment Details
   - Prompt input field
   - Rubric input field
   - Submit button
   - Clear validation feedback

4. Processing
   - Progress indicator
   - Percentage complete
   - Cancel option

5. Completion
   - Email notification
   - Download links for reports
   - Clear success/error messaging

## 6. Testing Plan

### 6.1 Unit Testing
- Document processing functions
- Rubric parsing
- Grade calculation
- Cost estimation
- PII detection/redaction
- Error handling

### 6.2 Integration Testing
- Google Drive API integration
- LLM API integration
- Email notification system
- Progress tracking
- File handling pipeline

### 6.3 End-to-End Testing
- Complete user flow
- Various document sizes
- Different rubric formats
- Error conditions
- Performance testing

### 6.4 Test Cases
- Empty documents
- Invalid file types
- Large folders (should error before processing)
- Various text lengths
- Different rubric complexities
- Edge cases in student naming
- Permission scenarios
- Network interruptions
- LLM interruptions 

## 7. Performance Requirements

- Processing time: < 2 minutes for 30 student assignments
- Concurrent processing: Support for multiple teachers
- File size limits: Up to 2000 words
- Folder limits: Up to 30 documents per batch
- Response time: < 500ms for UI interactions

## 8. Development Phases

### Phase 1: MVP
1. Basic Google Drive integration
2. Document processing pipeline
3. Simple grading system
4. Basic report generation
5. Email notifications

### Phase 2: Enhancements (Future)
1. Two pass grading system 
2. Advanced prompt managemetn 
3. Performance optimization
4. Price per job

### Phase 3: Scale and Analytics (Future)
1. Advanced analytics 
2. Subscription plan 

## 9. Stimulus Controllers

### drive_picker_controller.js
```javascript
// app/javascript/controllers/drive_picker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["folderInput", "folderName"]
  
  connect() {
    // Initialize Google Picker API
  }
  
  showPicker() {
    // Show Google Drive folder picker
  }
  
  folderSelected(folderId, folderName) {
    // Update form with selected folder
  }
}
```

### progress_controller.js
```javascript
// app/javascript/controllers/progress_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "percentage"]
  
  connect() {
    this.pollStatus()
  }
  
  pollStatus() {
    // Poll job status endpoint and update progress
  }
}
```

### rubric_controller.js
```javascript
// app/javascript/controllers/rubric_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]
  
  previewRubric() {
    // Show formatted preview of pasted rubric
  }
}
```

## 10. Technical Stack Recommendations

### Frontend
- Hotwire (Turbo + Stimulus)
- Google Drive Picker API
- Tailwind CSS
- Rails view partials for reusable UI elements

### Backend
- Ruby on Rails 8
- Google Drive API Client (google-api-client gem)
- OpenAI/Anthropic API (ruby client)
- Solid Queue for background jobs
- Solid Cache for caching
- Action Mailer for emails
- Active Storage for temporary file handling
- Devise for authentication (Google OAuth)

### Infrastructure
- Deploy with Kamal to Google Cloud Compute 
- Solid Queue for background job processing
- Solid Cache for caching layer
- SQLite for database
- Rails credentials for secure key management
- Rack::Attack for rate limiting

### Database Schema

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :grading_jobs
  
  # Columns:
  # - email: string
  # - google_uid: string
  # - access_token: string
  # - refresh_token: string
  # - token_expires_at: datetime
  # - last_signed_in_at: datetime
  # - stripe_customer_id: string
  # - timestamps
end

# app/models/grading_job.rb
class GradingJob < ApplicationRecord
  belongs_to :user
  has_many :student_submissions
  has_one :class_report
  
  # Columns:
  # - status: string (enum: pending, processing, completed, failed)
  # - folder_id: string
  # - assignment_prompt: text
  # - rubric: text
  # - error_message: text
  # - completed_at: datetime
  # - timestamps
end

# app/models/student_submission.rb
class StudentSubmission < ApplicationRecord
  belongs_to :grading_job
  has_many :criterion_grades
  
  # Columns:
  # - original_doc_id: string
  # - graded_doc_id: string
  # - overall_grade: decimal
  # - feedback: text
  # - status: string (enum: pending, processed, error)
  # - error_message: text
  # - timestamps
end

# app/models/criterion_grade.rb
class CriterionGrade < ApplicationRecord
  belongs_to :student_submission
  
  # Columns:
  # - criterion_name: string
  # - score: integer
  # - feedback: text
  # - timestamps
end

# app/models/class_report.rb
class ClassReport < ApplicationRecord
  belongs_to :grading_job
  
  # Columns:
  # - strengths: text[]
  # - weaknesses: text[]
  # - next_steps: text[]
  # - statistical_summary: jsonb
  # - timestamps
end
```

## 11. Cost Management

### 11.1 Cost Control Mechanisms
```ruby
module CostControl
  MAX_COST_PER_ASSIGNMENT = 3.0  # dollars
  MAX_TOKENS_PER_ASSIGNMENT = 1000
  
  def estimate_batch_cost(num_assignments)
    cost_per_assignment = {
      initial_grading: 0.02,
      consistency_check: 0.01
    }
    
    total_cost = (num_assignments * cost_per_assignment[:initial_grading]) +
                 (num_assignments / 5.0).ceil * cost_per_assignment[:consistency_check]
    
    # Add 20% buffer for retries
    total_cost * 1.2
  end
  
  def enforce_cost_limits(batch)
    estimated_cost = estimate_batch_cost(batch.size)
    raise CostLimitExceeded if estimated_cost > MAX_BATCH_COST
    
    batch.each do |assignment|
      truncate_to_token_limit(assignment)
    end
  end
end
```

### 11.2 Batch Processing Strategy
```ruby
module BatchProcessor
  MICRO_BATCH_SIZE = 5
  RETRY_LIMIT = 3
  
  def process_batch(assignments)
    enforce_cost_limits(assignments)
    
    assignments.each_slice(MICRO_BATCH_SIZE) do |micro_batch|
      process_micro_batch(micro_batch)
      sleep 2  # Rate limiting
    end
    
    run_consistency_check(assignments)
  end
  
  private
  
  def process_micro_batch(micro_batch)
    micro_batch.each do |assignment|
      with_retries(max_attempts: RETRY_LIMIT) do
        grade_with_fallbacks(assignment)
      end
    end
  end
end
```

### 11.3 Prompt Templates
```ruby
module PromptTemplates
  GRADING_PROMPT = """
  Role: You are an experienced teacher grading assignments.
  
  Context:
  - Assignment: #{assignment_prompt}
  - Rubric: #{rubric}
  - Maximum points: #{max_points}
  
  Instructions:
  1. Read the student submission carefully
  2. For each rubric criterion:
     - Assign points
     - Provide specific evidence from text
     - Give constructive feedback
  3. Ensure feedback is:
     - Specific to student's work
     - Actionable
     - Encouraging
  
  Student submission:
  #{submission_content}
  
  Format your response as JSON:
  {
    "criteria_grades": [...],
    "overall_score": number,
    "feedback": string,
    "confidence_score": number
  }
  """
  
  CONSISTENCY_CHECK_PROMPT = """
  Review these #{MICRO_BATCH_SIZE} graded assignments and check for consistency.
  Previous grades: #{previous_grades_json}
  
  For each assignment, indicate if the grade seems inconsistent with others and why.
  Provide specific examples of inconsistencies if found.
  """
end
```