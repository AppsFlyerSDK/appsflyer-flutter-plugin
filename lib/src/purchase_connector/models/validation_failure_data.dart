part of appsflyer_sdk;

@JsonSerializable()
class ValidationFailureData {

  int status;
  String description;

  ValidationFailureData(
      this.status,
      this.description
      );



  factory ValidationFailureData.fromJson(Map<String, dynamic> json) => _$ValidationFailureDataFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationFailureDataToJson(this);

}