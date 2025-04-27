# 🤖 GradeBot 

## Product Requirements Document

GradeBot is an AI-feedback assistant designed for educators who want to provide better feedback in less time. Gradebot helps teachers focus on planning and insights and transform hours of grading into minutes of strategic review.

### Problem

Grading student work is time consuming work often done outside of regular school hours.

### Target user

The target user is a teacher who has students complete written assignments using Google Docs. This user may already use LLMs to generate assignments, rubrics, and provide feedback, but the process is time consuming and manual.

### How it works

Teachers log in with their Google accounts. The teacher visits the assignment form to create a new assignment. They enter an assignment title and subject, they select a grade level. They then paste instructions into a text area field.

Next teachers have two options. They can either select to have GradeBot generate a rubric using AI or they can paste an existing rubric into a text area field.

Next teachers click on a Google-branded "Select student work" button that opens a Google Picker. The teacher can select up to 35 pieces of student work.

Finally the teacher can customize grading settings by selecting from a feedback tone dropdown. Options are encouraging, neutral/objective, and critical.

The teacher then clicks on "Submit for grading" and they are redirected to an assignment detail page that shows the assignment details, the rubric, and a list of student work.

In the background GradeBot turns the assignment and optionally pasted rubric into a prompt to generate a structured rubric which has many criteria each of which has many levels. The prompt is then sent to an LLM and the response is saved. When the response is saved, the teacher watching the assignment detail page sees an update to the rubric section. The rubric goes from a processing message that says, "GradeBot is creating your rubric…" to a list of criteria and the descriptors of each criteria.

Next GradeBot gets each piece of student work for the assignment, combines it with the assignment and rubric into a prompt, and sends the prompt to the LLM for structured feedback. The feedback solicited will include a feedback note which is qualitative feedback on the overall assignment. There is also a list of feedback items which is a strength or opportunity. There is also a rubric criteria level for each rubric criteria. There is also a summary of the student work and a question the teacher can ask the student about their work. Finally there is a list of checks that are scored from 0-100% and could cover things like was this work LLM generated? The writing is also assigned a grade level.

From the assignment screen, the teacher can click on a student work and review the llm generated feedback. The teacher can append any or all of the qualitative feedback, feedback items and rubric criteria levels to the original student's Google document. Teaches can manually edit any piece of feedback by clicking an edit button, editing the text and then clicking a save button.

Once all of the student works are completed with feedback, they are assembled along with the original assignment, generated rubric, and student feedback into one final prompt. The prompt is sent to the LLM to produce an assignment summary report which mimics the feedback generated per student work, but the feedback is generalized for all student works.

Teachers can go to their assignments list and see a list of all their previous assignments. In the header, there is a streak indicator showing consecutive days with grading tasks, total number of grading tasks.

There are further gamification elements like a github-style contribution chart which shows 1 square per day of the year. The square gets darker the more student works were graded on that day.

Behind the scenes, every time a prompt is sent to an LLM, the cost of the response is tracked such that we can see cost per request and aggregate costs by requests for each assignment and each user.

There is a Stripe integration to handle subscriptions. Every user can get 1 assignment per month for free. For $X.99 users can get up to 300 assignments per month. When a free tier user reaches has 1 assignment in the calendar month, they are redirected to a pay plan whenever they try to create a new assignment. When a paying user reaches their 300 assignments per month limit, they are prevented from creating new assignments.

GradeBot has a privacy, terms of service, and ai pages describing specifically what data we collect and how we use it.

### Engineering specification

#### Techstack

The tech stack for GradeBot is Rails 8+ with stimulus for javascript and tailwind 4+ for styling. We use an sqlite database. We also use solid cache, queue, and cable. We deploy with Kamal to Google Cloud Platform. We manage secrets using Kamal Secrets and the 1Password adapter. We use minitest for testing. We use fixtures for test data.

In general we keep our techstack as simple as possible and avoid taking on unnecessary dependencies.

For the Google Docs integration we use the `drive.file` scope.

#### Database models

##### User

* Has many assignments

##### Assignment

