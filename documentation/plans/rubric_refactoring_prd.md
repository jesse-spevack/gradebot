# GradeBot Backend Refactoring PRD

## Overview

This document outlines the comprehensive plan to rebuild GradeBot's backend models and grading system. Currently, rubrics are stored as unstructured text fields, feedback is limited, and the data model doesn't support detailed scoring or assessment analytics. This refactoring will:

1. Create a structured data model for rubrics with criteria and levels
2. Rebuild the student submission model with enhanced feedback capabilities
3. Develop a grading task summary model for grading task level insights
4. Enable detailed, criterion-based scoring with evidence tracking
5. Implement a more sophisticated feedback system
6. Improve teacher editing capabilities
7. Enable teacher to selectively append feedback to student submissions

## Current Implementation

The current implementation stores rubrics as text fields in the GradingTask model:
- `formatted_grading_rubric`: text
- `grading_rubric`: text

This approach limits reusability and constrains structured feedback by treating the rubric as an opaque document rather than a data model.

The current implementation of StudentSubmission has limited feedback capabilities and does not support detailed, criterion-based scoring.

## Proposed Solution

### Data Models

#### RawRubric
- `id`: primary key
- `grading_task_id`: integer (foreign key to GradingTask) null false
- `rubric_id`: integer (foreign key to Rubric)
- `content`: text (raw pasted rubric content)
- `created_at`/`updated_at`: timestamps

#### Rubric
- `id`: primary key
- `title`: string (name of the rubric)
- `user_id`: integer (foreign key to User)
- `total_points`: integer (default 100)
- `status`: enum (pending, processing, complete)
- `created_at`/`updated_at`: timestamps

#### Criterion
- `id`: primary key
- `rubric_id`: integer (foreign key to Rubric)
- `title`: string
- `description`: text
- `points`: integer
- `position`: integer (for ordering)
- `created_at`/`updated_at`: timestamps

#### Level
- `id`: primary key
- `criterion_id`: integer (foreign key to Criterion)
- `title`: string
- `description`: text
- `points`: integer
- `position`: integer (for ordering)
- `created_at`/`updated_at`: timestamps

#### StudentSubmission (Updated Model)
- `id`: primary key
- `grading_task_id`: integer (foreign key to GradingTask)
- `document_selection_id`: integer (foreign key to DocumentSelection) - null false
- `status`: enum (pending, processing, graded, published) - new field for workflow tracking
- `content`: text (retrieved document content)
- `overall_feedback`: text (comprehensive assessment of the submission)
- `final_grade`: float (calculated based on criterion scores)
- `created_at`/`updated_at`: timestamps

#### StudentSubmissionCheck
- `id`: primary key
- `student_submission_id`: integer (foreign key to StudentSubmission)
- `check_type`: enum (plagiarism, authenticity)
- `score`: float (0-100)
- `reason`: text (LLM explanation of reason for score)
- `created_at`/`updated_at`: timestamps

#### Strengths
Polymorphic association with StudentSubmission GradingTaskSummary
- `id`: primary key
- `polymorphic_type`: string (StudentSubmission or GradingTaskSummary)
- `polymorphic_id`: integer (foreign key to StudentSubmission or GradingTaskSummary)
- `content`: text (key strength identified by LLM)
- `reason`: text (LLM explanation of strength)
- `created_at`/`updated_at`: timestamps

#### Opportunities
Polymorphic association with StudentSubmission GradingTaskSummary
- `id`: primary key
- `polymorphic_type`: string (StudentSubmission or GradingTaskSummary)
- `polymorphic_id`: integer (foreign key to StudentSubmission or GradingTaskSummary)
- `content`: text (growth area identified by LLM)
- `reason`: text (LLM explanation of area for improvement)
- `created_at`/`updated_at`: timestamps

#### RubricCriterionScore
- `id`: primary key
- `student_submission_id`: integer (foreign key to StudentSubmission)
- `criterion_id`: integer (foreign key to Criterion)
- `points_earned`: integer
- `level_id`: integer (foreign key to Level)
- `reason`: text (LLM explanation of score justification)
- `evidence`: text (student submission excerpt supporting the score)
- `teacher_adjusted`: boolean (indicates if the score was changed by teacher)
- `original_points_earned`: integer (stores original LLM score if teacher adjusted)
- `status`: enum (pending, scored, reviewed) - tracks scoring workflow
- `created_at`/`updated_at`: timestamps

Note we can infer the relationship to rubric and grading task by including

```ruby
# In RubricCriterionScore model
delegate :rubric, to: :grading_task
delegate :grading_task, to: :student_submission
```

#### GradingTaskSummary
- `id`: primary key
- `grading_task_id`: integer (foreign key to GradingTask)
- `insights`: text (suggested next instructional steps)
- `completion_rate`: float (percentage of graded submissions)
- `status`: enum (pending, processing, complete)
- `created_at`/`updated_at`: timestamps

### Key Functionality

