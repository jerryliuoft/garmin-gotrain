import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Glance view for the GO Train app
// Displays the next Lakeshore West departure from Union Station on the Instinct 3 Solar glance screen
(:glance)
class GlanceView extends WatchUi.GlanceView {

    function initialize() {
        WatchUi.GlanceView.initialize();
    }

    // Update the glance display
    function onUpdate(dc as Dc) as Void {
        // Clear the screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Set text color to white
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var height = dc.getHeight();
        var centerY = height / 2;

        // Get next departure
        var nextDeparture = ScheduleHelper.getNextDeparture();

        if (nextDeparture != null) {
            var timeStr = nextDeparture["time"] as String;
            var platformStr = "P" + (nextDeparture["platform"] as String);
            var minutesUntil = nextDeparture["minutesUntil"] as Number;
            var minutesStr = ScheduleHelper.formatMinutesUntil(minutesUntil);
            
            var stationName = nextDeparture["station"] as String;
            
            // Build a clean, two-line glance layout:
            // Line 1: Station • Platform
            // Line 2: Time (Minutes Until)
            var fontSmall = Graphics.FONT_SMALL;
            var fontTiny = Graphics.FONT_TINY;
            
            var line1Text = stationName + " • " + platformStr;
            var line2Text = timeStr + " (" + minutesStr + ")";
            
            // Draw Line 1
            dc.drawText(10, (height * 0.15).toNumber(), fontSmall, line1Text, Graphics.TEXT_JUSTIFY_LEFT);
            // Draw Line 2
            dc.drawText(10, (height * 0.55).toNumber(), fontTiny, line2Text, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            // No more trains today
            dc.drawText(10, centerY - (dc.getFontHeight(Graphics.FONT_SMALL) / 2), Graphics.FONT_SMALL, "LSW: No more trains", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

}
