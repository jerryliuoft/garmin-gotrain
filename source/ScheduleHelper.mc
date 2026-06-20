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

    // Find the next upcoming departure for the active station
    // Returns: { time: "HH:MM", platform: "N", minutesUntil: N, station: "Name" } or null
    static function getNextDeparture() as Dictionary or Null {
        var station = getActiveStation();
        var schedule = getScheduleForStation(station);
        var currentMinutes = getCurrentTimeInMinutes();

        // Find first train after current time
        for (var i = 0; i < schedule.size(); i += 2) {
            var departureMinutes = schedule[i];
            var platformVal = schedule[i+1];

            if (departureMinutes > currentMinutes) {
                var minutesUntil = departureMinutes - currentMinutes;
                var hours = departureMinutes / 60;
                var mins = departureMinutes % 60;
                var hoursStr = hours.toString();
                if (hours < 10) {
                    hoursStr = "0" + hoursStr;
                }
                var minsStr = mins.toString();
                if (mins < 10) {
                    minsStr = "0" + minsStr;
                }
                return {
                    "time" => hoursStr + ":" + minsStr,
                    "platform" => platformVal.toString(),
                    "minutesUntil" => minutesUntil,
                    "station" => station
                };
            }
        }

        // If no future trains today, wrap around to first train of schedule
        if (schedule.size() > 0) {
            var departureMinutes = schedule[0];
            var platformVal = schedule[1];
            var hours = departureMinutes / 60;
            var mins = departureMinutes % 60;
            var hoursStr = hours.toString();
            if (hours < 10) {
                hoursStr = "0" + hoursStr;
            }
            var minsStr = mins.toString();
            if (mins < 10) {
                minsStr = "0" + minsStr;
            }
            return {
                "time" => hoursStr + ":" + minsStr,
                "platform" => platformVal.toString(),
                "minutesUntil" => 0,
                "station" => station
            };
        }

        return null;
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
