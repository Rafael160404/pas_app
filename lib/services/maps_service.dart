import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  static const LatLng _clinicLocation = LatLng(14.558104288995674, 121.13694500985869); // ICCT Taytay
  
  // Get clinic location
  LatLng getClinicLocation() => _clinicLocation;
  
  // Note: Current location functionality has been removed
  // due to compatibility issues with the location package.
  // The map will show the clinic marker only.
  
  // Calculate distance between two locations (in km)
  double calculateDistance(LatLng start, LatLng end) {
    const double R = 6371; // Earth's radius in km
    
    double lat1 = start.latitude * (math.pi / 180);
    double lon1 = start.longitude * (math.pi / 180);
    double lat2 = end.latitude * (math.pi / 180);
    double lon2 = end.longitude * (math.pi / 180);
    
    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;
    
    double a = math.sin(dlat / 2) * math.sin(dlat / 2) +
               math.cos(lat1) * math.cos(lat2) *
               math.sin(dlon / 2) * math.sin(dlon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return R * c;
  }

  // Get directions URL (for opening in Google Maps app)
  String getDirectionsUrl(LatLng destination, {LatLng? origin}) {
    if (origin != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    } else {
      return 'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
    }
  }
}