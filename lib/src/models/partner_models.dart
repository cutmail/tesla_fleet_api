import 'package:json_annotation/json_annotation.dart';

part 'partner_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PartnerAccount {
  final String? publicKey;
  final String? domain;

  PartnerAccount({
    this.publicKey,
    this.domain,
  });

  factory PartnerAccount.fromJson(Map<String, dynamic> json) =>
      _$PartnerAccountFromJson(json);

  Map<String, dynamic> toJson() => _$PartnerAccountToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String? email;
  final String? fullName;
  final String? profileImageUrl;

  User({
    this.email,
    this.fullName,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}