/// Utility for formatting byte counts into human-readable strings.
class FormatUtils {
  FormatUtils._();

  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (bytes == 0)
        ? 0
        : (bytes.toDouble().toString().length <= 3
            ? 0
            : _log1000(bytes.toDouble()));
    final value = bytes / _pow1000(i);
    return '${value.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static int _log1000(double bytes) {
    int i = 0;
    double val = bytes;
    while (val >= 1000 && i < 5) {
      val /= 1000;
      i++;
    }
    return i;
  }

  static double _pow1000(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 1000;
    }
    return result;
  }

  /// Converts GB to bytes.
  static int gbToBytes(double gb) => (gb * 1000 * 1000 * 1000).round();

  /// Converts bytes to GB.
  static double bytesToGb(int bytes) => bytes / (1000 * 1000 * 1000);

  /// Formats a timestamp in ms to a readable date.
  static String formatDate(int timestampMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
