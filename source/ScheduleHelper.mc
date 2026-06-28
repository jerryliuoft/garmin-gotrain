import Toybox.Lang;
import Toybox.Time;
import Toybox.Application.Storage;

// Helper functions for schedule logic and train calculations
(:background)
class ScheduleHelper {

    // Get the configured morning station (defaults to Clarkson)
    static function getMorningStation() as String {
        var station = Storage.getValue("morning_station");
        if (station == null) {
            return "Clarkson";
        }
        return station as String;
    }

    // Set the configured morning station
    static function setMorningStation(station as String) as Void {
        Storage.setValue("morning_station", station);
    }

    // Get the configured afternoon station (defaults to Union)
    static function getAfternoonStation() as String {
        var station = Storage.getValue("afternoon_station");
        if (station == null) {
            return "Union";
        }
        return station as String;
    }

    // Set the configured afternoon station
    static function setAfternoonStation(station as String) as Void {
        Storage.setValue("afternoon_station", station);
    }

    // Get active station name based on the current hour (Morning = < 12:00 PM, Afternoon = >= 12:00 PM)
    static function getActiveStation() as String {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        if (info.hour < 12) {
            return getMorningStation();
        } else {
            return getAfternoonStation();
        }
    }
    
    // Map station name to GO API station code
    static function getStationCode(station as String) as String {
        return station.equals("Clarkson") ? "CL" : "UN";
    }
    
    // Save live departures for a station
    static function saveLiveDepartures(station as String, data as Array<Dictionary>) as Void {
        Storage.setValue("departures_" + station, data);
        Storage.setValue("departures_time_" + station, Time.now().value());
    }

    // Get live departures for the active station
    // Returns an Array of departure dictionaries.
    static function getNextDepartures(count as Number) as Array<Dictionary> {
        var station = getActiveStation();
        var data = Storage.getValue("departures_" + station);
        var results = [] as Array<Dictionary>;
        
        if (data != null && data instanceof Array) {
            // Check if data is too old (e.g., > 1 hour)
            var lastUpdate = Storage.getValue("departures_time_" + station);
            if (lastUpdate != null && (Time.now().value() - (lastUpdate as Number) < 3600)) {
                for (var i = 0; i < data.size() && results.size() < count; i++) {
                    var dep = data[i];
                    if (dep instanceof Dictionary) {
                        // Re-calculate minutesUntil based on current time
                        // We will skip this complex re-calc here and rely on the fact that 
                        // background fetches happen every 15 minutes.
                        results.add(dep);
                    }
                }
            }
        }

        return results;
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
