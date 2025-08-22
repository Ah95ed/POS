---
description: Repository Information Overview
alwaysApply: true
---

# POS System Information

## Summary
A Point of Sale (POS) system built with Flutter that provides inventory management, sales tracking, and reporting capabilities. The application follows clean architecture principles with a focus on maintainable code structure and state management using the Provider pattern.

## Structure
The project follows a well-organized structure with clear separation of concerns:
- **lib/Controller/**: Contains Provider classes for state management
- **lib/Model/**: Data models representing business entities
- **lib/Repository/**: Data access layer for database operations
- **lib/View/**: UI components including screens and widgets
- **lib/Helper/**: Utility classes and services

## Language & Runtime
**Language**: Dart
**Version**: SDK ^3.9.0
**Framework**: Flutter
**Build System**: Flutter build system
**Package Manager**: pub (Flutter/Dart package manager)

## Dependencies
**Main Dependencies**:
- **provider**: State management solution
- **sqflite** & **sqflite_common_ffi**: SQLite database access
- **path** & **path_provider**: File system path management
- **smart_sizer**: Responsive UI scaling
- **shared_preferences**: Local storage for preferences
- **flutter_localizations**: Internationalization support
- **pdf** & **printing**: PDF generation and printing capabilities

**Development Dependencies**:
- **flutter_test**: Testing framework
- **flutter_lints**: Linting rules for code quality

## Build & Installation
```bash
flutter pub get
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
flutter build windows         # For Windows
flutter build linux           # For Linux
flutter build macos           # For macOS
flutter build web             # For Web
```

## Clean Code Architecture
The project implements a clean architecture approach with:

**1. Separation of Concerns**:
- **Models**: Pure data classes with business logic (ProductModel, SaleModel)
- **Repositories**: Data access layer (ProductRepository, SaleRepository)
- **Controllers/Providers**: State management (ProductProvider, SaleProvider)
- **Views**: UI components with minimal business logic

**2. Error Handling**:
- Custom `Result<T>` class for consistent error handling across the application
- Clear error states in providers with user-friendly messages

**3. State Management**:
- Provider pattern for reactive state management
- Clear state variables and notifiers
- Separation of UI state from business logic
- Efficient state updates with granular notifyListeners() calls

**4. Clean Code Practices**:
- Consistent naming conventions (Arabic/English bilingual comments)
- Immutable data models with copyWith patterns
- Extension methods for common operations
- Comprehensive error handling
- Pagination support for large datasets

## Database
**Type**: SQLite (sqflite)
**Configuration**: Cross-platform implementation with platform-specific optimizations
**Tables**:
- Items: Product inventory
- Account: User accounts

**Features**:
- Platform-specific database initialization
- Optimized batch operations
- Search capabilities
- Transaction support

## Multilingual Support
The application supports multiple languages through:
- Flutter localization system
- Custom LanguageController for language switching
- Arabic language support with right-to-left (RTL) text direction

## Testing
**Framework**: flutter_test
**Test Location**: test/ directory
**Run Command**:
```bash
flutter test
```