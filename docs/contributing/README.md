# Contributing Guidelines

This section provides guidelines for contributing to the QuitTxT App project, including code style, testing requirements, and the pull request process.

## Contents

- [Code Style](code-style.md): Coding conventions and style guidelines
- [Testing](testing.md): Testing requirements and procedures
- [Pull Request Process](pull-request-process.md): Steps for submitting contributions

## How to Contribute

Contributions to the QuitTxT App are welcome from all developers. Here's how you can contribute:

1. **Find or Create an Issue**:
   - Check existing issues for tasks that need help
   - Create a new issue if you find a bug or have a feature request

2. **Fork the Repository**:
   - Fork the repository to your GitHub account
   - Clone your fork to your local machine

3. **Create a Branch**:
   - Create a branch from the `development` branch
   - Use a descriptive name following the branch naming convention:
     - `feature/feature-name` for new features
     - `fix/bug-description` for bug fixes
     - `refactor/component-name` for refactoring

4. **Make Changes**:
   - Write code following the [code style guidelines](code-style.md)
   - Add or update tests as necessary
   - Ensure all tests pass

5. **Submit a Pull Request**:
   - Push your changes to your fork
   - Create a pull request against the `development` branch
   - Follow the [pull request process](pull-request-process.md)

## Code Style Guidelines

The QuitTxT App follows standard Dart and Flutter coding conventions. Key points include:

- Use `camelCase` for variables and methods, `PascalCase` for classes and types
- Follow standard Dart formatting (`dart format .`)
- Organize imports alphabetically
- Use static types whenever possible
- Write clear and concise comments
- Create platform-specific implementations in appropriate directories

[View detailed Code Style Guidelines](code-style.md)

## Testing Requirements

All code contributions should include appropriate tests:

- **Unit Tests**: For individual functions and classes
- **Widget Tests**: For UI components
- **Integration Tests**: For feature workflows

Tests must pass before a pull request can be merged.

[View detailed Testing Guidelines](testing.md)

## Pull Request Process

The pull request process includes:

1. Filling out the pull request template
2. Getting approval from at least one maintainer
3. Ensuring CI checks pass
4. Addressing review comments

[View detailed Pull Request Process](pull-request-process.md)

## Commit Message Guidelines

Commit messages should follow this format:

```
<type>(<scope>): <subject>

<body>
```

Where `<type>` is one of:
- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring without functionality changes
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

Example:
```
feat(messaging): add support for quick replies

- Added QuickReply model
- Implemented UI for quick reply buttons
- Added handling for quick reply selection
```

## Versioning

The project follows semantic versioning (`MAJOR.MINOR.PATCH`):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible functionality additions
- **PATCH**: Backwards-compatible bug fixes

## Questions and Support

If you have questions about contributing, please:

1. Check existing documentation
2. Create an issue with the question
3. Reach out to the maintainers

Thank you for contributing to the QuitTxT App!