import 'package:equatable/equatable.dart';

/// A mini-app in the shell's catalog — the platform's public ServiceInfo for an
/// ACTIVE service. Display fields may be empty; the UI falls back to defaults.
/// `encryptionPublicKey` is the service's X25519 public key (raw, base64) the
/// shell uses to sealed-box encrypt the user id handed to the mini-app.
class MiniApp extends Equatable {
  const MiniApp({
    required this.serviceId,
    required this.name,
    this.description,
    this.iconUrl,
    this.miniAppUrl,
    this.encryptionPublicKey,
  });

  final String serviceId;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? miniAppUrl;
  final String? encryptionPublicKey;

  factory MiniApp.fromJson(Map<String, dynamic> json) => MiniApp(
        serviceId: json['serviceId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: _nonEmpty(json['description']),
        iconUrl: _nonEmpty(json['iconUrl']),
        miniAppUrl: _nonEmpty(json['miniappUrl']),
        encryptionPublicKey: _nonEmpty(json['encryptionPublicKey']),
      );

  static String? _nonEmpty(dynamic v) {
    final s = v as String?;
    return (s == null || s.isEmpty) ? null : s;
  }

  @override
  List<Object?> get props => [serviceId, name];
}
