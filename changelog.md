# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- Refactored `Rubric#display_status` method to use a case statement instead of conditional logic for better readability and maintenance
- Added comprehensive test for `Rubric#display_status` method to ensure correct status translation
- Fixed `grading_tasks` association in `Rubric` model to include `dependent: :destroy` for proper cleanup