1. **Rubric Management**
   - Generate a structured rubric with criteria and levels from an assignment prompt (`AssignmentPrompt` model) using LLM
   - Create a `RawRubric` from pasted rubric text.
   - Parse `RawRubric` into structured data with criteria and levels
   - Select and duplicate from previously used rubrics
   - Validate and normalize rubric structure and point values

2. **Student Submission Processing**
   - Track submission status through the entire grading workflow: grading, feedback review, feedback revision, appending feedback to the student submissions
   - Store and analyze submission content from Google Docs
   - Manage multiple submissions per grading task
   - Support status transitions (pending → processing → graded → (optional) revise → published)
   - Bulk append feedback to all submissions for a grading task 

3. **Criterion-Based Scoring**
   - Automatically evaluate submissions against each rubric criterion
   - Match submission quality to appropriate criterion levels
   - Provide evidence-based justifications for each score
   - Track both AI-generated and teacher-adjusted scores

4. **Comprehensive Feedback System**
   - Generate overall qualitative feedback for each submission
   - Identify specific strengths with supporting evidence
   - Highlight areas for improvement with actionable suggestions
   - Allow teachers to edit all feedback components
   - Support appending feedback, strengths, and areas of growth to student Google Docs
   - Support optional check for plagiarism and authenticity

5. **Grading Task Summary and Analytics**
   - Aggregate scores across all submissions in a grading task
   - Identify common strengths and weaknesses across the class
   - Generate teaching recommendations based on class performance
   - Provide statistical analysis of grade distribution
   - Track completion status of the grading process

## Technical Architecture

### Model Relationships
- `GradingTask belongs_to :rubric`
- `GradingTask has_many :student_submissions`
- `GradingTask has_one :grading_task_summary`
- `GradingTaskSummary has_many :strengths`
- `GradingTaskSummary has_many :areas_for_improvement`
- `Rubric has_many :criteria`
- `Criterion has_many :levels`
- `RubricCriterionScore has_one :criterion`
- `RubricCriterionScore has_one :level`
- `StudentSubmission has_many :rubric_criterion_scores`
- `StudentSubmission has_many :student_submission_checks`
- `StudentSubmission has_many :strengths`
- `StudentSubmission has_many :areas_for_improvement`
- `StudentSubmissionCheck belongs_to :student_submission`
- `Strength belongs_to :student_submission or :grading_task_summary`
- `AreasForImprovement belongs_to :student_submission or :grading_task_summary`


### Service Objects

```
Services/
  ├── GradingTask
  │   └── CreationService
  ├── AssignmentPrompt
  │   └── CreationService
  ├── Rubric
  │   ├── CreationService
  │   ├── ParserService
  │   ├── GeneratorService
  │   └── ValidatorService
  ├── DocumentSelection
  │   └── CreationService
  └── StudentSubmission
      ├── CreationService
      └── GradingService
```

#### AI Services
```
Services/
  ├── Ai
      ├── StudentSubmissionService
      │   ├── DocumentAnalysisService
      │   ├── RubricEvaluationService
      │   ├── FeedbackGenerationService
      │   └── EvidenceExtractionService
      ├── AssignmentPromptService
      ├── RubricService
      │   ├── ParsingService
      │   ├── GenerationService
      │   └── NormalizationService
      └── GradingService
          ├── StatisticalAnalysisService
          ├── InsightGenerationService
          └── TrendIdentificationService
```

### Jobs

```
Jobs/
  └── GradingTaskJob
```

### Technical Requirements

1. **Rubric Validation**
   - Total points must equal 100
   - Minimum criterion points: 5% of total
   - Criteria range: 1-10 per rubric
   - Consistent level terminology across criteria

2. **Default Level Structure**
   - 5 levels: Excellent, Advanced Proficient, Proficient, Developing, Beginning
   - Point distribution: 100%, 90%, 80%, 70%, 60% of criterion points

3. **Performance**
   - Rubric creation/selection must be fast (no LLM calls during initial creation)
   - LLM-based operations happen asynchronously
   - Rate limiting: 1 LLM request per grading task at a time

4. **UI Requirements**
   - No page refreshes for teacher feedback editing
   - Dynamic criterion score adjustment
   - Real-time updates using Turbo Streams
   - Stimulus controllers for interactive elements

## Implementation Phases

### Phase 1: Foundation - Models and Migrations
1. Create migration to remove existing data (grading tasks, student submissions, LLM cost logs)
2. Write tests for all new models using minitests:
   - Rubric (with status field for workflow tracking)
   - Criterion (with points and position fields)
   - Level (with standardized level terminology)
   - RubricCriterionScore (with teacher adjustment tracking)
   - GradingTaskSummary (for class-level insights)
3. Update tests for existing models:
   - StudentSubmission (adding status, strengths, areas_for_improvement)
   - GradingTask (updated associations)
4. Create migrations for all new models and field updates
5. Add validations for point distributions and relationship integrity
6. Implement model associations following Rails conventions
7. Remove `formatted_grading_rubric` and `grading_rubric` from GradingTask

