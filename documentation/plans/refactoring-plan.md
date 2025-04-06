# GradeBot Refactoring Plan

## Executive Summary

This plan outlines a comprehensive refactoring of GradeBot's grading task functionality to improve maintainability, reliability, and user experience.

### Objectives
1. Extract core models for better separation of concerns
2. Centralize processing with a single orchestration service
3. Standardize state management and transitions
4. Implement consistent real-time UI updates

### Key Components Overview

| Component | Current Issue | Proposed Solution | Benefits |
|-----------|---------------|-------------------|----------|
| Data Model | Embedded prompts/rubrics in grading tasks | Separate tables with clear relationships | Clearer data ownership, better validation |
| Process Flow | Scattered job coordination | Single orchestration service | Simplified workflow, easier maintenance |
| State Management | Inconsistent patterns | Standardized transitions | Improved reliability, predictable behavior |
| UI Updates | Mixed approaches | Centralized broadcast service | Consistent user experience, reduced code duplication |

## Current State Analysis

### Issues to Address

1. **Data Model**
   - Prompts and rubrics embedded in grading tasks
   - Unclear ownership of data and behavior
   - Missing validations and constraints

2. **Process Flow**
   - Scattered job coordination
   - Inconsistent state management
   - Complex error recovery

3. **User Interface**
   - Inconsistent update patterns
   - Poor progress visibility
   - Mixed real-time update approaches

## Implementation Plan

### 1. Foundation (Database & Models)

#### Database Schema Changes

1. **Assignment Prompts Table**
```ruby
# db/migrate/YYYYMMDDHHMMSS_create_assignment_prompts.rb
class CreateAssignmentPrompts < ActiveRecord::Migration[7.1]
  def change
    create_table :assignment_prompts do |t|
      t.references :grading_task, null: false, foreign_key: true
      t.text :original_text, null: false
      t.text :formatted_html
      t.string :status, default: 'pending'
      t.timestamps

      t.index :status  # For efficient status filtering
    end
  end
end
```

2. **Grading Rubrics Table**
```ruby
# db/migrate/YYYYMMDDHHMMSS_create_grading_rubrics.rb
class CreateGradingRubrics < ActiveRecord::Migration[7.1]
  def change
    create_table :grading_rubrics do |t|
      t.references :grading_task, null: false, foreign_key: true
      t.text :original_text, null: false
      t.text :formatted_html
      t.string :status, default: 'pending'
      t.timestamps

      t.index :status  # For efficient status filtering
    end
  end
end
```

3. **Data Migration**
```ruby
# db/migrate/YYYYMMDDHHMMSS_extract_prompt_and_rubric_from_grading_tasks.rb
class ExtractPromptAndRubricFromGradingTasks < ActiveRecord::Migration[7.1]
  def up
    # Wrap in transaction for atomic updates
    ActiveRecord::Base.transaction do
      GradingTask.find_each do |task|
        # Create assignment prompt
        task.create_assignment_prompt!(
          original_text: task.assignment_prompt_text,
          formatted_html: task.formatted_assignment_prompt,
          status: map_prompt_status(task.status)
        )

        # Create grading rubric
        task.create_grading_rubric!(
          original_text: task.grading_rubric_text,
          formatted_html: task.formatted_grading_rubric,
          status: map_rubric_status(task.status)
        )
      end

      # Remove old columns after successful migration
      remove_columns :grading_tasks,
        :assignment_prompt_text,
        :formatted_assignment_prompt,
        :grading_rubric_text,
        :formatted_grading_rubric
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def map_prompt_status(task_status)
    case task_status
    when 'created' then 'pending'
    when 'assignment_validated' then 'validated'
    when 'assignment_failed' then 'failed'
    else 'pending'
    end
  end

  def map_rubric_status(task_status)
    case task_status
    when 'rubric_processing' then 'processing'
    when 'rubric_processed' then 'validated'
    else 'pending'
    end
  end
end
```

#### Domain Models

1. **Assignment Prompt**
```ruby
# app/models/assignment_prompt.rb
class AssignmentPrompt < ApplicationRecord
  # Associations
  belongs_to :grading_task

  # Validations
  validates :original_text, presence: true
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }

  # Constants
  VALID_STATUSES = %w[pending processing validated failed].freeze

  # Callbacks
  after_update_commit :broadcast_update

  # Scopes
  scope :validated, -> { where(status: 'validated') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }

  private

  def broadcast_update
    BroadcastService.update(self)
  end
end
```

