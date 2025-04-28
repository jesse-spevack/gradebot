# Git Naming Conventions

## Commit Messages

All commit messages should follow this format:
```
<type>[#task-id]: <short summary>
```

### Types
- `feat` - A new feature
- `fix` - A bug fix
- `docs` - Documentation changes
- `style` - Formatting, missing semicolons, etc (no code change)
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `test` - Adding or refactoring tests
- `chore` - Updating build tasks, package manager configs, etc

### Examples
```
feat#22: add user authentication
fix#45: resolve pagination bug in user list
refactor#18: simplify product search algorithm
docs#33: update API documentation
test#27: add tests for payment processor
```

## Branch Names

Branch names should follow this format:
```
<type>/<task-id>-<short-description>
```

### Examples
```
feat/22-user-auth
fix/45-pagination-bug
refactor/18-search-algorithm
docs/33-api-updates
test/27-payment-processor
```

## Why This Convention?

This naming convention:
- Makes the purpose of each commit and branch immediately clear
- Creates consistency across the project
- Simplifies code review and history tracking
- Helps automate changelog generation
- Follows industry-standard patterns without unnecessary complexity

## GitHub Pull Request Template

When creating a pull request, use this template in the PR description:

```
## Task ID
#[Insert task ID number]

## Description
Description of the changes made in github friendly markdown.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Test updates
- [ ] Other (please describe)

## Testing
Describe the tests that you ran to verify your changes.
```

This template ensures all PRs contain consistent information and encourages proper documentation of changes. The task ID at the top makes it easy to link PRs to their corresponding tasks.

## Tips

- Keep descriptions concise but clear
- Use present tense in commit messages ("add feature" not "added feature")
- Use hyphens to separate words in branch names
- Always include the task ID in both commit messages and branch names
- For quick reference, the task ID should appear in both locations (e.g., commit message `feat#22` and branch name `feat/22-user-auth`)