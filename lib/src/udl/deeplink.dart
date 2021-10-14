part of appsflyer_sdk;


class DeepLink{

  final Map<String , dynamic> _clickEvent;

  DeepLink(this._clickEvent);

  Map<String , dynamic> get clickEvent => _clickEvent;

  String? getStringValue(String key) {
    return _clickEvent[key] as String?;
  }

  String? get deepLinkValue =>  _clickEvent["deep_link_value"] as String?;


  String? get matchType =>  _clickEvent["match_type"] as String?;


  String? get clickHttpReferrer =>   _clickEvent["click_http_referrer"] as String?;


  String? get mediaSource =>  _clickEvent["media_source"] as String?;


  String? get campaign =>  _clickEvent["campaign"] as String?;


  String? get campaignId =>   _clickEvent["campaign_id"] as String?;


  String? get afSub1 => _clickEvent["af_sub1"] as String?;


  String? get afSub2 =>  _clickEvent["af_sub2"] as String?;


  String? get afSub3 => _clickEvent["af_sub3"] as String?;


  String? get afSub4 =>  _clickEvent["af_sub4"] as String?;


  String? get afSub5 =>   _clickEvent["af_sub5"] as String?;


  bool? get isDeferred =>  _clickEvent["is_deferred"] as bool?;

  @override
    String toString() {
      return 'DeepLink: ${jsonEncode(_clickEvent)}';
    }
}