import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;

class GotrainView extends WatchUi.View {

    var mIsLoading as Boolean = false;
    var mError as String or Null = null;

    function initialize() {
        WatchUi.View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        fetchFreshData();
    }

    function fetchFreshData() as Void {
        mIsLoading = true;
        mError = null;
        var station = ScheduleHelper.getActiveStation();
        var stationCode = ScheduleHelper.getStationCode(station);
        GoTransitApi.fetchDepartures(stationCode, method(:onDataReceived));
        WatchUi.requestUpdate();
    }

    function onDataReceived(responseCode as Number, data as Dictionary or String or Null) as Void {
        mIsLoading = false;
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            var station = ScheduleHelper.getActiveStation();
            var parsed = GoTransitApi.parseDepartures(data, station);
            ScheduleHelper.saveLiveDepartures(station, parsed);
        } else {
            mError = "HTTP " + responseCode;
        }
        WatchUi.requestUpdate();
    }

    // Update the view - display the next 3 train departures
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        try {
            var width = dc.getWidth();
            var height = dc.getHeight();
            var subscreen = null;
            if (dc has :getSubscreen) {
                subscreen = dc.getSubscreen();
            }

            var departures = ScheduleHelper.getNextDepartures(3);

            if (departures.size() > 0) {
                var nextDep = departures[0];
                var stationName = nextDep["station"] as String;

                if (subscreen != null) {
                    var subCenterX = subscreen.x + (subscreen.width / 2);
                    var subCenterY = subscreen.y + (subscreen.height / 2);
                    var pltLabelY = subCenterY - dc.getFontHeight(Graphics.FONT_TINY) - 1;
                    dc.drawText(subCenterX, pltLabelY, Graphics.FONT_TINY, "PLT", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    dc.drawText(subCenterX, subCenterY, Graphics.FONT_MEDIUM, nextDep["platform"] as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }

                var leftMargin = 10;
                var rightEdge = (subscreen != null) ? subscreen.x - 4 : width - 8;
                var boardCenterX = leftMargin + (rightEdge - leftMargin) / 2;

                var headerY = 4;
                dc.drawText(boardCenterX, headerY, Graphics.FONT_TINY, stationName, Graphics.TEXT_JUSTIFY_CENTER);

                var dividerY = headerY + dc.getFontHeight(Graphics.FONT_TINY) + 2;
                dc.drawLine(leftMargin, dividerY, rightEdge, dividerY);

                var rowAreaTop = dividerY + 4;
                var rowAreaHeight = height - rowAreaTop - 4;
                var rowHeight = rowAreaHeight / 3;

                for (var r = 0; r < departures.size(); r++) {
                    var dep = departures[r];
                    var depTime = dep["time"] as String;
                    var depPlatform = dep["platform"] as String;
                    var depMinutes = dep["minutesUntil"] as Number;
                    var countdown = ScheduleHelper.formatMinutesUntil(depMinutes);

                    var rowTop = rowAreaTop + r * rowHeight;
                    var rowMidY = rowTop + rowHeight / 2;

                    if (r == 0) {
                        dc.setColor(0x303030, Graphics.COLOR_TRANSPARENT);
                        dc.fillRectangle(leftMargin - 2, rowTop, rightEdge - leftMargin + 4, rowHeight - 1);
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    }

                    var timeFont = (r == 0) ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
                    var infoFont = Graphics.FONT_TINY;

                    var timeY = rowMidY - dc.getFontHeight(timeFont) / 2;
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(leftMargin, timeY, timeFont, depTime, Graphics.TEXT_JUSTIFY_LEFT);

                    dc.setColor(r == 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(boardCenterX, rowMidY - dc.getFontHeight(infoFont) / 2, infoFont, countdown, Graphics.TEXT_JUSTIFY_CENTER);

                    if (r > 0 || subscreen == null) {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(rightEdge, rowMidY - dc.getFontHeight(infoFont) / 2, infoFont, "P" + depPlatform, Graphics.TEXT_JUSTIFY_RIGHT);
                    }

                    if (r < departures.size() - 1) {
                        dc.setColor(0x404040, Graphics.COLOR_TRANSPARENT);
                        dc.drawLine(leftMargin, rowTop + rowHeight - 1, rightEdge, rowTop + rowHeight - 1);
                    }

                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                }
            } else {
                var activeStation = ScheduleHelper.getActiveStation();
                if (subscreen != null) {
                    var subCenterX = subscreen.x + (subscreen.width / 2);
                    var subCenterY = subscreen.y + (subscreen.height / 2);
                    dc.drawText(subCenterX, subCenterY, Graphics.FONT_SMALL, "-", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
                var headerY = (height * 0.25).toNumber();
                dc.drawText(width / 2, headerY, Graphics.FONT_SMALL, activeStation, Graphics.TEXT_JUSTIFY_CENTER);
                
                var msgY = headerY + dc.getFontHeight(Graphics.FONT_SMALL) + 15;
                if (mIsLoading) {
                    dc.drawText(width / 2, msgY, Graphics.FONT_TINY, "Loading...", Graphics.TEXT_JUSTIFY_CENTER);
                } else if (mError != null) {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width / 2, msgY, Graphics.FONT_TINY, mError, Graphics.TEXT_JUSTIFY_CENTER);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.drawText(width / 2, msgY, Graphics.FONT_TINY, "No trains", Graphics.TEXT_JUSTIFY_CENTER);
                }
            }
            
            // Draw a small loading indicator if we have cached data but are fetching fresh data
            if (mIsLoading && departures.size() > 0) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(width - 5, 5, 2);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            
        } catch (ex) {
            var msg = ex.getErrorMessage();
            if (msg == null) {
                msg = "Unknown Error";
            }
            System.println("Exception in onUpdate: " + msg);

            var width = dc.getWidth();
            var height = dc.getHeight();
            var centerX = width / 2;
            dc.drawText(centerX, (height * 0.25).toNumber(), Graphics.FONT_SMALL, "Error", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, (height * 0.45).toNumber(), Graphics.FONT_TINY, msg, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

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
        
        // When settings change, we should ideally fetch fresh data
        WatchUi.requestUpdate();
    }
}
