part of appsflyer_sdk;

@immutable
class DeepLink {
  final Map<String, dynamic> _clickEvent;

  const DeepLink(this._clickEvent);

  Map<String, dynamic> get clickEvent => _clickEvent;

  String? getStringValue(String key) => _clickEvent[key]?.toString();

  String? get deepLinkValue => getStringValue('deep_link_value');

  String? get matchType => getStringValue('match_type');

  String? get clickHttpReferrer => getStringValue('click_http_referrer');

  String? get mediaSource => getStringValue('media_source');

  String? get campaign => getStringValue('campaign');

  String? get campaignId => getStringValue('campaign_id');

  String? get afSub1 => getStringValue('af_sub1');

  String? get afSub2 => getStringValue('af_sub2');

  String? get afSub3 => getStringValue('af_sub3');

  String? get afSub4 => getStringValue('af_sub4');

  String? get afSub5 => getStringValue('af_sub5');

  /// Whether this link came from deferred deep linking (fresh install) vs. a
  /// direct click while already installed.
  ///
  /// Reliable on Android. **Always `null` on iOS**: the native click event
  /// doesn't carry an `is_deferred` key.
  bool? get isDeferred {
    final value = _clickEvent['is_deferred'];
    if (value is bool) {
      return value;
    }
    if (value?.toString().toLowerCase() == 'true') {
      return true;
    }
    if (value?.toString().toLowerCase() == 'false') {
      return false;
    }
    return null;
  }

  @override
  String toString() {
    return 'DeepLink: ${jsonEncode(_clickEvent)}';
  }
}
