# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2026-04-19]
### Added
- Implement `Assignment` model with attributes, associations (user, rubric, student_works, assignment_summary), and validations (title, subject, grade_level).
- Add database migration for the `assignments` table with appropriate constraints.
- Create model tests and fixtures for the `Assignment` model.
