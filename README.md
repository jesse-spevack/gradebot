# GradeBot

AI-powered assignment grading system that automates feedback for student work in Google Docs. Built with Rails 8, integrates with Google Drive, and uses LLM technology for intelligent grading.

## Features
See: [Change log](/changelog.md)

## Setup
Requires Google OAuth credentials and LLM API key.

## Product vision
See: [Gradebot-prd](/documentation/gradebot-prd.md)

## Troubleshooting

### Common Issues

1. `kamal deploy` fails on step #12
   - Run `kamal prune all` and then `kamal deploy --verbose` 
2. When assets are messed up, run `kamal shell`, and then:

```ruby
rails@34:/rails$ rm -rf /rails/public/assets/*
rails@34:/rails$ mkdir -p /rails/public/assets
rails@34:/rails$ chmod -R 777 /rails/public/assets
rails@34:/rails$       bundle exec rails assets:precompile
```
   
## Competition 
- [EssayGrader](https://www.essaygrader.ai/)
- [BriskTeaching](https://www.briskteaching.com/)
- [CogGrader](https://cograder.com/)