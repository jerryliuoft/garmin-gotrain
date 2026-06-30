import Toybox.Application;
import Toybox.Background;
import Toybox.System;
import Toybox.Lang;

(:background)
class GotrainBackground extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var stationCode = ScheduleHelper.getActiveStationCode();
        
        GoTransitApi.fetchDepartures(stationCode, method(:onReceiveData));
    }

    function onReceiveData(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            var stationCode = ScheduleHelper.getActiveStationCode();
            var parsed = GoTransitApi.parseDepartures(data, stationCode);
            Background.exit(parsed);
        } else {
            Background.exit(null);
        }
    }
}
