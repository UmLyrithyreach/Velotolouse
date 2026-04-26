class FirebaseConfig {
  static const String _host =
      'velotolouse-60964-default-rtdb.asia-southeast1.firebasedatabase.app';

  static Uri buildUri(String path) {
    return Uri.https(_host, '/$path');
  }
}