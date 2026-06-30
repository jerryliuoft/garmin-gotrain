import Toybox.Lang;
import Toybox.Time;
import Toybox.Application.Storage;

// Helper functions for schedule logic and train calculations
(:background)
class ScheduleHelper {

    static function getMorningStationCode() as String {
        var id = Toybox.Application.Storage.getValue("DepartureStation");
        return StationData.getStationCode(id != null ? (id as Number) : 0);
    }

    static function getAfternoonStationCode() as String {
        var id = Toybox.Application.Storage.getValue("ArrivalStation");
        return StationData.getStationCode(id != null ? (id as Number) : 1);
    }

    static function getFlipHour() as Number {
        var hour = Toybox.Application.Storage.getValue("FlipHour");
        if (hour == null) { return 12; }
        return hour as Number;
    }

    // Get active station CODE based on the current hour (Morning = < Flip Hour, Afternoon = >= Flip Hour)
    static function getActiveStationCode() as String {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var flipHour = getFlipHour();
        if (info.hour < flipHour) {
            return getMorningStationCode();
        } else {
            return getAfternoonStationCode();
        }
    }

    // Map station name to GO API station code - no longer needed as we use codes natively
    static function getStationCode(station as String) as String {
        return station;
    }

    // Determine the LineCode (LW, LE, GT, etc.) based on the user's selected Route
    static function getTargetLineCode() as String {
        var routeId = Toybox.Application.Storage.getValue("RouteId");
        if (routeId == null) { routeId = 0; }
        
        var id = routeId as Number;
        if (id == 0) { return "LW"; }
        if (id == 1) { return "LE"; }
        if (id == 2) { return "GT"; }
        if (id == 3) { return "BR"; }
        if (id == 4) { return "MI"; }
        if (id == 5) { return "RH"; }
        if (id == 6) { return "ST"; }
        
        return "LW";
    }
    
    // Save live departures for a station
    static function saveLiveDepartures(station as String, data as Array<Dictionary>) as Void {
        Storage.setValue("departures_" + station, data);
        Storage.setValue("departures_time_" + station, Time.now().value());
    }

    static function getNextDepartures(count as Number) as Array<Dictionary> {
        var station = getActiveStationCode();
        var data = Storage.getValue("departures_" + station);
        var results = [] as Array<Dictionary>;
        
        if (data != null && data instanceof Array) {
            // Check if data is too old (e.g., > 1 hour)
            var lastUpdate = Storage.getValue("departures_time_" + station);
            if (lastUpdate != null && (Time.now().value() - (lastUpdate as Number) < 3600)) {
                for (var i = 0; i < data.size() && results.size() < count; i++) {
                    var dep = data[i];
                    if (dep instanceof Dictionary) {
                        var timeStr = dep["time"];
                        if (timeStr != null && timeStr instanceof String) {
                            var minutesUntil = calculateMinutesUntil(timeStr);
                            if (minutesUntil >= 0) {
                                dep["minutesUntil"] = minutesUntil;
                                results.add(dep);
                            }
                        }
                    }
                }
            }
        }

        return results;
    }

    // Calculate minutes until a given HH:MM time string
    static function calculateMinutesUntil(timeStr as String) as Number {
        var colonIdx = timeStr.find(":");
        if (colonIdx != null && colonIdx >= 1) {
            var h = timeStr.substring(0, colonIdx).toNumber();
            var m = timeStr.substring(colonIdx + 1, timeStr.length()).toNumber();
            if (h != null && m != null) {
                var depMins = (h * 60) + m;
                var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
                var curMins = (info.hour * 60) + info.min;
                var minutesUntil = depMins - curMins;
                if (minutesUntil < -720) {
                    minutesUntil += 24 * 60;
                }
                return minutesUntil;
            }
        }
        return -1;
    }

    // Find the next upcoming departure for the active station
    static function getNextDeparture() as Dictionary or Null {
        var departures = getNextDepartures(1);
        if (departures.size() > 0) {
            return departures[0];
        }
        return null;
    }

    // Format minutes until into a readable string
    static function formatMinutesUntil(minutes as Number) as String {
        if (minutes == 0) {
            return "now";
        } else if (minutes < 60) {
            return minutes + "m";
        } else {
            var hours = minutes / 60;
            var mins = minutes % 60;
            if (mins == 0) {
                return hours + "h";
            } else {
                return hours + "h" + mins + "m";
            }
        }
    }

}
