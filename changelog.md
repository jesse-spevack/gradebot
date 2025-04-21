# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2025-04-20]
Implemented foundational models for rubric-based assessment, student work evaluation, and the assignments management interface.
### Added
- Implement `Criterion` model with attributes (`title`, `description`, `position`), associations (`rubric`, `levels`), validation (`title`), and prefixed ID (`crit_`).
- Add migration for `criteria` table, enforcing `NOT NULL` on `title` and `rubric_id`.
- Add model tests and fixtures for `Criterion`.
- Add `criterion`/`criteria` inflection rule.
- Update `fixtures.mdc` rule to prevent invalid fixtures.
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
