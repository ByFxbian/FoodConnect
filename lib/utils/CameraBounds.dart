import 'package:google_maps_flutter/google_maps_flutter.dart';

class CameraBounds {
  const CameraBounds(this.bounds);

  final LatLngBounds? bounds;

  static const CameraBounds unbounded = CameraBounds(null);

  Object toJson() => <Object?>[<Object>[]];

  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(runtimeType != other.runtimeType) {
      return false;
    }
    return other is CameraBounds && bounds == other.bounds;
  }

  @override
  int get hashCode => bounds.hashCode;

  @override
  String toString() {
    return 'CameraBounds(bounds: $bounds)';
  }
}

extension ToJsonExtension on LatLng {
  Object toJson() {
    return <double>[latitude, longitude];
  }
}

extension ToJsonExtensionBounds on LatLngBounds {
  Object toJson() {
    return <Object>[southwest.toJson(), northeast.toJson()];
  }
}
