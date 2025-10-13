# Contributing to RailsPress

First off, thank you for considering contributing to RailsPress! It's people like you that make RailsPress such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the [RailsPress Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps which reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include screenshots if possible**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a step-by-step description of the suggested enhancement**
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior and explain which behavior you expected to see instead**

### Pull Requests

* Fill in the required template
* Follow the Ruby/Rails style guides
* Include appropriate test coverage
* Update documentation as needed
* Follow conventional commits format

## Development Setup

1. Fork and clone the repository
2. Run setup script:
   ```bash
   ./railspress setup
   ```
3. Create a branch for your changes:
   ```bash
   git checkout -b feature/my-new-feature
   ```

## Coding Standards

### Ruby Style Guide

We use [Standard Ruby](https://github.com/testdouble/standard) for code style:

```bash
bundle exec standardrb
```

Auto-fix issues:

```bash
bundle exec standardrb --fix
```

### Conventional Commits

We use [Conventional Commits](https://www.conventionalcommits.org/) for clear and semantic commit messages:

```
feat: add CKEditor 5 integration
fix: resolve Tailwind CSS loading issue
docs: update API documentation
test: add specs for Post model
refactor: extract tenant logic to concern
perf: optimize database queries in posts controller
chore: update dependencies
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, missing semi colons, etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Testing

All features should include tests:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/post_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Test Coverage

We aim for >80% test coverage. Coverage reports are generated in `coverage/` directory.

## Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/) format
3. Ensure all tests pass and coverage is maintained
4. Run security scans:
   ```bash
   bundle exec brakeman
   bundle exec bundler-audit check --update
   ```
5. Request review from maintainers
6. Once approved, your PR will be merged

## Project Structure

```
railspress/
├── app/
│   ├── controllers/      # Controllers (Admin, API, Public)
│   ├── models/           # ActiveRecord models
│   ├── views/            # View templates
│   ├── mailers/          # Email mailers
│   └── themes/           # Theme system
├── lib/
│   ├── railspress/       # Core CMS logic
│   └── plugins/          # Plugin system
├── spec/                 # RSpec tests
├── config/               # Configuration
└── db/                   # Database migrations & seeds
```

## Making Changes

### Adding a New Feature

1. Create migration if needed
2. Add/update model with validations and associations
3. Create controller actions
4. Add views
5. Add tests (model, controller, system)
6. Update documentation
7. Add to CHANGELOG.md

### Adding a Plugin

1. Create plugin directory in `lib/plugins/your_plugin/`
2. Inherit from `Railspress::PluginBase`
3. Implement `activate` and `deactivate` methods
4. Register hooks/filters
5. Add documentation
6. Add tests

### Adding a Theme

1. Create theme directory in `app/themes/your_theme/`
2. Add `config.yml`
3. Create views and helpers
4. Add `theme.rb` for hooks/filters
5. Document theme features

## Questions?

Feel free to open an issue for discussion or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.



