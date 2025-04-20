# GradeBot Rebuild Plan

## Domain Model Structure

This document outlines the plan for rebuilding the GradeBot grading system using a command-centric domain model approach that aligns with the Google Classroom rubric schema.

### Core Model Relationships

```
GradingTask
│
├── AssignmentPrompt (many-to-one)
│
├── Rubric (many-to-one)
│   ├── Criterion (one-to-many)
│   │   └── Level (one-to-many)
│   │
│   └── RubricTemplate (optional)
│
└── StudentSubmission (one-to-many)
    ├── DocumentReference
    ├── FeedbackContent
    ├── StrengthPoint (one-to-many)
    ├── ImprovementPoint (one-to-many)
    └── RubricScore
        └── CriterionScore (one-to-many)
```

### Model Details

#### GradingTask
- Central entity representing a grading assignment
- Contains settings for feedback style, AI assistance level, plagiarism check
- Statuses: draft, in_progress, complete

#### AssignmentPrompt
- Reusable component that can be shared across multiple grading tasks
- Attributes: title, content (rich text), word_count, grade_level, subject/course
- Supports AI enhancement for clarity and structure

#### Rubric System
- **Rubric**: Container with name, description, total_points
- **Criterion**: Individual grading categories (e.g., "Argument", "Evidence")
  - Attributes: title, description, weight
- **Level**: Scoring levels for each criterion
  - Attributes: title, description, points

#### StudentSubmission
- Links student work to the grading task
- Contains document reference (Google Doc ID)
- Tracks grading status: pending, in_progress, graded
- Includes feedback components:
  - Overall comment (rich text)
  - Strength points (prioritized list)
  - Improvement points (prioritized list)
  - Rubric scores for each criterion

## Implementation Approach

We'll use a **Command-Centric Structure** with the following characteristics:

1. **Core Models**: Normalized database structure for key entities

2. **Rich Command Objects**:
   - `CreateGradingTaskCommand`
   - `BuildRubricCommand`
   - `ProcessSubmissionCommand`
   - `GenerateFeedbackCommand`
   - `CalculateRubricScoreCommand`

3. **Service Objects** for orchestrating complex operations:
   - `RubricBuilder` - Creates and manages rubrics
   - `SubmissionProcessor` - Handles document extraction
   - `FeedbackGenerator` - Creates AI-powered feedback
   - `GradingEngine` - Coordinates the overall grading process

## Implementation Plan

### Phase 1: Core Models
1. Define and implement database schema
2. Build model validations and relationships
3. Develop basic CRUD operations

### Phase 2: Command Structure
1. Implement command infrastructure
2. Create core command objects
3. Build service objects for workflow management

### Phase 3: Google Integration
1. Implement Google API integrations
2. Build document picker and handling
3. Set up document content extraction

### Phase 4: AI Enhancement
1. Integrate AI for rubric generation
2. Build feedback generation system
3. Implement scoring assistance

## Notes

- All models should follow single responsibility principle
- Use service objects for complex domain logic
- Maintain clear boundaries between components
- Consider strategic use of JSON for complex nested structures (rubric criteria/levels)
