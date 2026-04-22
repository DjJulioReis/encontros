import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'location_service.dart';

class LocationController extends ChangeNotifier {
  String city = "Detectando...";
  double? lat;
  double? lng;

  Future<void> initLocation() async {
    try {
      Position? position = await LocationService.getCurrentLocation();

      if (position == null) {
        city = "Localização indisponível";
        notifyListeners();
        return;
      }

      lat = position.latitude;
      lng = position.longitude;

      await Future.delayed(const Duration(milliseconds: 500));

      final placemarks = await placemarkFromCoordinates(lat!, lng!);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final cityName = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            "Local desconhecido";

        final state = place.administrativeArea ?? "";

        city = "📍 $cityName${state.isNotEmpty ? ' - $state' : ''}";
        print("LAT: $lat | LNG: $lng");
      } else {
        city = "Cidade não encontrada";
      }

      notifyListeners();
    } catch (e) {
      city = "Erro ao obter localização";
      notifyListeners();
    }
  }
}