2. **Grading Rubric**
```ruby
# app/models/grading_rubric.rb
class GradingRubric < ApplicationRecord
  # Associations
  belongs_to :grading_task

  # Validations
  validates :original_text, presence: true
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }

  # Constants
  VALID_STATUSES = %w[pending processing validated failed].freeze

  # Callbacks
  after_update_commit :broadcast_update

  # Scopes
  scope :validated, -> { where(status: 'validated') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }

  private

  def broadcast_update
    BroadcastService.update(self)
  end
end
```

3. **Grading Task**
```ruby
# app/models/grading_task.rb
class GradingTask < ApplicationRecord
  # Associations
  belongs_to :user
  has_one :assignment_prompt, dependent: :destroy
  has_one :grading_rubric, dependent: :destroy
  has_many :student_submissions, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }

  # Constants
  VALID_STATUSES = %w[pending processing completed failed].freeze

  # Callbacks
  after_update_commit :broadcast_update

  # Scopes
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :in_progress, -> { where(status: %w[pending processing]) }

  def progress_percentage
    return 0 if student_submissions.none?
    (student_submissions.graded.count.to_f / student_submissions.count * 100).round
  end

  private

  def broadcast_update
    BroadcastService.update(self)
  end
end
```

### 2. Core Services (Business Logic)

#### State Transition Service
```ruby
# app/services/transition_state_service.rb
class TransitionStateService
  def self.transition(record:, to_state:)
    new(record, to_state).transition
  end

  def initialize(record, to_state)
    @record = record
    @to_state = to_state
  end

  def transition
    return false unless valid_transition?

    ApplicationRecord.transaction do
      @record.update!(status: @to_state)
      publish_transition_event
      broadcast_update
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def valid_transition?
    @record.class.valid_transitions[@record.status.to_sym]&.include?(@to_state.to_sym)
  end

  def publish_transition_event
    event_name = "#{@record.class.name.underscore}.#{@to_state}"
    EventPublisher.publish(event_name, record: @record)
  end

  def broadcast_update
    BroadcastService.update(@record)
  end
end
```

#### Orchestration Service
```ruby
# app/services/process_grading_task_service.rb
class ProcessGradingTaskService
  Error = Class.new(StandardError)

  def self.process(grading_task)
    new(grading_task).process
  end

  def initialize(grading_task)
    @grading_task = grading_task
    @prompt = grading_task.assignment_prompt
    @rubric = grading_task.grading_rubric
  end

  def process
    ActiveRecord::Base.transaction do
      @grading_task.update!(status: :processing)

      process_assignment_prompt
      return mark_failed('Assignment prompt processing failed') unless @prompt.validated?

      process_grading_rubric
      return mark_failed('Grading rubric processing failed') unless @rubric.validated?

      process_student_submissions
      @grading_task.update!(status: :completed)
    end
  rescue StandardError => e
    ErrorHandler.capture(e)
    mark_failed(e.message)
    raise Error, e.message
  end

  private

  def process_assignment_prompt
    Rails.logger.info "Processing assignment prompt for task #{@grading_task.id}"
    result = LlmService.process_prompt(@prompt)
    
    @prompt.update!(
      formatted_html: result.html,
      status: result.success? ? :validated : :failed
    )
  end

  def process_grading_rubric
    Rails.logger.info "Processing grading rubric for task #{@grading_task.id}"
    result = LlmService.process_rubric(@rubric)
    
    @rubric.update!(
      formatted_html: result.html,
      status: result.success? ? :validated : :failed
    )
  end

  def process_student_submissions
    Rails.logger.info "Queueing student submissions for task #{@grading_task.id}"
    @grading_task.student_submissions.find_each do |submission|
      GradeSubmissionJob.perform_later(submission.id)
    end
  end

  def mark_failed(reason)
    Rails.logger.error "Grading task #{@grading_task.id} failed: #{reason}"
    @grading_task.update!(status: :failed)
    false
  end
end
```

