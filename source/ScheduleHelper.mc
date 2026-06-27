import Toybox.Lang;
import Toybox.Time;
import Toybox.Application.Storage;

// Helper functions for schedule logic and train calculations
(:glance)
class ScheduleHelper {

    // Get the current time and determine if today is a weekday (1=Sunday, 7=Saturday)
    // Returns true if weekday (Mon-Fri), false if weekend (Sat-Sun)
    static function isWeekday() as Boolean {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dayOfWeek = info.day_of_week; // 1 = Sunday, 7 = Saturday
        return (dayOfWeek >= 2 && dayOfWeek <= 6);
    }

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

    // Get the appropriate schedule for the specified station and weekday status
    static function getScheduleForStation(station as String) as Array<Number> {
        var isWd = isWeekday();
        if (station.equals("Clarkson")) {
            return isWd ? Schedule.CLARKSON_WEEKDAY_SCHEDULE : Schedule.CLARKSON_WEEKEND_SCHEDULE;
        } else {
            return isWd ? Schedule.UNION_WEEKDAY_SCHEDULE : Schedule.UNION_WEEKEND_SCHEDULE;
        }
    }

    // Get current time in minutes since midnight
    static function getCurrentTimeInMinutes() as Number {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return (info.hour * 60) + info.min;
    }

    // Build a departure dictionary from schedule array index and current minutes
    static function buildDeparture(schedule as Array<Number>, idx as Number, currentMinutes as Number, station as String) as Dictionary {
        var departureMinutes = schedule[idx];
        var platformVal = schedule[idx + 1];
        var minutesUntil = departureMinutes > currentMinutes ? departureMinutes - currentMinutes : 0;
        var hours = departureMinutes / 60;
        var mins = departureMinutes % 60;
        var hoursStr = hours.toString();
        if (hours < 10) { hoursStr = "0" + hoursStr; }
        var minsStr = mins.toString();
        if (mins < 10) { minsStr = "0" + minsStr; }
        return {
            "time" => hoursStr + ":" + minsStr,
            "platform" => platformVal.toString(),
            "minutesUntil" => minutesUntil,
            "station" => station
        };
    }

    // Find the next upcoming departure for the active station
    // Returns: { time: "HH:MM", platform: "N", minutesUntil: N, station: "Name" } or null
    static function getNextDeparture() as Dictionary or Null {
        var departures = getNextDepartures(1);
        if (departures.size() > 0) {
            return departures[0];
        }
        return null;
    }

    // Find the next N upcoming departures for the active station.
    // Returns an Array of up to 'count' departure dictionaries.
    static function getNextDepartures(count as Number) as Array<Dictionary> {
        var station = getActiveStation();
        var schedule = getScheduleForStation(station);
        var currentMinutes = getCurrentTimeInMinutes();
        var results = [] as Array<Dictionary>;

        // Walk the schedule looking for future trains
        for (var i = 0; i < schedule.size() && results.size() < count; i += 2) {
            if (schedule[i] > currentMinutes) {
                results.add(buildDeparture(schedule, i, currentMinutes, station));
            }
        }

        // If we still need more entries and the schedule has trains, add from the
        // beginning of the schedule (wrapping to next day)
        var i = 0;
        while (results.size() < count && i < schedule.size()) {
            results.add(buildDeparture(schedule, i, currentMinutes, station));
            i += 2;
        }

        return results;
    }

    // Format minutes until into a readable string
    static function formatMinutesUntil(minutes as Number) as String {
        if (minutes == 0) {
            return "tomorrow";
        } else if (minutes == 1) {
            return "in 1 min";
        } else if (minutes < 60) {
            return "in " + minutes + " mins";
        } else {
            var hours = minutes / 60;
            var mins = minutes % 60;
            if (mins == 0) {
                return "in " + hours + " hr";
            } else {
                return "in " + hours + "h" + mins + "m";
            }
        }
    }

}
