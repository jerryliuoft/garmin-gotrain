import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

(:background)
class GoTransitApi {

    // Fetch next departures for a station
    static function fetchDepartures(stationCode as String, callback as Method(responseCode as Number, data as Dictionary or String or Null) as Void) as Void {
        var url = "https://api.openmetrolinx.com/OpenDataAPI/api/V1/Stop/NextService/" + stationCode;
        var parameters = {
            "key" => GO_TRANSIT_API_KEY
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, parameters, options, callback);
    }
    
    // Parse the raw Dictionary into our standard UI format
    static function parseDepartures(data as Dictionary or Null, stationName as String) as Array<Dictionary> {
        var results = [] as Array<Dictionary>;
        if (data == null || !data.hasKey("NextService")) {
            return results;
        }
        var nextService = data["NextService"];
        if (nextService == null || !(nextService instanceof Dictionary) || !nextService.hasKey("Lines")) {
            return results;
        }
        var lines = nextService["Lines"];
        if (lines == null || !(lines instanceof Array)) {
            return results;
        }
        
        for (var i = 0; i < lines.size(); i++) {
            var line = lines[i];
            if (line instanceof Dictionary) {
                // Filter to only Lakeshore West ("LW")
                
                // Extract time
                var departureStr = line["ComputedDepartureTime"];
                        if (departureStr == null || departureStr.equals("null") || departureStr.equals("")) {
                            departureStr = line["ScheduledDepartureTime"];
                        }
                        
                        var platform = line["ActualPlatform"];
                        if (platform == null || platform.equals("null") || platform.equals("")) {
                            platform = line["ScheduledPlatform"];
                        }
                        if (platform == null || platform.equals("null") || platform.equals("")) {
                            platform = "-";
                        }
                        
                        var timeFormatted = "--:--";
                        var minutesUntil = 0;
                        if (departureStr != null && departureStr instanceof String) {
                             // Naive parse assuming format like "2026-06-26 15:30:00" or "15:30:00" or similar
                             var colonIdx = departureStr.find(":");
                             if (colonIdx != null && colonIdx >= 2) {
                                 timeFormatted = departureStr.substring(colonIdx - 2, colonIdx + 3);
                                 var h = departureStr.substring(colonIdx - 2, colonIdx).toNumber();
                                 var m = departureStr.substring(colonIdx + 1, colonIdx + 3).toNumber();
                                 if (h != null && m != null) {
                                     var depMins = (h * 60) + m;
                                     var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
                                     var curMins = (info.hour * 60) + info.min;
                                     minutesUntil = depMins - curMins;
                                     if (minutesUntil < -720) { // Time wrapped to next day
                                         minutesUntil += 24 * 60;
                                     } else if (minutesUntil < 0) { // Train already departed? Or slightly late
                                         minutesUntil = 0;
                                     }
                                 }
                             }
                        }
                        
                        // Only add trains that haven't left yet (or just left)
                        if (minutesUntil >= 0) {
                            results.add({
                                "time" => timeFormatted,
                                "platform" => platform,
                                "minutesUntil" => minutesUntil,
                                "station" => stationName
                            });
                        }
            }
        }
        
        // Sort results by minutesUntil ascending
        var n = results.size();
        for (var i = 0; i < n - 1; i++) {
            for (var j = 0; j < n - i - 1; j++) {
                var a = results[j]["minutesUntil"] as Number;
                var b = results[j+1]["minutesUntil"] as Number;
                if (a > b) {
                    var temp = results[j];
                    results[j] = results[j+1];
                    results[j+1] = temp;
                }
            }
        }
        
        return results;
    }
}
