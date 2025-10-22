part of appsflyer_sdk;

@JsonSerializable()
class IosError {
  String localizedDescription;
  String domain;
  int code;

  IosError(this.localizedDescription, this.domain, this.code);

  factory IosError.fromJson(Map<String, dynamic> json) =>
      _$IosErrorFromJson(json);

  Map<String, dynamic> toJson() => _$IosErrorToJson(this);
}
