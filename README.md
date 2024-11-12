# Discord Clone

A Discord clone built with Flutter, featuring real-time chat functionality and a Discord-like UI.

## Features

- Real-time messaging using WebSocket
- Server and channel management
- Friends list and user status
- Discord-like UI and theme

## Prerequisites

- Flutter SDK (>=3.5.0)
- Dart SDK (>=3.0.0)
- Python 3.7+ (for backend server)
- pip (Python package manager)

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/discord-clone.git
cd discord-clone
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Set up the backend server

```bash
cd backend
pip install -r requirements.txt
python main.py
```

### 4. Run the application

```bash
flutter run
```

## Project Structure

```
discord-clone/
├── lib/
│   ├── models/
│   │   ├── channel.dart
│   │   └── server.dart
│   ├── chat_room.dart
│   ├── main_dashboard.dart
│   └── main.dart
├── backend/
│   └── main.py
└── pubspec.yaml
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.