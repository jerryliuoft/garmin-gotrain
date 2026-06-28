import Toybox.Test;
import Toybox.Lang;
import Toybox.Time;

(:test)
class GoTransitApiTest {

    (:test)
    static function testParseDeparturesValidData(logger as Test.Logger) as Boolean {
        // Mock a future departure time (e.g. current time + 30 mins)
        var info = Time.Gregorian.info(Time.now().add(new Time.Duration(1800)), Time.FORMAT_SHORT);
        var futureTimeStr = "2026-06-27 " + info.hour.format("%02d") + ":" + info.min.format("%02d") + ":00";
        
        var mockData = {
            "NextService" => {
                "Lines" => [
                    {
                        "LineCode" => "LW",
                        "DirectionCode" => "W",
                        "ComputedDepartureTime" => futureTimeStr,
                        "ActualPlatform" => "4"
                    }
                ]
            }
        };

        var parsed = GoTransitApi.parseDepartures(mockData, "Union");
        
        if (parsed.size() != 1) {
            logger.debug("Expected 1 departure, got " + parsed.size());
            return false;
        }

        var dep = parsed[0];
        if (!dep["platform"].equals("4")) {
            logger.debug("Platform mismatch");
            return false;
        }
        
        if (!dep["station"].equals("Union")) {
            logger.debug("Station mismatch");
            return false;
        }

        return true;
    }
    
    (:test)
    static function testParseDeparturesNullData(logger as Test.Logger) as Boolean {
        var parsed = GoTransitApi.parseDepartures(null, "Union");
        return parsed.size() == 0;
    }
    
    (:test)
    static function testParseDeparturesEmptyLines(logger as Test.Logger) as Boolean {
        var mockData = {
            "NextService" => {
                "Lines" => [] as Array<Dictionary>
            }
        };
        var parsed = GoTransitApi.parseDepartures(mockData, "Union");
        return parsed.size() == 0;
    }
}
