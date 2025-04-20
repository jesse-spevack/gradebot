# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2025-04-20]
### Added
- Implement `Criterion` model with attributes (`title`, `description`, `position`), associations (`rubric`, `levels`), validation (`title`), and prefixed ID (`crit_`).
- Add migration for `criteria` table, enforcing `NOT NULL` on `title` and `rubric_id`.
- Add model tests and fixtures for `Criterion`.
- Add `criterion`/`criteria` inflection rule.
- Update `fixtures.mdc` rule to prevent invalid fixtures.

## [2026-04-19]
### Added
- Create `bin/rails check` Rake task to run tests, Rubocop, and Brakeman.
- Implement `Assignment` model with attributes, associations (user, rubric, student_works, assignment_summary), and validations (title, subject, grade_level).
- Add database migration for the `assignments` table with appropriate constraints.
- Create model tests and fixtures for the `Assignment` model.
### Changed
- Updated `.cursor/rules/lessons.mdc` with TDD and fixture management takeaways.
