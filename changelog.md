# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2025-04-23]
### Added
- Implemented `Assignment::InitializerService` to orchestrate the creation of Assignments, Selected Documents, and Student Works within a single transaction, including enqueuing `AssignmentProcessingJob`.
- Added integration tests for `Assignment::InitializerService` covering success and invalid parameter scenarios.
- Added `has_many :selected_documents` association to the `Assignment` model.
- Implemented `SelectedDocument::BulkCreationService` for efficient bulk creation of selected documents associated with assignments, using `insert_all!` for performance.
- Service enforces a maximum of 35 documents per assignment and stores doc ID, URL, and title.
- Added comprehensive tests for valid creation, limit enforcement, and transactional integrity.
- Implemented `StudentWork::BulkCreationService` for efficient creation of multiple `StudentWork` records from `SelectedDocument` records using `insert_all` (Task 17).
- Implemented `Assignments::BulkCreationService` to create Assignment records for each selected Google Document (Task 15).
- Added `google_doc_id` and `url` to `selected_documents` table (Task 16).
### Changed
- Refactored `AssignmentsController#create` to utilize `Assignment::InitializerService`.
- Corrected `selected_documents_params` in `AssignmentsController` to properly permit an array of document hashes.
- Standardized the keyword argument for passing document data to services as `document_data`.
- Refactored `Assignment::InitializerService` to return the `Assignment` object on success and `false` on failure/rollback, and added an `attr_reader` for the assignment object.
- Removed unique index on `google_doc_id` from `selected_documents` to allow the same Google Doc to be selected for multiple assignments.
- Updated migration and schema to reflect non-unique index on `google_doc_id`.

## [2025-04-22]
Enhanced the Google Document Picker UI and improved design system consistency across the application.
### Added
- Created a shared Google icon partial at `app/views/shared/icons/_google.html.erb`
- Added comprehensive design system rules in `.cursor/rules/design.mdc` to ensure UI consistency
- Implemented dynamic UI updates for the document selection interface
- New navbar section for Assignments under "Beta features"
- Added `feedback_tone` attribute to the `Assignment` model (defaulting to 'constructive') to allow configuration of feedback style.
### Changed
- Completely redid the Assignments form
- Enhanced the Google Document Picker to show/hide buttons based on selection state
- Updated the Assignments index page to match the design system of the new assignment form
- Improved button styling to use consistent inline-flex pattern with proper spacing
- Fixed form structure to ensure all form elements are properly contained within the form tag
- Standardized card styling with consistent shadows, padding, and hover effects

## [2025-04-20]
Implemented foundational models for rubric-based assessment, student work evaluation, and the assignments management interface.
### Added
- Implement `Criterion` model with attributes (`title`, `description`, `position`), associations (`rubric`, `levels`), validation (`title`), and prefixed ID (`crit_`).
- Add migration for `criteria` table, enforcing `NOT NULL` on `title` and `rubric_id`.
- Add model tests and fixtures for `Criterion`.
- Add `criterion`/`criteria` inflection rule.
- Update `fixtures.mdc` rule to prevent non-conforming fixtures.
- Implement `Level` model with attributes (`title`, `description`, `position`), association (`criterion`), validation (`title`), and prefixed ID (`lvl_`).
- Add migration for `levels` table, enforcing `NOT NULL` on `title` and `criterion_id`.
- Add model tests and fixtures for `Level`.
- Create `prefix_ids.mdc` rule.
- Implement `StudentWork` model with attributes (`qualitative_feedback`, `status`), associations (`assignment`, `feedback_items`, `student_work_checks` with `dependent: :destroy`), validation (`assignment`), enum (`status`), and prefixed ID (`sw_`).
- Add migration for `student_works` table with `status` enum (default: `pending`) and index.
- Add model tests and fixtures for `StudentWork`.
- Create `enum.mdc` rule.
- Implement polymorphic `FeedbackItem` model with attributes (`title`, `description`, `evidence`, `kind`), associations (`feedbackable`), validations (`feedbackable`, `title`, `description`, `kind`), enum (`kind`), and prefixed ID (`fbk`).
- Add migration for `feedback_items` table with polymorphic references and `kind` enum/index.
- Add model tests and fixtures for `FeedbackItem`.
- Update `StudentWork` model to declare polymorphic `has_many :feedback_items`.
- Implement `StudentWorkCriterionLevel` join model with attributes (`explanation`), associations (`student_work`, `criterion`, `level`), validation (uniqueness on `student_work` + `criterion`), and prefixed ID (`swcl_`).
- Add migration for `student_work_criterion_levels` table with unique index.
- Add model tests and fixtures for `StudentWorkCriterionLevel`.
- Implement `StudentWorkCheck` model with attributes (`explanation`, `check_type`, `score`), association (`student_work`), validations (presence, score range 0-100, conditional score range 1-12 for `writing_grade_level`), enum (`check_type`), and prefixed ID (`chk`).
- Add migration for `student_work_checks` table with `check_type` enum/index.
- Add model tests and fixtures for `StudentWorkCheck`.
- Implement `AssignmentSummary` model with attributes (`student_work_count`, `qualitative_insights`), associations (`assignment`, polymorphic `feedback_items`), validations (presence for all attributes, numericality for count), and prefixed ID (`asum_`).
- Add migration for `assignment_summaries` table with required columns and default for count.
- Add model tests and fixtures for `AssignmentSummary`.
- Implement `SelectedDocument` model (renamed from legacy `DocumentSelection`) with attributes (`google_doc_id`, `title`, `url`), association (`assignment`), validations (presence, uniqueness on `google_doc_id`), and prefixed ID (`sd_`).
- Add migration for `selected_documents` table with required columns and unique index.
- Add model tests and fixtures for `SelectedDocument`.
- Update PRD and tasks to reflect `SelectedDocument` renaming and purpose.
- Implement `AssignmentsController` with actions for index, new, create, show, and destroy.
- Create views for assignments including index page with assignment lists, new form with fields for creating assignments, and show page for displaying assignment details.
- Add authentication tests to ensure proper access control for assignment management.
- Set up routes for assignments resource.

## [2026-04-19]
### Added
- Create `bin/rails check` Rake task to run tests, Rubocop, and Brakeman.
- Implement `Assignment` model with attributes, associations (user, rubric, student_works, assignment_summary), and validations (title, subject, grade_level).
- Add database migration for the `assignments` table with appropriate constraints.
- Create model tests and fixtures for the `Assignment` model.
### Changed
- Updated `.cursor/rules/lessons.mdc` with TDD and fixture management takeaways.
