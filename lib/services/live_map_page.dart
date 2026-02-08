import 'dart:async';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:care_nexus/services/location_service.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  GoogleMapController? _mapController;
  Marker? _patientMarker;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();

    void loadLocation() async {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        var currentLatLng = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void _startLiveTracking() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          final LatLng latLng = LatLng(position.latitude, position.longitude);

          setState(() {
            _patientMarker = Marker(
              markerId: const MarkerId("patient"),
              position: latLng,
              infoWindow: const InfoWindow(title: "Patient Location"),
            );
          });

          _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Patient Location")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(20.5937, 78.9629), // India fallback
          zoom: 15,
        ),
        markers: _patientMarker != null ? {_patientMarker!} : {},
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
