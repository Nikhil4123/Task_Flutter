# 📋 TaskManager - Firebase Edition

A comprehensive task management application built with Flutter and Firebase, designed for cross-platform deployment with real-time data synchronization and push notifications.

## ✨ Features

### 🔐 Authentication
- Email/Password registration and login
- Anonymous sign-in for guest users
- Password reset functionality
- User profile management

### 📝 Task Management
- Create, edit, and delete tasks
- Set task priorities (Low, Medium, High, Urgent)
- Due date and time scheduling
- Task status tracking (Pending, In Progress, Completed, Cancelled)
- Tag-based organization
- Search and filter capabilities

### 🔔 Smart Notifications
- Push notifications for task reminders
- Due date alerts
- Overdue task notifications
- Background notification handling

### 📊 Advanced Features
- Real-time data synchronization across devices
- Offline data persistence
- Task statistics and analytics
- Bulk task operations
- Responsive UI for all screen sizes

### 🎨 User Experience
- Material Design 3 components
- Dark/Light theme support
- Intuitive navigation
- Pull-to-refresh functionality
- Error handling and loading states

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.8.0)
- Dart SDK
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/taskmanager.git
cd taskmanager
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**
   - Follow the [Deployment Guide](DEPLOYMENT_GUIDE.md) for complete Firebase configuration
   - Update `lib/firebase_options.dart` with your project credentials

4. **Run the application**
```bash
flutter run
```

## 🏗️ Project Architecture

### 📁 Directory Structure
```
lib/
├── models/          # Data models (Task, User)
├── services/        # Firebase services (Auth, Firestore, FCM)
├── providers/       # State management (Provider pattern)
├── screens/         # UI screens (Login, Home, Add Task)
├── widgets/         # Reusable UI components
├── utils/           # Utility functions and helpers
├── firebase_options.dart  # Firebase configuration
└── main.dart        # Application entry point
```

### 🔧 Technology Stack
- **Frontend**: Flutter & Dart
- **Backend**: Firebase (Firestore, Auth, FCM)
- **State Management**: Provider
- **Local Storage**: Firestore offline persistence
- **Notifications**: Firebase Cloud Messaging
- **Authentication**: Firebase Authentication

### 📱 Supported Platforms
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🔧 Development

### Running in Development
```bash
# Debug mode
flutter run

# Specific platform
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Widget tests
flutter test test/widget_test.dart
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Check dependencies
flutter pub deps
```

## 📦 Building for Production

### Android
```bash
# APK for testing
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# iOS build (requires Xcode)
flutter build ios --release
```

### Web
```bash
# Web build
flutter build web --release
```

## 🔒 Security Features

### Data Security
- Firestore security rules for user data isolation
- Authentication-based access control
- Input validation and sanitization
- Secure data transmission (HTTPS)

### Privacy
- Local data encryption
- User consent management
- Minimal data collection
- GDPR compliance ready

## 📊 Firebase Services Used

### 🔥 Firebase Services Used

### 🔐 Firebase Authentication
- Email/Password authentication
- Anonymous sign-in for guest users
- Password reset functionality
- User profile management
- Multi-platform session handling

### 🔥 Firestore Database
- Real-time task synchronization across devices
- Offline data persistence with automatic sync
- Scalable NoSQL database with advanced querying
- User-based data isolation and security
- Collections: users, tasks, categories, analytics

### 📁 Firebase Storage
- User profile image uploads
- Task file attachments (images, PDFs, documents)
- Secure file access with user-based permissions
- Automatic file compression and optimization
- Cross-platform file handling

### 📱 Firebase Cloud Messaging
- Cross-platform push notifications
- Task reminder notifications
- Due date and overdue alerts
- Background message handling
- Rich notification content with actions

## 🎯 Usage Examples

### Creating a Task
```dart
final task = Task.create(
  title: 'Complete project',
  description: 'Finish the TaskManager app',
  userId: user.id,
  dueDate: DateTime.now().add(Duration(days: 1)),
  priority: TaskPriority.high,
  tags: ['work', 'urgent'],
);

await taskProvider.createTask(task);
```

### Listening to Task Updates
```dart
Consumer<TaskProvider>(
  builder: (context, taskProvider, child) {
    return ListView.builder(
      itemCount: taskProvider.tasks.length,
      itemBuilder: (context, index) {
        return TaskItem(task: taskProvider.tasks[index]);
      },
    );
  },
)
```

## 🔄 State Management

The app uses the Provider pattern for state management:

- **AuthProvider**: Manages authentication state
- **TaskProvider**: Handles task operations and filtering
- Real-time updates through Firebase streams
- Optimistic UI updates for better UX

## 🎨 UI Components

### Reusable Widgets
- `TaskItem`: Individual task display with actions
- `TaskFilterChip`: Filter UI component
- Custom form inputs with validation
- Loading and error state widgets

### Design System
- Material Design 3 principles
- Consistent color scheme
- Responsive layouts
- Accessibility support

## 📈 Performance Optimizations

### Database
- Efficient Firestore queries with pagination
- Local caching and offline support
- Optimistic updates
- Connection state monitoring

### UI
- Lazy loading of task lists
- Image optimization
- Minimal rebuilds with Provider
- Efficient state management

## 🐛 Troubleshooting

### Common Issues

**Firebase not initialized**
- Ensure `firebase_options.dart` is properly configured
- Check internet connectivity
- Verify Firebase project setup

**Authentication failures**
- Check Firebase Auth configuration
- Verify email/password requirements
- Review security rules

**Tasks not syncing**
- Check Firestore security rules
- Verify user authentication
- Test network connectivity

### Debug Tools
```bash
# Flutter inspector
flutter inspector

# Performance profiling
flutter run --profile

# Network debugging
flutter run --verbose
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Code Style
- Follow Dart style guidelines
- Use meaningful variable names
- Add comments for complex logic
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Documentation
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [API Documentation](docs/API.md)
- [Widget Documentation](docs/WIDGETS.md)

### Getting Help
- 📧 Email: support@taskmanager.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/taskmanager/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/taskmanager/discussions)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for the backend services
- Material Design team for design guidelines
- Contributors and beta testers

---

Built with ❤️ using Flutter and Firebase

## 📊 Statistics

![GitHub stars](https://img.shields.io/github/stars/yourusername/taskmanager?style=social)
![GitHub forks](https://img.shields.io/github/forks/yourusername/taskmanager?style=social)
![GitHub issues](https://img.shields.io/github/issues/yourusername/taskmanager)
![GitHub license](https://img.shields.io/github/license/yourusername/taskmanager)

## 🔮 Roadmap

- [ ] Team collaboration features
- [ ] Task templates
- [ ] Calendar integration
- [ ] Advanced analytics
- [ ] Voice commands
- [ ] AI-powered task suggestions
- [ ] Third-party integrations
- [ ] Desktop widgets