* Belongs to a user  
* Has one rubric  
* Has many student works  
* Has many document selections  
* Has one assignment summary  
* Raw rubric text  
* Integer - total processing milliseconds

##### Rubric

* Has many criteria

##### Criterion

* Has many levels  
* Title  
* Description  
* Position

##### Level

* Title  
* Description  
* Position

##### SelectedDocument

* _Note: Renamed from `DocumentSelection` (used in legacy GradingTask flow) to avoid naming conflicts during the parallel refactor._
* _Purpose: This model tracks documents selected via the Google Picker for a specific `Assignment` in the refactored workflow, keeping it separate from the legacy `DocumentSelection`/`GradingTask` process._
* Belongs to an assignment
* google_doc_id (string)
* title (string)
* url (string)

We are only storing google_doc, title, and url because this is what we need at this point for the UI (title, url) and to create student_works (google_doc_id).

When processing student work, we use the `student_work.selected_document.google_doc_id` to fetch the document content and validate that it does not exceed the maximum number of words.
If it does, we will set the student work status to failure.

##### Student Work

* Belongs to an assignment  
* Belongs to a selected document  
* Has many student work criterion levels  
* Has many feedback items  
* Qualitative feedback as text  
* Has many checks

##### Student Work Criterion Level

* Join between student work, criteria and level representing how a student did on a particular rubric criteria  
* Has explanation as text

##### Feedback items

* Type - strength or opportunity  
* Title  
* Description  
* Evidence  
* Belongs to student work

##### Student Work Check

* Type  
* Score (0-100)  
* Explanation  
* Belongs to student work

##### Assignment summary

* Belongs to assignment  
* Student work count  
* Qualitative insights as text  
* Has many feedback items

#### Architecture

GradeBot uses a conventional Rails MVC architecture. It relies on solid queue background workers for handling LLM requests. It also uses a services directory for business logic that is not appropriate for the model or the controller.

##### LLM processing abstraction

*Note: the processing abstraction is aspirational and not yet built*

GradeBot leverages two abstractions to handle the repeated pattern of:

1. Collect data ->  
2. Build prompt ->   
3. Send prompt to llm ->  
4. Parse llm response ->  
5. Store result

The ProcessingTask encapsulates all configuration and context for a specific LLM processing task.

* It represents a single task encompassing the assembly and collection of data, prompt building, llm request, response parsing, and result storage.  
  * Examples include:  
    * Rubric Generation  
    * Student Feedback  
    * Assignment Summary  
* It contains all necessary data for the processing  
* Defines which specific component to use for each step  
  * Which prompt to use with the prompt builder  
  * Which response parser to use  
  * Which storage service to use  
  * Which broadcaster to use for real time ui updates  
  * Which status manager to use  
* Handles tracking of processing time and user attribution  
* Provides a consistent interface regardless of the specific task type

The ProcessingPipeline provides a standardized workflow for all LLM processing

* Takes an ProcessingTask as an input  
* Orchestrates the entire processing flow  
  * Builds the prompt  
  * Makes the llm request  
  * Tracks processing time  
  * Parses the LLM response  
  * Stores the result  
  * Handles status management  
  * Broadcasts updates  
* Centralizes error handling, retries and timeouts

#### Detailed LLM System Components and Flow

The codebase implements a robust LLM integration system that handles request processing, error management, cost tracking, and event handling. Here's a comprehensive breakdown of the components and their interactions:

**Core Components**

1.  **Client Architecture**
    *   `Client` (`app/services/llm/client.rb`): Entry point for LLM requests that validates inputs, checks circuit breaker status, and delegates to specific implementations.
    *   `BaseClient` (`lib/llm/base_client.rb`): Abstract class providing shared functionality like request logging, timing, and cost tracking. Implements the template method pattern with abstract methods for specific client implementations.
    *   `AnthropicClient` (`lib/llm/anthropic/client.rb`): Concrete implementation for Anthropic's Claude API that handles model mapping, token counting, and API communication.
    *   `ClientFactory` (`lib/llm/client_factory.rb`): Creates appropriate client instances, currently defaulting to Anthropic's client.

