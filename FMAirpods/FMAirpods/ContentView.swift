//
//  ContentView.swift
//  FMAirpods
//
//  Created by speedy on 2024/12/20.
//

import SwiftUI
import CoreBluetooth
import CoreLocation
import MapKit

// MARK: - Data Models
struct AirPodLocation: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let coordinate: CLLocationCoordinate2D
    let signalStrength: Int
    let deviceName: String
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, latitude, longitude, signalStrength, deviceName
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(signalStrength, forKey: .signalStrength)
        try container.encode(deviceName, forKey: .deviceName)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        signalStrength = try container.decode(Int.self, forKey: .signalStrength)
        deviceName = try container.decode(String.self, forKey: .deviceName)
    }
    
    init(timestamp: Date, coordinate: CLLocationCoordinate2D, signalStrength: Int, deviceName: String) {
        self.timestamp = timestamp
        self.coordinate = coordinate
        self.signalStrength = signalStrength
        self.deviceName = deviceName
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

// MARK: - Enhanced Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var isScanning = false
    @Published var foundDevices: [CBPeripheral] = []
    @Published var signalStrength: Int = 0
    @Published var lastLocations: [AirPodLocation] = []
    
    private var centralManager: CBCentralManager!
    private let locationManager = LocationManager()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        loadLastLocations()
    }
    
    func saveLocation(for peripheral: CBPeripheral, signalStrength: Int) {
        guard let location = locationManager.location else { return }
        
        let airPodLocation = AirPodLocation(
            timestamp: Date(),
            coordinate: location.coordinate,
            signalStrength: signalStrength,
            deviceName: peripheral.name ?? "Unknown AirPods"
        )
        
        lastLocations.append(airPodLocation)
        saveLastLocations()
    }
    
    private func saveLastLocations() {
        if let encoded = try? JSONEncoder().encode(lastLocations) {
            UserDefaults.standard.set(encoded, forKey: "LastLocations")
        }
    }
    
    private func loadLastLocations() {
        if let data = UserDefaults.standard.data(forKey: "LastLocations"),
           let decoded = try? JSONDecoder().decode([AirPodLocation].self, from: data) {
            lastLocations = decoded
        }
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            isScanning = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any],
                       rssi RSSI: NSNumber) {

        if peripheral.name?.contains("AirPods") ?? false {
            if !foundDevices.contains(peripheral) {
                foundDevices.append(peripheral)
            }
            signalStrength = RSSI.intValue
        }
    }
}
// MARK: - Map View
struct MapView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: bluetoothManager.lastLocations) { location in
            MapAnnotation(coordinate: location.coordinate) {
                VStack {
                    Image(systemName: "airpodspro")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text(location.deviceName)
                        .font(.caption)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - History View
struct HistoryView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        List(bluetoothManager.lastLocations) { location in
            VStack(alignment: .leading) {
                Text(location.deviceName)
                    .font(.headline)
                Text("Signal: \(location.signalStrength) dBm")
                Text("Time: \(location.timestamp, style: .time)")
                Text("Date: \(location.timestamp, style: .date)")
                Text("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {

            VStack {
            Text("AirPods Finder")
                .font(.largeTitle)
                .padding()
            
            if bluetoothManager.isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Scanning for AirPods...")
            }
            
            List(bluetoothManager.foundDevices, id: \.identifier) { device in
                VStack(alignment: .leading) {
                    Text(device.name ?? "Unknown Device")
                        .font(.headline)
                    Text("Signal Strength: \(bluetoothManager.signalStrength) dBm")
                        .font(.subheadline)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Rectangle()
                                .frame(width: 20, height: 10)
                                .foregroundColor(
                                    index < abs(bluetoothManager.signalStrength/20)
                                    ? .blue : .gray
                                )
                        }
                    }
                }
            }
            
            Button(action: {
                if bluetoothManager.isScanning {
                    bluetoothManager.stopScanning()
                } else {
                    bluetoothManager.startScanning()
                }
            }) {
                Text(bluetoothManager.isScanning ? "Stop Scanning" : "Start Scanning")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .tabItem {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Scanner")
                        }
                        .tag(0)
                        
                        MapView(bluetoothManager: bluetoothManager)
                            .tabItem {
                                Image(systemName: "map")
                                Text("Map")
                            }
                            .tag(1)
                        
                        HistoryView(bluetoothManager: bluetoothManager)
                            .tabItem {
                                Image(systemName: "clock")
                                Text("History")
                            }
                            .tag(2)
                    }
                }
            }
        }

#Preview {
    ContentView()
}
