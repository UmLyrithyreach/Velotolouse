class FirebaseConfig {
  // The hostname only — Uri.https() adds 'https://' automatically
  static const String _host =
      'velotolouse-562e4-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Build a full URI for the given Firebase path (e.g. 'bookings.json')
  static Uri buildUri(String path) {
    return Uri.https(_host, '/$path');
  }
}
