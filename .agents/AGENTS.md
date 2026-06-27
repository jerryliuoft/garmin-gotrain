# Garmin GoTrain Widget App

This file contains the core project rules, context, and structural guidelines for the `garmin-gotrain` project.

## Project Context
- **Description**: This is a widget application for Garmin watches.
- **Goal**: Because it is intended for a watch, all implementations must be kept **as lean as possible** to preserve memory and ensure smooth performance. 

## Project Structure
- `source/`: Contains the Monkey C source code (e.g., `GotrainApp.mc`, `GotrainView.mc`, `GlanceView.mc`, etc.).
- `resources/`: Contains the app resources (layouts, strings, drawables).
- `bin/`: Used for compiled builds and executables.
- `manifest.xml`: The Garmin application manifest.
- `monkey.jungle`: The Monkey C build configuration.

## Operating System & Scripts
- **OS**: The development environment is Windows.
- **Rule**: **NO bash scripts**. Any terminal commands must be compatible with Windows/PowerShell.

## Testing & Quality Assurance
- **TDD Preferred**: We prefer Test-Driven Development (TDD) to ensure code reliability and prevent regressions.
- **Unit Tests**: All new features and logic must have accompanying unit tests. Everything should be thoroughly tested.
- **Committing**: Do not commit any changes unless all tests are passing AND the user has explicitly instructed you to commit. Before committing, you must inform the user of all file changes and highlight any potential regressions that require manual verification.

## Communication Guidelines
- **Avoid XY Problem**: When the user asks a question about how to do something, proactively analyze if the requested approach is the best solution for their underlying problem. Ask clarifying questions back to ensure the root problem is being solved rather than just fulfilling a potentially flawed request.
