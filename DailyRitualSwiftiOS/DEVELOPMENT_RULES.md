# Development Rules & Best Practices

This file establishes development standards for the Daily Dose project based on John Ousterhout's "A Philosophy of Software Design" principles and iOS best practices.

## Core Design Philosophy

### 1. Deep Modules - Hide Complexity Behind Simple Interfaces

**Principle**: Create modules that provide substantial functionality through simple, clean interfaces.

**Application**:
- `SupabaseManager` should hide all backend complexity behind simple async methods
- View Models should encapsulate business logic and expose only necessary state
- AI service integration should be abstracted behind clear, purpose-driven interfaces

**Examples**:
```swift
// GOOD: Simple interface, complex implementation hidden
func generateAffirmation(for goals: [String]) async throws -> String

// BAD: Exposing implementation details
func callClaudeAPIWithPromptAndContextAndRetry(prompt: String, context: [String], retryCount: Int) async throws -> String
```

### 2. Information Hiding - Encapsulate Design Decisions

**Principle**: Each module should hide its internal design decisions and implementation details.

**Application**:
- Database schema details should be hidden within `SupabaseManager`
- View state management should be encapsulated in ViewModels
- Network implementation details should not leak to UI layers

**Rules**:
- Use `private` and `fileprivate` aggressively
- Expose only what other modules absolutely need
- Keep implementation details internal to the module

### 3. General-Purpose Modules - Design for Reusability

**Principle**: Design interfaces to be general enough to support multiple uses.

**Application**:
- Create reusable UI components that work across different contexts
- Design data models that can be extended without breaking existing code
- Build services that can handle various use cases

**Examples**:
```swift
// GOOD: General-purpose, extensible
protocol AIContentGenerator {
    func generateContent(for type: ContentType, context: GenerationContext) async throws -> String
}

// BAD: Too specific, hard to extend
func generateMorningAffirmationForGoals(_ goals: [String]) async throws -> String
```

### 4. Push Complexity Downwards - Keep Interfaces Simple

**Principle**: It's better to have a more complex implementation if it makes the interface simpler.

**Application**:
- ViewModels should handle complexity so Views remain simple
- Service layers should handle error recovery and retry logic internally
- Complex state management should be hidden from UI components

**Rules**:
- Views should focus purely on presentation
- Business logic complexity should live in dedicated layers
- Error handling should be centralized and abstracted

### 5. Consistency - Maintain Uniformity

**Principle**: Consistent design patterns reduce cognitive load and errors.

**Application**:
- Use consistent naming conventions across the project
- Apply the same architectural patterns throughout
- Maintain consistent error handling approaches

## Project-Specific Rules

### Architecture Standards

#### MVVM Pattern Implementation
```swift
// Standard ViewModel structure
@MainActor
class [Feature]ViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var errorMessage: String?
    
    private let service: ServiceProtocol
    
    // Public interface methods only
    func performAction() async { /* implementation */ }
    
    // Private helper methods
    private func handleError(_ error: Error) { /* implementation */ }
}
```

#### Service Layer Pattern
```swift
// Standard service interface
protocol ServiceProtocol {
    func performOperation() async throws -> Result
}

// Implementation hides complexity
class ConcreteService: ServiceProtocol {
    func performOperation() async throws -> Result {
        // Complex implementation hidden here
    }
}
```

### Code Organization Rules

#### File Structure
- One primary type per file
- Related extensions in the same file
- Group related functionality together
- Use `// MARK: -` for section organization

#### Naming Conventions
- Use clear, descriptive names that explain purpose
- Avoid abbreviations unless universally understood
- Boolean properties should be questions: `isComplete`, `canProceed`
- Methods should be verbs: `generateContent`, `updateEntry`

#### Error Handling Standards
```swift
// Consistent error handling pattern
enum ServiceError: LocalizedError {
    case networkFailure
    case invalidData
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .networkFailure: return "Network connection failed"
        case .invalidData: return "Invalid data received"
        case .authenticationRequired: return "Authentication required"
        }
    }
}
```

