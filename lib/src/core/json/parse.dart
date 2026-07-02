/// protojson encodes proto int64 fields as JSON **strings** (verified against
/// the live gateway: `currencyId` comes back as `"1"`, not `1`). Small ints may
/// also arrive as numbers, so parse both forms defensively.
int parseInt64(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
