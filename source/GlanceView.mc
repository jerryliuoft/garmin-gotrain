import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Glance view for the GO Train app
// Displays the next departure using background-cached live data
(:glance)
class GlanceView extends WatchUi.GlanceView {

    function initialize() {
        WatchUi.GlanceView.initialize();
    }

    // Update the glance display
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var height = dc.getHeight();
        var centerY = height / 2;

        var nextDeparture = ScheduleHelper.getNextDeparture();

        if (nextDeparture != null) {
            var timeStr = nextDeparture["time"] as String;
            var platformStr = "P" + (nextDeparture["platform"] as String);
            var minutesUntil = nextDeparture["minutesUntil"] as Number;
            var minutesStr = ScheduleHelper.formatMinutesUntil(minutesUntil);
            var stationName = nextDeparture["station"] as String;
            
            var fontSmall = Graphics.FONT_SMALL;
            var fontTiny = Graphics.FONT_TINY;
            
            var line1Text = stationName + " • " + platformStr;
            var line2Text = timeStr + " (" + minutesStr + ")";
            
            dc.drawText(10, (height * 0.15).toNumber(), fontSmall, line1Text, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(10, (height * 0.55).toNumber(), fontTiny, line2Text, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            var stationName = ScheduleHelper.getActiveStation();
            dc.drawText(10, (height * 0.15).toNumber(), Graphics.FONT_SMALL, stationName, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(10, (height * 0.55).toNumber(), Graphics.FONT_TINY, "No live data", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

}