2.  **Resilience Mechanisms**
    *   `RetryHandler` (`lib/llm/retry_handler.rb`): Manages retry strategies with exponential backoff for different error types.
    *   `CircuitBreaker` (`lib/llm/circuit_breaker.rb`): Prevents cascading failures by temporarily stopping operations after multiple errors. Implements closed, open, and half-open states.

3.  **Cost Management**
    *   `CostCalculator` (`app/services/llm/cost_calculator.rb`): Calculates costs based on token usage and model-specific rates.
    *   `CostTracker` (`app/services/llm/cost_tracker.rb`): Records cost data to the database.
    *   `CostTracking` (`app/services/llm/cost_tracking.rb`): Facade providing simplified access to cost tracking functionality.
    *   `CostTrackingSubscriber` (`app/services/llm/cost_tracking_subscriber.rb`): Listens for request completion events and handles cost tracking.

4.  **Event Management**
    *   `EventSystem` (`app/services/llm/event_system.rb`): Simple pub/sub system for LLM-related events, with Publisher and Subscriber components.

5.  **Prompt Management** (Note: These files were not explicitly reviewed but are part of the overall system)
    *   `PromptBuilder` (`app/services/prompt_builder.rb`): Builds prompts for different request types.
    *   `PromptTemplate` (`app/services/prompt_template.rb`): Renders ERB templates with variables for prompt construction.

**Request Flow**

When a client calls `LLM::Client.generate(llm_request)`:

1.  The request is validated and the circuit breaker is checked.
2.  `ClientFactory` creates an appropriate client instance (currently `AnthropicClient`).
3.  `BaseClient#generate` method is invoked:
    *   Logs the request.
    *   Calculates prompt token count via the provider-specific `calculate_token_count`.
    *   Times the execution.
    *   Delegates the actual API call to the provider-specific `execute_request` method.
    *   After successful execution, publishes a completion event via `EventSystem`.
    *   Handles cost tracking event publishing (or direct fallback if publishing fails).
4.  The provider-specific client (`AnthropicClient#execute_request`) executes the actual API request.
5.  The response is processed, enriched with metadata (tokens, model), and returned up the call stack.

**Error Handling & Resilience**

The system implements multiple resilience patterns:

*   **Circuit Breaker Pattern**: Prevents cascading failures by temporarily stopping operations after multiple errors (`LLM::CircuitBreaker`).
*   **Retry Strategy**: Handles transient errors (like rate limits or temporary overloads) with exponential backoff and jitter (`LLM::RetryHandler`).
*   **Error Classification**: Custom error classes (`LLM::Errors::ApiOverloadError`, `LLM::Errors::AnthropicOverloadError`, `LLM::ServiceUnavailableError`) allow for specific handling by the retry mechanism and circuit breaker.

**Cost Tracking System**

Cost tracking follows an event-driven approach integrated into `BaseClient`:

1.  When `BaseClient#generate` successfully receives a response from `execute_request`, it publishes an `EventSystem::EVENTS[:request_completed]` event containing the request, response (with token data), and context.
2.  `CostTrackingSubscriber` listens for this event and processes it:
    *   Extracts token counts from the response metadata.
    *   Calculates costs using `CostCalculator` based on the model's pricing.
    *   Records the cost data using `CostTracker`.
3.  **Fallback**: If event publishing fails within `BaseClient#generate`, it calls `track_cost_directly` to perform the calculation and recording immediately.

**Extension Points**

The system can be extended in several ways:

*   **New LLM Providers**: Create a new client class inheriting from `BaseClient`, implement `#execute_request` and `#calculate_token_count`, and update `ClientFactory` to instantiate it based on configuration or model name.
*   **Custom Retry Strategies**: Extend `RetryHandler` with new strategies for different error types.
*   **Enhanced Cost Tracking**: Extend `CostTracker` or `CostCalculator` for more complex metrics or pricing.
*   **New Event Types**: Add events to `EventSystem::EVENTS` and create corresponding subscribers.
*   **Prompt Templates**: Add new `.erb` templates under `app/views/prompts/` for different use cases, utilized by `PromptTemplate` and `PromptBuilder`.

This architecture provides a solid foundation for building AI-assisted applications with proper error handling, cost control, and extensibility.

