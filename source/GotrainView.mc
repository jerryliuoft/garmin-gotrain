import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;

class GotrainView extends WatchUi.View {

    function initialize() {
        WatchUi.View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // Just set a basic layout - don't reference missing resources
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
    }

    // Update the view - display the next train departure in glance format
    function onUpdate(dc as Dc) as Void {
        // Clear the screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Set text color to white
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        try {
            // Fetch next departure dynamically using ScheduleHelper
            var nextDeparture = ScheduleHelper.getNextDeparture();
            
            // Screen dimensions and subscreen detection
            var width = dc.getWidth();
            var height = dc.getHeight();
            var centerX = width / 2;
            var subscreen = null;
            if (dc has :getSubscreen) {
                subscreen = dc.getSubscreen();
            }

            if (nextDeparture != null) {
                var nextTime = nextDeparture["time"] as String;
                var nextPlatform = nextDeparture["platform"] as String;
                var minutesUntil = nextDeparture["minutesUntil"] as Number;
                var stationName = nextDeparture["station"] as String;

                // Format the countdown string using helper
                var countdownStr = ScheduleHelper.formatMinutesUntil(minutesUntil);

                if (subscreen != null) {
                    // --- Layout WITH subscreen (e.g. Instinct 2 / 3) ---
                    var subCenterX = subscreen.x + (subscreen.width / 2);
                    var subCenterY = subscreen.y + (subscreen.height / 2);
                    
                    // Draw platform in the subscreen
                    dc.drawText(subCenterX, subCenterY, Graphics.FONT_MEDIUM, nextPlatform, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                    // Draw station name header at the top-center (shifted left slightly to not feel crowded near subscreen)
                    var headerY = (height * 0.15).toNumber();
                    dc.drawText(centerX - 15, headerY, Graphics.FONT_SMALL, stationName, Graphics.TEXT_JUSTIFY_CENTER);

                    // Draw a divider line
                    var dividerY = headerY + dc.getFontHeight(Graphics.FONT_SMALL) + 2;
                    dc.drawLine(20, dividerY, width - 40, dividerY);

                    // Time display
                    var timeY = dividerY + 10;
                    dc.drawText(centerX - 15, timeY, Graphics.FONT_LARGE, nextTime, Graphics.TEXT_JUSTIFY_CENTER);

                    // Countdown displays below time
                    var countdownY = timeY + dc.getFontHeight(Graphics.FONT_LARGE) + 6;
                    dc.drawText(centerX - 15, countdownY, Graphics.FONT_SMALL, countdownStr, Graphics.TEXT_JUSTIFY_CENTER);

                } else {
                    // --- Standard Layout WITHOUT subscreen (e.g. standard circular/rectangular watches) ---
                    // Header (Station Name)
                    var headerY = (height * 0.15).toNumber();
                    dc.drawText(centerX, headerY, Graphics.FONT_SMALL, stationName, Graphics.TEXT_JUSTIFY_CENTER);

                    // Divider line
                    var dividerY = headerY + dc.getFontHeight(Graphics.FONT_SMALL) + 2;
                    dc.drawLine(20, dividerY, width - 20, dividerY);

                    // Time and Platform side-by-side
                    var contentY = dividerY + 10;
                    dc.drawText(centerX - 10, contentY, Graphics.FONT_LARGE, nextTime, Graphics.TEXT_JUSTIFY_RIGHT);
                    dc.drawText(centerX + 10, contentY + 5, Graphics.FONT_SMALL, "Plat " + nextPlatform, Graphics.TEXT_JUSTIFY_LEFT);

                    // Countdown
                    var countdownY = contentY + dc.getFontHeight(Graphics.FONT_LARGE) + 6;
                    dc.drawText(centerX, countdownY, Graphics.FONT_SMALL, countdownStr, Graphics.TEXT_JUSTIFY_CENTER);
                }
            } else {
                // No more trains today
                var activeStation = ScheduleHelper.getActiveStation();
                if (subscreen != null) {
                    var subCenterX = subscreen.x + (subscreen.width / 2);
                    var subCenterY = subscreen.y + (subscreen.height / 2);
                    dc.drawText(subCenterX, subCenterY, Graphics.FONT_SMALL, "-", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
                
                var headerY = (height * 0.25).toNumber();
                dc.drawText(centerX, headerY, Graphics.FONT_SMALL, activeStation, Graphics.TEXT_JUSTIFY_CENTER);
                
                var noTrainsY = headerY + dc.getFontHeight(Graphics.FONT_SMALL) + 15;
                dc.drawText(centerX, noTrainsY, Graphics.FONT_TINY, "No trains", Graphics.TEXT_JUSTIFY_CENTER);
            }
        } catch (ex) {
            var msg = ex.getErrorMessage();
            if (msg == null) {
                msg = "Unknown Error";
            }
            Toybox.System.println("Exception in onUpdate: " + msg);
            
            var width = dc.getWidth();
            var height = dc.getHeight();
            var centerX = width / 2;
            dc.drawText(centerX, (height * 0.25).toNumber(), Graphics.FONT_SMALL, "Error", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, (height * 0.45).toNumber(), Graphics.FONT_TINY, msg, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
    }

}

class GotrainInputDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Settings"});
        menu.addItem(new WatchUi.MenuItem("Morning", ScheduleHelper.getMorningStation(), "morning", null));
        menu.addItem(new WatchUi.MenuItem("Afternoon", ScheduleHelper.getAfternoonStation(), "afternoon", null));
        
        WatchUi.pushView(menu, new GotrainSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onTap(clickEvent) as Boolean {
        return onMenu();
    }
}

class GotrainSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("morning")) {
            var current = ScheduleHelper.getMorningStation();
            var next = current.equals("Clarkson") ? "Union" : "Clarkson";
            ScheduleHelper.setMorningStation(next);
            item.setSubLabel(next);
        } else if (id.equals("afternoon")) {
            var current = ScheduleHelper.getAfternoonStation();
            var next = current.equals("Clarkson") ? "Union" : "Clarkson";
            ScheduleHelper.setAfternoonStation(next);
            item.setSubLabel(next);
        }
        WatchUi.requestUpdate();
    }
}
