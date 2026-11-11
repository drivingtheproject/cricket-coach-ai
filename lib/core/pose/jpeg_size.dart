/// Reads the pixel size of a JPEG from its header, without decoding the image.
/// Returns null when [bytes] is not a JPEG or has no frame header.
({int width, int height})? readJpegSize(List<int> bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var i = 2;
  while (i + 8 < bytes.length) {
    if (bytes[i] != 0xFF) {
      i++;
      continue;
    }
    final marker = bytes[i + 1];
    if (marker == 0xFF) {
      i++; // Padding byte before a marker.
      continue;
    }
    final standalone =
        marker == 0x01 || marker == 0xD8 || (marker >= 0xD0 && marker <= 0xD7);
    if (standalone) {
      i += 2;
      continue;
    }
    final length = (bytes[i + 2] << 8) | bytes[i + 3];
    // Start-of-frame markers, excluding DHT (C4), JPG (C8) and DAC (CC).
    final startOfFrame = marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (startOfFrame) {
      return (
        width: (bytes[i + 7] << 8) | bytes[i + 8],
        height: (bytes[i + 5] << 8) | bytes[i + 6],
      );
    }
    if (length < 2) return null;
    i += 2 + length;
  }
  return null;
}
