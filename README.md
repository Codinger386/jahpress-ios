# README #

This app is available in the app store: https://apps.apple.com/us/app/jahpress/id1444504931.

### Project Setup ###

* Execute `carthage update --platform iOS`
* Put the following frameworks in the Frameworks folder:
    * Bolts.framework
    * FIRAnalyticsConnector.framework
    * FirebaseAnalytics.framework
    * FirebaseCore.framework
    * FirebaseCoreDiagnostics.framework
    * FirebaseInstanceID.framework
    * FreeStreamer.framework
    * GoogleAppMeasurement.framework
    * GoogleDataTransport.framework
    * GoogleDataTransportCCTSupport.framework
    * GoogleMobileAds.framework
    * GoogleToolboxForMac.framework
    * GoogleUtilities.framework
    * nanopb.framework

For more information check: https://firebase.google.com/docs/ios/setup and https://github.com/muhku/FreeStreamer

This project requires a Shoutcast API key which needs to be added in JahPress.xcconfig.


### TODO ###

* Firebase Analytics
* Crash Lytics
* Sounds sortieren
* Eigene Sounds