#### Cost tracking system

GradeBot implements a comprehensive cost tracking system that monitors and records the cost of each LLM request. This system tracks token usage, calculates associated costs, and aggregates this data at the user and assignment level to provide transparency and enable business decisions.

##### **Technical Implementation**

###### **Event-Based Architecture**

The cost tracking system uses an event-based architecture that:

1. Captures metrics for every LLM request  
2. Calculates costs based on token usage and model type  
3. Persists this data for reporting and analysis  
4. Provides real-time cost insights during assignment processing

###### **Cost Tracking Flow**

1. **Request Execution**: When an LLM request is made through the `BaseClient`, the system:  
   * Logs the request details including model name and request type  
   * Calculates and records the prompt token count before execution  
   * Times the execution for performance metrics  
2. **Event Publication**: Upon successful completion, the system:  
   * Publishes a `request_completed` event with request, response, and context data  
   * Includes token usage metrics (prompt, completion, total)  
   * Attaches user and assignment context for attribution  
3. **Cost Calculation**: The `CostTrackingSubscriber` processes the event by:  
   * Extracting token counts from the response metadata  
   * Calculating the cost based on the specific model's pricing  
   * Recording both token usage and dollar cost  
4. **Fallback Mechanism**: If the event system fails, a direct cost tracking fallback:  
   * Extracts token information from the response  
   * Calculates cost using the same pricing logic  
   * Records the data directly via `CostTracking.record`

###### **Data Collection Points**

For each LLM request, the system collects:

* LLM model name (e.g., "claude-3-5-haiku")  
* Prompt tokens count  
* Completion tokens count  
* Total tokens count  
* Calculated cost in USD  
* Request ID for correlation  
* Request type (e.g., "rubric_generation", "student_feedback", "assignment_summary")  
* User ID for attribution  
* Assignment ID for aggregation  
* Processing time in milliseconds

##### **Reporting and Visualization**

The cost tracking data enables:

1. **User-Level Reporting**: Aggregate costs per user to:  
   * Monitor usage patterns  
   * Enforce subscription limits  
   * Provide transparency on resource utilization  
2. **Assignment-Level Analysis**: Aggregate costs per assignment to:  
   * Calculate average cost per student work  
   * Compare costs across different assignment types  
   * Optimize prompt engineering for cost efficiency  
3. **Business Intelligence**: Overall system analysis to:  
   * Track total operating costs for LLM usage  
   * Calculate contribution margins per user and subscription tier  
   * Inform pricing strategy and tier limits

##### **Integration with Subscription Model**

Cost tracking directly supports the subscription model by:

* Providing accurate usage data for the freemium model (1 free assignment/month)  
* Supporting enforcement of paid tier limits (300 assignments/month)  
* Enabling data-driven decisions about pricing adjustments

##### **Performance Considerations**

The cost tracking system is designed to:

* Minimize impact on request performance through asynchronous event handling  
* Gracefully degrade with a fallback mechanism if event publishing fails  
* Use efficient database operations for recording cost data

By implementing this comprehensive cost tracking system, GradeBot provides complete transparency into LLM usage costs, supporting both business operations and product optimization efforts.

#### **Processing Time Estimation System**

##### **Overview**

GradeBot implements a straightforward processing time estimation system to provide teachers with realistic completion time expectations. This system calculates and updates estimated completion times based on the number of pending LLM requests and average processing duration metrics.

##### **Technical Implementation**

###### **Base Time Calculation**

1. **Request Time Constants**:  
   * Each LLM request is assigned a standard expected processing time:  
     * Rubric Generation: 30 seconds  
     * Student Work Feedback: 60 seconds per work  
     * Assignment Summary: 45 seconds  
2. **Total Assignment Processing Formula**:  
   * `Total Estimated Time = Rubric Generation Time + (Student Work Feedback Time × Number of Works) + Assignment Summary Time`  
3. **Example Calculation**:  
   * For an assignment with 25 student works:  
     * Rubric: 30 seconds  
     * Student Works: 25 × 60 seconds = 1,500 seconds (25 minutes)  
     * Summary: 45 seconds  
     * Total: 1,575 seconds (26 minutes, 15 seconds)

