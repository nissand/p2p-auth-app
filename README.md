# 🔐 P2P Authentication App

A modern, secure Flutter application that enables peer-to-peer authentication between devices using QR codes and Time-based One-Time Passwords (TOTP). This app provides a seamless way to establish secure connections and verify identities across different platforms.

![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.8.1+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## 📱 Features

### 🔑 Core Authentication
- **QR Code Generation**: Create secure QR codes containing encrypted pairing information
- **QR Code Scanning**: Scan QR codes to establish new device pairings
- **TOTP Generation**: Generate time-based one-time passwords for secure verification
- **Secure Storage**: All sensitive data stored using Flutter Secure Storage

### 🎨 User Experience
- **Modern UI**: Clean Material Design 3 interface with intuitive navigation
- **Cross-Platform**: Works seamlessly on iOS, Android, and Web
- **Real-time Updates**: Live TOTP codes that refresh automatically
- **Offline Capability**: Generate codes without internet connection

### 🔒 Security Features
- **Encrypted QR Codes**: QR codes contain encrypted pairing secrets
- **Secure Key Storage**: All secrets stored in device's secure storage
- **TOTP Standards**: Implements RFC 6238 TOTP standard
- **No Server Dependency**: Direct peer-to-peer communication

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point and theme configuration
├── models/
│   └── pairing.dart         # Pairing data model with JSON serialization
├── screens/
│   ├── home_screen.dart     # Main dashboard with paired devices
│   ├── new_pair_screen.dart # QR code generation interface
│   └── scan_pair_screen.dart # QR code scanning interface
├── services/
│   ├── qr_scanner_service.dart # QR code scanning logic
│   ├── storage_service.dart    # Secure storage operations
│   └── totp_service.dart       # TOTP generation and validation
└── widgets/
    ├── empty_state.dart     # Empty state display widget
    └── pairing_card.dart    # Individual pairing display widget
```

### Key Components

#### 🔧 Services
- **StorageService**: Manages secure storage of pairing data using `flutter_secure_storage`
- **TOTPService**: Handles TOTP generation and validation using the `otp` package
- **QRScannerService**: Manages QR code scanning functionality using `mobile_scanner`

#### 📊 Models
- **Pairing**: Data model representing a device pairing with JSON serialization support

#### 🎯 Screens
- **HomeScreen**: Dashboard showing all paired devices with live TOTP codes
- **NewPairScreen**: Interface for creating new pairings and generating QR codes
- **ScanPairScreen**: QR code scanner for establishing new connections

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.8.1 or higher
- **Dart SDK**: 3.8.1 or higher
- **Development Environment**:
  - iOS: Xcode 14+ (for iOS development)
  - Android: Android Studio (for Android development)
  - Web: Chrome browser (for web development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/nissand/p2p-auth-app.git
   cd p2p-auth-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # For iOS Simulator
   flutter run -d ios
   
   # For Android Emulator
   flutter run -d android
   
   # For Web Browser
   flutter run -d chrome
   ```

### Platform-Specific Setup

#### iOS Setup
If you encounter CocoaPods sync issues:
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
```

#### Android Setup
Ensure you have the latest Android SDK and build tools installed.

#### Web Setup
The app works out of the box in modern browsers with camera access for QR scanning.

## 📖 Usage Guide

### Creating a New Pairing

1. **Open the app** and tap the "+" button on the home screen
2. **Enter your name** and your partner's name
3. **Generate QR code** - the app creates a secure QR code with encrypted pairing information
4. **Share the QR code** with your partner (screenshot, display on screen, etc.)

### Scanning a QR Code

1. **Tap "Scan QR Code"** on the home screen
2. **Grant camera permissions** when prompted
3. **Point camera** at the QR code displayed on your partner's device
4. **Confirm pairing** - the app will establish the secure connection

### Using TOTP Codes

1. **View paired devices** on the home screen
2. **See live TOTP codes** that refresh every 30 seconds
3. **Use codes for authentication** in your target application
4. **Codes are synchronized** between paired devices

### Managing Pairings

- **View all pairings** on the home screen
- **See creation dates** and partner names
- **Live TOTP codes** update automatically
- **Secure storage** keeps all data encrypted

## 🔧 Technical Details

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_secure_storage` | ^5.0.2 | Secure storage for sensitive data |
| `mobile_scanner` | ^7.0.1 | QR code scanning functionality |
| `qr_flutter` | ^4.1.0 | QR code generation |
| `otp` | ^3.0.0 | TOTP generation and validation |
| `base32` | ^2.1.3 | Base32 encoding/decoding |
| `crypto` | ^3.0.3 | Cryptographic operations |

### Security Implementation

#### QR Code Security
- QR codes contain encrypted pairing secrets
- Base32 encoding for compatibility
- Random secret generation using crypto package

#### TOTP Implementation
- Follows RFC 6238 standard
- 30-second time windows
- SHA1 hashing algorithm
- 6-digit codes for compatibility

#### Data Storage
- Uses Flutter Secure Storage
- Encrypted at rest on device
- No cloud storage or external dependencies

### State Management
- Simple state management using Flutter's built-in StatefulWidget
- Service-based architecture for business logic
- Reactive UI updates for TOTP codes

## 🧪 Testing

Run the test suite:
```bash
flutter test
```

The app includes widget tests for core functionality.

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS | ✅ Supported | Requires camera permissions |
| Android | ✅ Supported | Requires camera permissions |
| Web | ✅ Supported | Camera access via browser |
| macOS | 🔄 Partial | May need additional setup |
| Windows | 🔄 Partial | May need additional setup |
| Linux | 🔄 Partial | May need additional setup |

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes** and add tests if applicable
4. **Commit your changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
5. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**

### Development Guidelines

- Follow Dart/Flutter best practices
- Add comments for complex logic
- Include tests for new features
- Update documentation as needed
- Follow the existing code style

## 🐛 Troubleshooting

### Common Issues

#### iOS Build Issues
```bash
# Clean and rebuild
flutter clean
cd ios && pod install && cd ..
flutter pub get
flutter run -d ios
```

#### Android Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d android
```

#### QR Scanner Not Working
- Ensure camera permissions are granted
- Check if camera is being used by another app
- Try restarting the app

#### TOTP Codes Not Syncing
- Verify both devices have the same time
- Check if the pairing was established correctly
- Try recreating the pairing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Contributors to the open-source packages used
- The TOTP RFC 6238 specification
- Material Design team for the design system

## 📞 Support

- **GitHub Issues**: [Create an issue](https://github.com/nissand/p2p-auth-app/issues)
- **Documentation**: Check this README and code comments
- **Community**: Join Flutter community discussions

## 🔮 Roadmap

- [ ] Add biometric authentication
- [ ] Support for multiple TOTP algorithms
- [ ] Cloud backup (optional)
- [ ] Dark mode support
- [ ] Widget for home screen
- [ ] Export/import functionality
- [ ] Advanced security features

---

**Made with ❤️ using Flutter**

*This app provides secure, peer-to-peer authentication without relying on external servers or cloud services.*
