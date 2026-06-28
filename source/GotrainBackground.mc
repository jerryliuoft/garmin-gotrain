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
        var station = ScheduleHelper.getActiveStation();
        var stationCode = ScheduleHelper.getStationCode(station);
        
        GoTransitApi.fetchDepartures(stationCode, method(:onReceiveData));
    }

    function onReceiveData(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            var station = ScheduleHelper.getActiveStation();
            var parsed = GoTransitApi.parseDepartures(data, station);
            Background.exit(parsed);
        } else {
            Background.exit(null);
        }
    }
}