###### **Dynamic Adjustment**

1. **Progress Tracking**:  
   * The system tracks completed requests and adjusts remaining time accordingly  
   * As each student work completes processing, the estimation is recalculated  
   * The UI displays both progress (X/Y works processed) and updated time estimate

###### **User-Facing Display**

1. **Initial State**:  
   * When assignment is first submitted: "Calculating estimated completion time..."  
   * After rubric generation completes: "Estimated time remaining: X minutes"  
2. **Progress Updates**:  
   * Real-time updates via Broadcast Service for each completed student work  
   * Timer displays in minutes for estimates >2 minutes  
   * Timer switches to seconds for estimates <2 minutes  
   * Visual progress bar shows percentage of completed works  
3. **Completion Notification**:  
   * When all processing completes, the UI updates to show total actual processing time  
   * Provides breakdown: "Total processing time: X minutes (Y seconds per student work on average)"  
4. **Error Handling**:  
   * If a student work fails processing, the estimation excludes that work  
   * Failed works are marked with an error indicator and "Retry" option  
   * When retrying, the estimation is recalculated to include the additional request

### Metrics

#### **Business Metrics**

* **User Acquisition**: 100 paying customers by the end of the 2026 school year  
* **Retention**: 80% monthly retention rate for paying users  
* **Engagement**: 1+ assignment created daily by October 2025  
* **Conversion**: 10% conversion rate from free tier to paid subscription

#### **Product Usage Metrics**

* **Assignment Volume**: Track total assignments processed per week/month  
* **Student Work Volume**: Average number of student works per assignment  
* **Feature Adoption**: Percentage of teachers using each feature:  
  * AI-generated rubrics vs. custom rubrics  
  * Feedback customization rate  
  * Feedback editing frequency  
  * Assignment summary usage

#### **Performance Metrics**

* **Processing Time**: Average time to complete:  
  * Rubric generation (target: <60 seconds)  
  * Per student work feedback (target: <90 seconds)  
  * Complete assignment processing (target: <10 minutes for 25 students)  
* **Error Rates**: Percentage of failed LLM requests requiring retry  
* **System Uptime**: Maintain 99.9% availability during school hours

#### **Quality Metrics**

* **Feedback Quality**: Measured via:  
  * Teacher edit frequency (lower is better)  
  * Teacher satisfaction surveys (NPS score)  
  * Student improvement on subsequent assignments  
* **Cost Efficiency**:  
  * Average token usage per student work  
  * Cost per assignment trend over time  
  * Token efficiency improvements through prompt optimization

#### **Financial Metrics**

* **Average Revenue Per User (ARPU)**: Monthly tracked against subscription price  
* **Customer Acquisition Cost (CAC)**: Marketing spend per converted paying user  
* **LLM Cost Ratio**: LLM costs as percentage of revenue (target: <30%)  
* **Contribution Margin**: Net revenue after direct costs per customer  
* **Lifetime Value (LTV)**: Projected based on retention and usage patterns

#### **Growth Indicators**

* **Viral Coefficient**: Number of new users referred by existing users  
* **Word-of-Mouth Rate**: Percentage of new signups attributable to referrals  
* **School Coverage**: Multiple teachers adopting within same schools/districts

### Launch Plan

While some of this functionality (LLM requests, login, picker, some of the domain models) exists, we need to refactor and rebuild piece by piece.

### Milestones

1. Teachers can visit /assignments/new and see the assignment form.  
2. Teachers submit the form to create an Assignment record with associated empty Rubric, Document selections, and Student works.  
   1. The controller parses the submission and calls Assignment::InitializerService  
   2. Document selections created via DocumentSelection::BulkCreationService (single insert)  
      1. Validate that document selections are < 2000 words, if a document is longer it will not be included in the assignment processing  
   3. Student works created via StudentWork::BulkCreationService (single insert)  
   4. The InitializerService enqueues an AssignmentProcessingJob, which initializes the parent ProcessingPipeline  
   5. Teacher is redirected to the assignment/ show page  
