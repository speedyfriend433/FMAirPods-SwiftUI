# FMAirPods

A simple iOS application to help locate your AirPods using Bluetooth signal strength and location tracking.

## Features

- **Real-time AirPods Detection**
  - Bluetooth signal strength monitoring
  - Visual signal strength indicator
  - Support for all AirPods models

- **Location Tracking**
  - Saves last known locations
  - Interactive map view
  - Historical location data

- **History Management**
  - Detailed history of detected locations
  - Timestamp and signal strength records
  - Persistent storage

## Screenshots

[soon]

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Real iOS device (Simulator not supported due to Bluetooth functionality)

## Installation

1. Clone the repository
```bash
git clone https://github.com/speedyfriend67/FMAirPods.git

2. Open FMAirPods.xcodeproj in Xcode

3. Add required permissions to Info.plist:

- NSBluetoothAlwaysUsageDescription
- NSBluetoothPeripheralUsageDescription
- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysAndWhenInUseUsageDescription

4. Build and run the application on a physical iOS device

## Usage

1. Launch the app
2. Grant necessary permissions when prompted
3. Press "Start Scanning" to begin searching for AirPods
4. Use the signal strength indicator to locate your AirPods
5. View history and locations in the Map and History tabs

## Technical Details

1. Built with SwiftUI
2. Uses Core Bluetooth framework
3. Implements CoreLocation for tracking
4. MapKit integration for location visualization

## Contributing

Feel free to submit issues and enhancement requests!

## Contact

Developer: speedyfriend67 Email: speedyfriend433@gmail.com

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Apple Documentation for CoreBluetooth
- SwiftUI Community