#### Event Publishing System
```ruby
# app/events/domain_events.rb
module DomainEvents
  module AssignmentPrompt
    VALIDATED = "assignment_prompt.validated"
    FAILED = "assignment_prompt.failed"
  end

  module GradingRubric
    VALIDATED = "grading_rubric.validated"
    FAILED = "grading_rubric.failed"
  end

  module GradingTask
    COMPLETED = "grading_task.completed"
    FAILED = "grading_task.failed"
  end
end

# app/services/event_publisher.rb
class EventPublisher
  def self.publish(event, payload = {})
    ActiveSupport::Notifications.instrument(event, payload)
    Rails.logger.info "Published event: #{event} with payload: #{payload.keys.join(', ')}"
  end
end
```

### 3. Execution Layer (Jobs & Controllers)

#### Background Jobs
```ruby
# app/jobs/process_grading_task_job.rb
class ProcessGradingTaskJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(grading_task_id)
    grading_task = GradingTask.find(grading_task_id)
    ProcessGradingTaskService.process(grading_task)
  rescue ProcessGradingTaskService::Error => e
    # Already handled by service
    Rails.logger.error "Failed to process grading task #{grading_task_id}: #{e.message}"
  end
end

# app/jobs/grade_submission_job.rb
class GradeSubmissionJob < ApplicationJob
  queue_as :grading
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(submission_id)
    submission = StudentSubmission.find(submission_id)
    
    Rails.logger.info "Grading submission #{submission_id}"
    result = LlmService.grade_submission(submission)
    
    submission.update!(
      feedback_html: result.feedback,
      grade: result.grade,
      status: result.success? ? :graded : :failed
    )
  rescue StandardError => e
    ErrorHandler.capture(e)
    Rails.logger.error "Failed to grade submission #{submission_id}: #{e.message}"
    submission.update!(status: :failed)
  end
end
```

#### Controller Updates
```ruby
# app/controllers/grading_tasks_controller.rb
class GradingTasksController < ApplicationController
  def create
    @grading_task = Current.session.user.grading_tasks.build(grading_task_params)
    
    if @grading_task.save
      GradingTask.transaction do
        # Create associated records
        @grading_task.create_assignment_prompt!(prompt_params)
        @grading_task.create_grading_rubric!(rubric_params)
        CreateStudentSubmissionsCommand.call(grading_task: @grading_task)

        # Start processing
        ProcessGradingTaskJob.perform_later(@grading_task.id)
        
        redirect_to @grading_task, notice: 'Grading task created'
      end
    else
      render :new
    end
  end

  private

  def grading_task_params
    params.require(:grading_task).permit(:title)
  end

  def prompt_params
    params.require(:grading_task).permit(:assignment_prompt_text).tap do |p|
      p[:original_text] = p.delete(:assignment_prompt_text)
    end
  end

  def rubric_params
    params.require(:grading_task).permit(:grading_rubric_text).tap do |p|
      p[:original_text] = p.delete(:grading_rubric_text)
    end
  end
end
```

### 4. Presentation Layer (UI & Real-time)

#### Broadcast Service
```ruby
# app/services/broadcast_service.rb
class BroadcastService
  def self.update(record)
    new(record).update
  end

  def initialize(record)
    @record = record
  end

  def update
    case @record
    when GradingTask
      broadcast_grading_task
    when AssignmentPrompt
      broadcast_assignment_prompt
    when GradingRubric
      broadcast_grading_rubric
    when StudentSubmission
      broadcast_student_submission
    end
  end

  private

  def broadcast_grading_task
    Turbo::StreamsChannel.broadcast_replace_to(
      @record,
      target: dom_id(@record),
      partial: "grading_tasks/grading_task",
      locals: { grading_task: @record }
    )

    broadcast_progress if @record.status_previously_changed?
  end

  def broadcast_assignment_prompt
    Turbo::StreamsChannel.broadcast_replace_to(
      @record.grading_task,
      target: dom_id(@record),
      partial: "assignment_prompts/assignment_prompt",
      locals: { prompt: @record }
    )
  end

  def broadcast_grading_rubric
    Turbo::StreamsChannel.broadcast_replace_to(
      @record.grading_task,
      target: dom_id(@record),
      partial: "grading_rubrics/grading_rubric",
      locals: { rubric: @record }
    )
  end

  def broadcast_student_submission
    Turbo::StreamsChannel.broadcast_replace_to(
      "student_submissions_#{@record.grading_task_id}",
      target: dom_id(@record),
      partial: "student_submissions/student_submission",
      locals: { submission: @record }
    )

    broadcast_progress
  end

  def broadcast_progress
    task = @record.is_a?(GradingTask) ? @record : @record.grading_task

    Turbo::StreamsChannel.broadcast_replace_to(
      task,
      target: "#{dom_id(task)}_progress",
      partial: "grading_tasks/progress",
      locals: { grading_task: task }
    )
  end

  def dom_id(*args)
    ActionView::RecordIdentifier.dom_id(*args)
  end
end
```

