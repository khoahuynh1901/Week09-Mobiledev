import SwiftUI
import MapKit
import CoreLocation

struct LocationPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct ContentView: View {
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.7, longitude: -79.4), // Ontario, Canada
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    
    @State private var locations: [LocationPoint] = []
    @State private var distances: [String] = []
    @State private var selectedMapItem: MKMapItem?

    var body: some View {
        VStack {
            Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: locations) { location in
                MapPin(coordinate: location.coordinate, tint: .blue)
            }
            .onTapGesture(coordinateSpace: .local) { tapLocation in
                addLocation(at: tapLocation)
            }
            .overlay(
                GeometryReader { geometry in
                    drawTriangle(in: geometry)
                }
            )
            
            Button("Show Route") {
                generateRoute()
            }
            .padding()
        }
    }
    
    private func addLocation(at tapLocation: CGPoint) {
        let coordinate = convertTapToCoordinate(tapLocation)

        // Remove point if user taps close to an existing one
        if let index = locations.firstIndex(where: { isClose(to: $0.coordinate, newLocation: coordinate) }) {
            locations.remove(at: index)
        } else if locations.count < 3 {
            locations.append(LocationPoint(coordinate: coordinate))
        }

        if locations.count == 3 {
            calculateDistances()
        }
    }
    
    private func convertTapToCoordinate(_ tapLocation: CGPoint) -> CLLocationCoordinate2D {
        // Assuming conversion logic from tap location to coordinate.
        return CLLocationCoordinate2D(latitude: mapRegion.center.latitude, longitude: mapRegion.center.longitude)
    }

    private func isClose(to existing: CLLocationCoordinate2D, newLocation: CLLocationCoordinate2D) -> Bool {
        let distance = CLLocation(latitude: existing.latitude, longitude: existing.longitude)
            .distance(from: CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude))
        return distance < 500 // Within 500 meters
    }
    
    private func calculateDistances() {
        guard locations.count == 3 else { return }
        distances = []
        
        for i in 0..<3 {
            let nextIndex = (i + 1) % 3
            let distance = CLLocation(latitude: locations[i].coordinate.latitude, longitude: locations[i].coordinate.longitude)
                .distance(from: CLLocation(latitude: locations[nextIndex].coordinate.latitude, longitude: locations[nextIndex].coordinate.longitude))
            distances.append(String(format: "%.2f km", distance / 1000))
        }
    }
    
    private func drawTriangle(in geometry: GeometryProxy) -> some View {
        if locations.count < 3 { return AnyView(EmptyView()) }

        let points = locations.map { location in
            CGPoint(
                x: geometry.size.width * (location.coordinate.longitude - mapRegion.center.longitude) / mapRegion.span.longitudeDelta + geometry.size.width / 2,
                y: geometry.size.height * (mapRegion.center.latitude - location.coordinate.latitude) / mapRegion.span.latitudeDelta + geometry.size.height / 2
            )
        }

        return AnyView(
            ZStack {
                Path { path in
                    path.move(to: points[0])
                    path.addLine(to: points[1])
                    path.addLine(to: points[2])
                    path.closeSubpath()
                }
                .stroke(Color.green, lineWidth: 2)
                
                Path { path in
                    path.move(to: points[0])
                    path.addLine(to: points[1])
                    path.addLine(to: points[2])
                    path.closeSubpath()
                }
                .fill(Color.red.opacity(0.5))
                
                ForEach(0..<3, id: \.self) { i in
                    Text(distances.indices.contains(i) ? distances[i] : "")
                        .position(x: (points[i].x + points[(i+1) % 3].x) / 2, y: (points[i].y + points[(i+1) % 3].y) / 2)
                        .foregroundColor(.black)
                        .font(.caption)
                }
            }
        )
    }

    private func generateRoute() {
        print("Generating route A → B → C → A")
    }
}