### SwiftUI Best Practices

#### View Composition
- Break large views into smaller, focused components
- Use `@ViewBuilder` for reusable view logic
- Prefer composition over inheritance

#### State Management
- Use `@State` for local view state only
- Use `@StateObject` for view-owned objects
- Use `@ObservedObject` for injected dependencies
- Use `@EnvironmentObject` for app-wide shared state

#### Performance Considerations
- Avoid expensive operations in view body
- Use `@State` and `@Binding` appropriately
- Implement proper `Equatable` conformance for complex data

### Data Management

#### Model Design
```swift
// Well-designed model with clear responsibilities
struct DailyEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let date: Date
    
    // Grouped related properties
    var morningRitual: MorningRitual
    var eveningReflection: EveningReflection
    
    // Computed properties for derived state
    var isMorningComplete: Bool { morningRitual.isComplete }
    var isEveningComplete: Bool { eveningReflection.isComplete }
}
```

#### Async/Await Standards
- Always use `async throws` for operations that can fail
- Handle errors at the appropriate level
- Use proper cancellation handling
- Avoid blocking the main thread

### Testing Standards

#### Unit Test Structure
```swift
@Test("Description of what is being tested")
func testSpecificBehavior() async throws {
    // Given - setup
    let viewModel = ViewModel(service: MockService())
    
    // When - action
    await viewModel.performAction()
    
    // Then - verification
    #expect(viewModel.state == .success)
}
```

#### Test Categories
- Unit tests for ViewModels and Services
- Integration tests for data flow
- UI tests for critical user journeys
- Performance tests for heavy operations

### Documentation Standards

#### Code Comments
- Explain **why**, not **what**
- Document complex business logic
- Add TODO/FIXME comments for technical debt
- Use `///` for public API documentation

#### Architecture Documentation
- Keep architectural decisions documented
- Update documentation when patterns change
- Document integration points and dependencies

### Performance Guidelines

#### Memory Management
- Use weak references to break retain cycles
- Implement proper cleanup in deinitializers
- Monitor memory usage in complex views

#### Network Optimization
- Implement proper caching strategies
- Use efficient data serialization
- Handle offline scenarios gracefully

#### UI Performance
- Avoid expensive operations in view updates
- Use lazy loading for large datasets
- Implement proper list virtualization

### Security Considerations

#### Data Protection
- Never store sensitive data in UserDefaults
- Use Keychain for secure storage
- Implement proper data encryption

#### API Security
- Use proper authentication tokens
- Implement certificate pinning
- Validate all input data

## Code Review Checklist

### Before Submitting
- [ ] Code follows established patterns
- [ ] All public interfaces are well-designed
- [ ] Complex logic is properly abstracted
- [ ] Error handling is consistent
- [ ] Tests cover new functionality
- [ ] Documentation is updated

### During Review
- [ ] Interfaces are simple and clear
- [ ] Complexity is pushed to appropriate layers
- [ ] Code is consistent with project standards
- [ ] Performance implications are considered
- [ ] Security best practices are followed

## Refactoring Guidelines

### When to Refactor
- Code becomes difficult to understand
- Interfaces become too complex
- Duplication increases significantly
- Performance degrades noticeably

### How to Refactor Safely
1. Write tests for existing behavior
2. Make small, incremental changes
3. Verify tests pass after each change
4. Update documentation as needed

### Red Flags
- Methods with more than 3-4 parameters
- Classes with more than 10 public methods
- Deep inheritance hierarchies
- Tight coupling between modules

## Conclusion

These rules prioritize **simplicity**, **clarity**, and **maintainability** over clever or complex solutions. When in doubt, choose the approach that makes the code easier to understand and modify.

Remember: "The best code is code that doesn't need to exist, but when it must exist, it should be obvious what it does."