#### View Templates

1. Grading Task Progress
```erb
<%# app/views/grading_tasks/_progress.html.erb %>
<div id="<%= dom_id(grading_task) %>_progress" class="mt-4">
  <div class="flex items-center gap-4">
    <div class="w-full bg-gray-200 rounded-full h-2.5">
      <div class="bg-blue-600 h-2.5 rounded-full transition-all duration-500"
           style="width: <%= grading_task.progress_percentage %>%">
      </div>
    </div>
    <span class="text-sm text-gray-600">
      <%= grading_task.progress_percentage %>%
    </span>
  </div>

  <div class="mt-2 text-sm text-gray-600">
    <%= pluralize(grading_task.student_submissions.graded.count,
                 'submission') %> graded
    of <%= grading_task.student_submissions.count %> total
  </div>
</div>
```

2. Assignment Prompt Status
```erb
<%# app/views/assignment_prompts/_assignment_prompt.html.erb %>
<div id="<%= dom_id(prompt) %>" class="mt-4">
  <div class="flex items-center gap-2">
    <h3 class="text-lg font-semibold">Assignment Prompt</h3>
    <%= render "shared/status_badge", status: prompt.status %>
  </div>

  <% if prompt.formatted_html? %>
    <div class="mt-2 prose">
      <%= prompt.formatted_html.html_safe %>
    </div>
  <% end %>
</div>
```

3. Student Submission Card
```erb
<%# app/views/student_submissions/_student_submission.html.erb %>
<div id="<%= dom_id(submission) %>" 
     class="p-4 bg-white rounded-lg shadow transition-all duration-300"
     data-controller="submission">
  <div class="flex items-center justify-between">
    <h4 class="font-medium"><%= submission.student_name %></h4>
    <%= render "shared/status_badge", status: submission.status %>
  </div>

  <% if submission.graded? %>
    <div class="mt-4">
      <div class="text-2xl font-bold"><%= submission.grade %>%</div>
      <div class="mt-2 prose prose-sm">
        <%= submission.feedback_html.html_safe %>
      </div>
    </div>
  <% end %>
</div>
```

## Migration Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data loss during migration | High | Full database backup before migration, dry-run in staging environment first |
| Service disruption | Medium | Schedule maintenance window, implement rollback plan with tested restore process |
| Performance impact | Medium | Add database indexes, benchmark critical paths, optimize queries |
| UI inconsistencies | Low | Comprehensive UI testing before release, feature flags for gradual rollout |
| Job queue overload | Medium | Implement rate limiting, monitor queue sizes, scale worker processes |

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Average grading task completion time | 3.5 minutes | < 1 minute |
| Error rate | 5% | < 1% |
| Code maintainability index | 65 | > 80 |
| UI update latency | 2-3 seconds | < 500ms |
| Background job throughput | 10/minute | 30/minute |

## Testing Strategy

### Service Tests
```ruby
class ProcessGradingTaskServiceTest < ActiveSupport::TestCase
  test "processes entire workflow when successful" do
    # Setup
    task = grading_tasks(:one)
    
    # Exercise
    ProcessGradingTaskService.process(task)
    
    # Verify
    assert_equal "validated", task.assignment_prompt.reload.status
    assert_equal "validated", task.grading_rubric.reload.status
    assert_enqueued_jobs task.student_submissions.count, only: GradeSubmissionJob
  end

  test "stops at assignment prompt when it fails" do
    # Setup
    task = grading_tasks(:one)
    LlmService.stubs(:process_prompt).returns(OpenStruct.new(success?: false))
    
    # Exercise
    ProcessGradingTaskService.process(task)
    
    # Verify
    assert_equal "failed", task.assignment_prompt.reload.status
    assert_equal "pending", task.grading_rubric.reload.status
    assert_no_enqueued_jobs only: GradeSubmissionJob
  end
end
```