3. The assignment show page displays:  
   1. Basic assignment details (title, subject, grade level, truncated instructions)  
   2. Status badge showing "In progress"  
   3. Rubric section with "GradeBot is generating your rubric" message  
   4. Student work progress (0/total count) with "calculating" estimated completion time  
   5. List of student works with pending status badges  
4. A background job is kicked off which will begin the parent ProcessingPipeline execution:  
   1. Rubric Generation Child Pipeline:  
      1. Creates an ProcessingJob for rubric generation  
      2. LlmProcessingPipeline executes the job:  
         1. Builds prompt via prompt builder  
         2. Calls LLM Client  
         3. Parses response into RubricResponse object  
         4. Creates rubric structure via Rubric::CreationService with nested services  
      3. BroadcastService updates the rubric section on the assignment page  
      4. Assignment page updates to show the generated rubric criteria  
   2. Student Work Feedback Child Pipelines (for each submission):  
      1. Parent pipeline creates a new ProcessingJob for each student work  
      2. Updates student work status to "processing" via BroadcasterService  
      3. For each student work, LlmProcessingPipeline:  
         1. Fetches document content from Google  
         2. Builds prompt with document content, assignment, and rubric  
         3. Calls LLM Client  
         4. Parses response into StudentWorkFeedback object  
         5. Saves feedback and creates related records  
      4. Parent pipeline updates completion time estimates via TimerService  
      5. BroadcasterService updates UI with progress information, status changes, and completion links  
      6. Each completed student work shows "View feedback" link  
   3. Assignment Summary Child Pipeline:  
      1. After all student works complete, parent pipeline creates an ProcessingJob for assignment summary  
      2. LlmProcessingPipeline:  
         1. Gathers all student works, assignment, and rubric data  
         2. Builds summary prompt  
         3. Calls LLM Client  
         4. Parses response  
         5. Creates assignment summary record  
      3. Parent pipeline updates assignment status to "Complete"  
      4. BroadcasterService updates assignment page to show insights section with:  
         1. Common strengths and opportunities  
         2. Total processing time  
         3. Assignment summary information  
5. Teacher interaction with completed assignment:  
   1. From student work show page, teachers can view and edit feedback  
   2. Each section has edit, save, and send buttons  
   3. "Send" appends feedback to student's Google document  
6. Assignments index page displays analytics with gamification themes to encourage usage:  
   1. Assignment creation streak count  
   2. Total and average assignment counts  
   3. Grading statistics and shared feedback metrics  
   4. Monthly limit progress  
   5. GitHub-style contribution graph  
7. Individual student works can be re-processed if they failed for some reason

---

# Decision log

## Assignment Form UX & Architecture Decisions (2025-04-21)

- **Field Structure:**
  - The assignment form uses flat attributes (title, description, subject, grade level, instructions) matching the Assignment model. No nested attributes or form object is used at this stage, as the flow is simple and direct.
- **Rubric Selection:**
  - A toggle switch is used for "Generate with AI" (default) vs. "I have a rubric". Only if the latter is selected does a textarea appear for rubric input. The placeholder is: "Paste your rubric here, don't worry about formatting."
- **Google Picker:**
  - The form integrates the Google Picker for selecting up to 35 student documents. The selected document data is submitted as a hidden field and handled in the controller. There is a dedicated section in the form for displaying selected documents.
- **Feedback Tone:**
  - Instead of a dropdown, a slider bar is used to select among three feedback tone options: Encouraging, Objective/Neutral, Critical. This provides a more engaging and intuitive UX.
- **Icon Usage:**
  - All icons in the form are rendered as Rails partials from the `/icons` directory for maintainability and reusability.
- **Form Model Rationale:**
  - A form object is not used at this stage. The flat model approach is sufficient because only the Assignment and document data are being submitted. If future requirements introduce complex multi-model coordination or cross-field validations, a form object or service object can be introduced.
- **Validation:**
  - Validation errors are displayed tastefully at the top of the form, following Tailwind and application style conventions.
- **Submission:**
  - The form submits via POST. Stimulus controllers are used for rubric toggle, Google Picker, and feedback tone slider interactivity.
