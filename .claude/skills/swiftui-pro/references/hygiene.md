# Hygiene

- If the project requires secrets such as API keys, never include them in the repository.
- Write no code comment unless it states a why the code and its names cannot.
- Unit tests should exist for core application logic. UI tests only where unit tests are not possible.
- `@AppStorage` must never be used to store usernames, passwords, or other sensitive data. Use the keychain for that.
- If SwiftLint is configured, it should return no warnings or errors.
- If the Xcode MCP is configured, prefer its tools over generic alternatives. For example, `RenderPreview` is able to capture images of rendered SwiftUI previews for examination, and `DocumentationSearch` can search Apple's documentation for latest usage instructions.
