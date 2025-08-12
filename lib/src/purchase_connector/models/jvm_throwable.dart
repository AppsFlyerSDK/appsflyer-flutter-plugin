part of appsflyer_sdk;

@JsonSerializable()
class JVMThrowable{
  String type;
  String message;
  String stacktrace;
  JVMThrowable? cause;

  JVMThrowable(this.type, this.message, this.stacktrace, this.cause);

  factory JVMThrowable.fromJson(Map<String, dynamic> json) => _$JVMThrowableFromJson(json);

  Map<String, dynamic> toJson() => _$JVMThrowableToJson(this);

}