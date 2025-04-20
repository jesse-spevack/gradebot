# Refined Rubric Implementation Plan

## Phase 1: Foundation

### Model Tests and Naming:
- Yes, I'll use RubricCriterionScore instead of RubricScore for better clarity
- For status fields, I think that makes sense. We could add:
  - status enum field on Rubric (pending, processing, complete) for tracking LLM-based generation
  - Similar status field for RubricCriterionScore when grading is in progress

- Comment: We should also add a status field the the student submission and grading task models

### Migrations:
- Agreed on removing all existing data (grading tasks, student submissions, LLM cost logs) as part of our clean slate approach
- I'll create a separate migration specifically for this cleanup

### GradingTask Associations:
- The standard Rails pattern would be belongs_to :rubric on the GradingTask model (with rubric_id column)
- For accessing criteria, we could use:
```ruby
# In GradingTask model
has_one :rubric
has_many :criteria, through: :rubric
```
- This follows Rails conventions and would allow grading_task.rubric and grading_task.criteria as desired

## Phase 2: Rubric Creation
### Service Classes:
- RubricParserService: Takes raw text, processes it with LLM, returns structured rubric
- RubricGeneratorService: Takes assignment prompt, generates rubric with LLM
- Additional services we might need:
  - RubricDuplicatorService: For creating deep copies of existing rubrics
    - comment: We will not need this.
  - RubricValidatorService: For ensuring rubric structure meets requirements
    - since the llm will be creating the rubric either from the assignment prompt or from the raw rubric text, what should happen if the rubric is invalid?

## Controller and Service Structure:
- Good point on using params.permit over params.require for more flexibility
  - This is a security issue: `user_params = params.permit(user: [:name, :age]).require(:user)` is an example.
- The service organization is excellent. I recommend:
```bash
Services/
  ├── GradingTaskCreationService
  ├── AssignmentPromptCreationService
  ├── RubricCreationService
  ├── DocumentSelectionCreationService
  └── StudentSubmissionCreationService
```
- comment: I prefer this:
```bash
Services/
  ├── GradingTask
  │   └── CreationService
  ├── AssignmentPrompt
  │   └── CreationService
  ├── Rubric
  │   └── CreationService
  ├── DocumentSelection
  │   └── CreationService
  └── StudentSubmission
      └── CreationService
```
These would handle object creation quickly with no LLM calls
- The async job approach for LLM processing is the right pattern for responsive UI

## Phase 3: Student Submission Integration
### Controller Logic Clarification:
- I meant implementing the controller actions for teachers to adjust rubric criterion scores
  - comment: Ok, sounds good. Updating the rubric scores, qualitative feedback should not require page refreshes.
    - Can we use turbo streams for writes? Or do we need a stimulus controller to make an ajax request? Or is there another option?
- This would include routes and controller methods for updating scores, feedback, etc.

### AI Services Structure:
- For wholistic qualitative feedback, I suggest adding these fields to the StudentSubmission model:
  - overall_feedback (text): General assessment of the submission
  - strengths (text array or serialized): Key strengths identified
  - areas_for_improvement (text array or serialized): Growth areas
  - comment: Why not their own models? I'm not saying we should definitely do that, I'm just curious what the tradeoffs are.
- The service structure is well thought-out:
  - Ai::StudentSubmissionService: Handles grading and creation of RubricCriterionScores
    - comment: What sub services might we need?
  - Ai::AssignmentPromptService: Formats assignment prompts with HTML
  - Ai::RubricService: Generates/parses rubrics
    - comment: What sub services might we need?
  - Ai::GradingService: Creates summary-level feedback
    - comment: What sub services might we need?

For strengths and weaknesses, I'd recommend using the LLM to generate these based on the rubric scores, but also the entire submission context. This is more holistic than just summarizing the scores.
- comment: do you think we'd make multiple llm calls for this? Or one big call?

## GradingTask Fields:
Good suggestion on adding fields to GradingTask for summary data:
- comment: Should a grading task have a summary object? Again, not saying definitely do this, I want to know the tradeoffs.
```ruby
add_column :grading_tasks, :class_strengths, :text
add_column :grading_tasks, :class_areas_for_growth, :text
add_column :grading_tasks, :teaching_recommendations, :text
add_column :grading_tasks, :summary, :text
```

## Phase 4: UI Updates
### Existing Rubric Selection:
- Will add UI for selecting from previously used rubrics
- Could include search/filtering by subject or grade level

### Teacher Editing Capabilities:
- Will build UI components for:
  - Adjusting criterion scores
  - Editing qualitative feedback
  - Controlling which feedback gets appended to student documents
  - comment no page refresh should be required for any of this.

### Should follow the TDD approach with Stimulus controllers for interactive elements

## Additional Responses
### Default Level Structure:
- Excellent, Advanced Proficient, Proficient, Developing, Beginning is a strong pedagogical progression
- For point distribution, perhaps: 100%, 90%, 80%, 70%, 60% of the criterion's total points

### Validation Strategy:
- Agree that we should validate criterion points sum to total, but with flexibility
- Since this is LLM-generated, we could:
  - Have validation in the model
  - Add a normalization step in the service that adjusts criterion points to total 100 if they're close

### Rubric Duplication:
- Deep copy is the right approach for flexibility and preventing unexpected changes
- The RubricDuplicatorService would handle this cleanly

### Zero-Point Criteria:
- Minimum points makes sense - perhaps 5% of total rubric points as minimum per criterion

### Questions for Further Clarification:
- Should we implement an approval workflow for LLM-generated rubrics? For example, teachers see the generated rubric and can adjust it before finalizing.
  - comment: I think this is a good idea. But let's not do that at first.
- For the criterion levels, should we enforce consistent level terminology across all criteria in a rubric, or allow each criterion to have its own level titles?
  - comment: I think we should enforce consistent level terminology across all criteria in a rubric. But, can you generate a sample rubric in our described schema so we can get more concrete?
- What should the minimum number of criteria be for a valid rubric? Would 3-5 be a good range to enforce?
  - comment: 1-10.
- Would you want the ability to have weighted criteria (some worth more than others) or should all criteria have equal weight in the overall grade?
  - Since a criterion has points, and levels have points doesn't our model already support this?