### Phase 2: Service Layer Development
1. Write tests for all Rubric-related services:
   - Rubric::ParserService (structured rubric from text)
   - Rubric::GeneratorService (LLM-based rubric creation)
   - Rubric::ValidatorService (point distribution validation)
   - Rubric::NormalizationService (fixing point inconsistencies)
2. Write tests for StudentSubmission services:
   - StudentSubmission::CreationService 
   - StudentSubmission::GradingService
3. Write tests for GradingTaskSummary services:
   - GradingTaskSummary::CreationService
   - GradingTaskSummary::StatisticalAnalysisService
4. Implement all services following TDD approach
5. Update controller tests for GradingTask lifecycle

### Phase 3: AI Integration
1. Write tests for all AI service classes:
   - AI::StudentSubmission::DocumentAnalysisService
   - AI::StudentSubmission::RubricEvaluationService
   - AI::StudentSubmission::FeedbackGenerationService
   - AI::StudentSubmission::EvidenceExtractionService
   - AI::Rubric::ParsingService
   - AI::Rubric::GenerationService
   - AI::GradingService and its subservices
2. Implement LLM prompt templates for each service
3. Create response parsers for structured LLM outputs
4. Implement rate limiting (1 LLM request per grading task at a time)
5. Write tests for GradingTaskJob
6. Implement GradingTaskJob for asynchronous processing

### Phase 4: UI Updates
1. Update grading task form to handle rubrics (new, pasted, existing selection)
2. Update student submission feedback UI to show structured rubric scores
3. Create UI components for teacher adjustment of scores
4. Implement Turbo Stream updates for real-time feedback editing

## Sample Rubric Schema Example

```ruby
# Rubric
{
  id: 1,
  title: "Literary Analysis Essay Rubric",
  user_id: 42,
  total_points: 100,
  raw_content: "Original pasted rubric text...",
  status: "complete",
  created_at: "2025-04-08T22:00:00-06:00",
  updated_at: "2025-04-08T22:05:30-06:00"
}

# Criteria (belonging to Rubric 1)
[
  {
    id: 1,
    rubric_id: 1,
    title: "Thesis Statement",
    description: "Clear main argument that addresses the prompt in a thoughtful way",
    points: 25,
    position: 1
  },
  {
    id: 2,
    rubric_id: 1,
    title: "Evidence & Analysis",
    description: "Relevant textual support and insightful interpretation",
    points: 30,
    position: 2
  },
  {
    id: 3,
    rubric_id: 1,
    title: "Organization",
    description: "Logical flow with effective transitions and paragraphing",
    points: 20,
    position: 3
  },
  {
    id: 4,
    rubric_id: 1,
    title: "Language & Style",
    description: "Effective language with appropriate academic tone",
    points: 15,
    position: 4
  },
  {
    id: 5,
    rubric_id: 1,
    title: "Mechanics",
    description: "Grammar, punctuation, and formatting conventions",
    points: 10,
    position: 5
  }
]

# Levels (for Criterion 1 - Thesis Statement)
[
  {
    id: 1,
    criterion_id: 1,
    title: "Excellent",
    description: "Thesis is insightful, nuanced, and addresses the prompt with sophistication. Shows original thinking.",
    points: 25,
    position: 1
  },
  {
    id: 2,
    criterion_id: 1,
    title: "Advanced Proficient",
    description: "Thesis is clear, thoughtful, and addresses all aspects of the prompt effectively.",
    points: 22,
    position: 2
  },
  {
    id: 3,
    criterion_id: 1,
    title: "Proficient",
    description: "Thesis addresses the prompt and is generally clear, though may lack nuance.",
    points: 20,
    position: 3
  },
  {
    id: 4,
    criterion_id: 1,
    title: "Developing",
    description: "Thesis is present but vague or only partially addresses the prompt.",
    points: 17,
    position: 4
  },
  {
    id: 5,
    criterion_id: 1,
    title: "Beginning",
    description: "Thesis is unclear, missing, or fails to address the prompt.",
    points: 15,
    position: 5
  }
]

# RubricCriterionScore
{
  id: 42,
  student_submission_id: 123,
  criterion_id: 1,
  points_earned: 22,
  level_id: 2,
  reason: "The thesis addresses all parts of the prompt with a clear argument about the character's motivation, though it could have explored the societal implications more deeply.",
  evidence: "\"The protagonist's refusal to conform represents not just personal rebellion but a rejection of systemic injustice...\"",
  created_at: "2025-04-09T10:30:00-06:00",
  updated_at: "2025-04-09T10:30:00-06:00"
}
```

## Deployment Strategy
- One-time migration to clear existing data
- Deploy all changes at once using Kamal
- No special rollout needed as we don't have real users yet

## Additional Considerations
1. Error handling leverages existing LLM service error handling
2. Rate limiting implemented as 1 LLM request per grading task at a time
3. No tracking of teacher edits for AI improvement (using external APIs only)
4. No additional system tests required