### Integration Tests
```ruby
class GradingTaskFlowTest < ActionDispatch::IntegrationTest
  test "complete grading task flow" do
    # Setup
    sign_in users(:teacher)
    
    # Exercise - Create task
    post grading_tasks_path, params: { grading_task: valid_params }
    assert_response :redirect
    follow_redirect!
    
    # Verify - Initial state
    task = GradingTask.last
    assert_equal "pending", task.assignment_prompt.status
    assert_equal "pending", task.grading_rubric.status
    
    # Exercise - Process task
    perform_enqueued_jobs
    
    # Verify - Final state
    assert_equal "validated", task.assignment_prompt.reload.status
    assert_equal "validated", task.grading_rubric.reload.status
    assert task.student_submissions.all? { |s| s.status == "graded" }
  end
end
```

## Phased Rollout Plan

### Phase 1: Database Changes (Week 1)
- Create new database tables for prompts and rubrics
- Run data migration scripts
- Add database indexes for performance
- Verify data integrity

### Phase 2: Core Models & Services (Week 2)
- Update model relationships and validations
- Implement state transition service
- Add orchestration service
- Set up event publishing system

### Phase 3: Processing Logic (Week 3)
- Refactor background jobs
- Update controller actions
- Implement error handling
- Set up monitoring and logging

### Phase 4: UI & Real-time Updates (Week 4)
- Create broadcast service
- Update view templates
- Implement Turbo Stream integration
- Test UI responsiveness

### Phase 5: Testing & Deployment (Week 5)
- Write comprehensive tests
- Deploy to staging environment
- Monitor performance metrics
- Gradual rollout to production (10% → 50% → 100%)

## Workflow Diagrams

### State Transition Flow

```
[Created] → [Processing Prompt] → [Processing Rubric] → [Processing Submissions] → [Completed]
    ↓               ↓                    ↓                       ↓                    
[Failed]         [Failed]             [Failed]                [Failed]
```

### Service Interaction Flow

```
Controller → ProcessGradingTaskJob → ProcessGradingTaskService
                                          ↓
                                    Process Assignment Prompt
                                          ↓
                                    Process Grading Rubric
                                          ↓
                                    Process Student Submissions → GradeSubmissionJob(s)
```

## Monitoring and Logging

1. **Job Monitoring**
   - Active job queue sizes and processing times
   - Error rates by job type
   - Job completion throughput

2. **Event Monitoring**
   - Event frequency by type
   - Event subscriber performance
   - Failed event handling

3. **State Transition Logging**
   - State changes with timestamps
   - Average time in each state
   - Failed transition attempts

## Implementation Checklist

- [ ] Create database migrations
- [ ] Extract data from existing tables
- [ ] Create/update models with associations
- [ ] Implement state transition service
- [ ] Create orchestration service
- [ ] Set up event publishing system
- [ ] Refactor background jobs
- [ ] Update controllers
- [ ] Create broadcast service
- [ ] Update view templates
- [ ] Write tests
- [ ] Add monitoring and logging
- [ ] Deploy to staging
- [ ] Verify performance
- [ ] Deploy to production

## Appendix: Additional Code Snippets

### Error Handling
```ruby
# app/services/error_handler.rb
class ErrorHandler
  def self.capture(error, context = {})
    Rails.logger.error "#{error.class.name}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    # Log to exception monitoring service
    Honeybadger.notify(error, context: context) if defined?(Honeybadger)
  end
end
```

### Database Indexes
```ruby
# Additional indexes for performance
add_index :grading_tasks, :status
add_index :student_submissions, [:grading_task_id, :status]
add_index :student_submissions, :status
```

### Performance Monitoring
```ruby
# config/initializers/performance_monitoring.rb
ActiveSupport::Notifications.subscribe("process_grading_task.performance") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.info "Processing task took #{event.duration.round(2)}ms"
  
  # Log to metrics service
  StatsD.timing("grading_task.processing_time", event.duration)
end
```
