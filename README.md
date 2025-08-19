# P2P Authentication App

A Flutter-based peer-to-peer authentication application that allows secure pairing between devices using QR codes and TOTP (Time-based One-Time Password) for enhanced security.

## Features

- **QR Code Scanning**: Scan QR codes to establish secure connections between devices
- **TOTP Generation**: Generate time-based one-time passwords for secure authentication
- **Secure Storage**: Store pairing information securely using Flutter Secure Storage
- **Cross-Platform**: Works on iOS, Android, and Web platforms
- **Modern UI**: Clean and intuitive user interface with Material Design

## Screenshots

- Home Screen: View all paired devices
- New Pair Screen: Generate QR codes for new pairings
- Scan Pair Screen: Scan QR codes to establish new connections

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- iOS Simulator or Android Emulator (for mobile development)
- Chrome (for web development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/p2p-auth-app.git
   cd p2p-auth-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For iOS
   flutter run -d ios
   
   # For Android
   flutter run -d android
   
   # For Web
   flutter run -d chrome
   ```

### iOS Setup

If you encounter CocoaPods sync issues:

```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── pairing.dart         # Pairing data model
├── screens/
│   ├── home_screen.dart     # Main home screen
│   ├── new_pair_screen.dart # QR code generation screen
│   └── scan_pair_screen.dart # QR code scanning screen
├── services/
│   ├── qr_scanner_service.dart # QR code scanning logic
│   ├── storage_service.dart    # Secure storage operations
│   └── totp_service.dart       # TOTP generation logic
└── widgets/
    ├── empty_state.dart     # Empty state widget
    └── pairing_card.dart    # Pairing card widget
```

## Dependencies

- `flutter_secure_storage`: Secure storage for sensitive data
- `mobile_scanner`: QR code scanning functionality
- `otp`: TOTP generation library

## Security Features

- **Secure Storage**: All pairing data is stored using Flutter Secure Storage
- **TOTP Authentication**: Time-based one-time passwords for secure verification
- **QR Code Encryption**: QR codes contain encrypted pairing information

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please open an issue on GitHub. 