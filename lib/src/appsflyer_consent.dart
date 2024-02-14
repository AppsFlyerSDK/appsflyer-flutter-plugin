class AppsFlyerConsent {
  final bool isUserSubjectToGDPR;
  final bool hasConsentForDataUsage;
  final bool hasConsentForAdsPersonalization;

  AppsFlyerConsent._({
    required this.isUserSubjectToGDPR,
    required this.hasConsentForDataUsage,
    required this.hasConsentForAdsPersonalization,
  });

  // Factory constructors
  factory AppsFlyerConsent.forGDPRUser({
    required bool hasConsentForDataUsage,
    required bool hasConsentForAdsPersonalization
  }){
    return AppsFlyerConsent._(
        isUserSubjectToGDPR: true,
        hasConsentForDataUsage: hasConsentForDataUsage,
        hasConsentForAdsPersonalization: hasConsentForAdsPersonalization
    );
  }

  factory AppsFlyerConsent.nonGDPRUser(){
    return AppsFlyerConsent._(
        isUserSubjectToGDPR: false,
        hasConsentForDataUsage: false,
        hasConsentForAdsPersonalization: false
    );
  }

  // Converts object to a map
  Map<String, dynamic> toMap() {
    return {
      'isUserSubjectToGDPR': isUserSubjectToGDPR,
      'hasConsentForDataUsage': hasConsentForDataUsage,
      'hasConsentForAdsPersonalization': hasConsentForAdsPersonalization,
    };
  }
}