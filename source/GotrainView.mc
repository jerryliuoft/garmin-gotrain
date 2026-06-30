import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.System;

class GotrainView extends WatchUi.View {

    var mIsLoading as Boolean = false;
    var mError as String or Null = null;
    var mLayoutManager as LayoutSystem.LayoutManager or Null = null;
    var mTimer as Timer.Timer or Null = null;
    var mScrollOffset as Number = 0;

    function initialize() {
        WatchUi.View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        mLayoutManager = new LayoutSystem.LayoutManager(dc);
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        fetchFreshData();
        mTimer = new Timer.Timer();
        mTimer.start(method(:onTimer), 150, true);
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
    }

    function onTimer() as Void {
        mScrollOffset += 3;
        WatchUi.requestUpdate();
    }

    function fetchFreshData() as Void {
        mIsLoading = true;
        mError = null;
        var stationCode = ScheduleHelper.getActiveStationCode();
        GoTransitApi.fetchDepartures(stationCode, method(:onDataReceived));
        WatchUi.requestUpdate();
    }

    function onDataReceived(responseCode as Number, data as Dictionary or String or Null) as Void {
        mIsLoading = false;
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            var stationCode = ScheduleHelper.getActiveStationCode();
            var parsed = GoTransitApi.parseDepartures(data, stationCode);
            ScheduleHelper.saveLiveDepartures(stationCode, parsed);
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

        if (mLayoutManager == null) {
            return;
        }

        try {
            var width = dc.getWidth();
            var height = dc.getHeight();
            
            var subRegion = mLayoutManager.subScreenRegion;
            var topRegion = mLayoutManager.topLeftRegion;
            var bodyRegion = mLayoutManager.mainBodyRegion;

            var departures = ScheduleHelper.getNextDepartures(3);

            if (departures.size() > 0) {
                var nextDep = departures[0];
                var stationCode = nextDep["station"] as String;
                var stationName = StationData.getStationNameFromCode(stationCode);
                var countdown = ScheduleHelper.formatMinutesUntil(nextDep["minutesUntil"] as Number);

                var leftMargin = bodyRegion.x;
                var rightEdge = bodyRegion.x + bodyRegion.width;
                var boardCenterX = leftMargin + (rightEdge - leftMargin) / 2;

                var headerY = (topRegion != null) ? topRegion.y : bodyRegion.y;
                var headerCenterX = (topRegion != null) ? topRegion.x + topRegion.width / 2 : boardCenterX;

                var font = Graphics.FONT_TINY;
                var textWidth = dc.getTextWidthInPixels(stationName, font);
                var availWidth = (topRegion != null) ? topRegion.width : (rightEdge - leftMargin);

                if (textWidth > availWidth) {
                    if (mScrollOffset > textWidth + 20) {
                        mScrollOffset = -availWidth;
                    }
                    var clipX = (topRegion != null) ? topRegion.x : leftMargin;
                    dc.setClip(clipX, headerY, availWidth, dc.getFontHeight(font) + 4);
                    var drawX = clipX - mScrollOffset;
                    dc.drawText(drawX, headerY, font, stationName, Graphics.TEXT_JUSTIFY_LEFT);
                    dc.clearClip();
                } else {
                    dc.drawText(headerCenterX, headerY, font, stationName, Graphics.TEXT_JUSTIFY_CENTER);
                }

                var dividerY = headerY + dc.getFontHeight(font) + 2;
                var rowAreaTop = dividerY + 6;
                var bodyBottom = bodyRegion.y + bodyRegion.height;
                var rowAreaHeight = bodyBottom - rowAreaTop;
                var rowHeight = rowAreaHeight / 3;

                for (var r = 0; r < departures.size(); r++) {
                    var dep = departures[r];
                    var depTime = dep["time"] as String;
                    var depPlatform = dep["platform"] as String;
                    var depMinutes = dep["minutesUntil"] as Number;
                    var rowCountdown = ScheduleHelper.formatMinutesUntil(depMinutes);

                    var rowTop = rowAreaTop + r * rowHeight;
                    var rowMidY = rowTop + rowHeight / 2;

                    var hasColor = (subRegion == null);
                    var highlightBg = hasColor ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_WHITE;
                    var highlightFg = hasColor ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

                    if (r == 0) {
                        // Draw full width highlight
                        dc.setColor(highlightBg, Graphics.COLOR_TRANSPARENT);
                        dc.fillRectangle(leftMargin - 2, rowTop, rightEdge - leftMargin + 4, rowHeight - 1);
                        
                        // Mask out the subscreen with a black circle
                        if (subRegion != null) {
                            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                            var subCenterX = subRegion.x + (subRegion.width / 2);
                            var subCenterY = subRegion.y + (subRegion.height / 2);
                            // Draw circle to act as an eraser over the subscreen area
                            dc.fillCircle(subCenterX, subCenterY, (subRegion.width / 2) + 2);
                        }
                    }

                    var timeFont = (r == 0) ? Graphics.FONT_MEDIUM : Graphics.FONT_SMALL;
                    var infoFont = Graphics.FONT_TINY;

                    var timeY = rowMidY - dc.getFontHeight(timeFont) / 2;
                    dc.setColor(r == 0 ? highlightFg : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    
                    var displayTime = depTime;
                    if (r == 0 && subRegion != null) {
                        displayTime = displayTime + " P" + depPlatform;
                    }
                    dc.drawText(leftMargin, timeY, timeFont, displayTime, Graphics.TEXT_JUSTIFY_LEFT);

                    dc.setColor(r == 0 ? highlightFg : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    
                    if (r > 0 || subRegion == null) {
                        dc.drawText(boardCenterX, rowMidY - dc.getFontHeight(infoFont) / 2, infoFont, rowCountdown, Graphics.TEXT_JUSTIFY_CENTER);
                    }

                    if (r > 0 || subRegion == null) {
                        // Keep text color same as previous drawText
                        dc.drawText(rightEdge, rowMidY - dc.getFontHeight(infoFont) / 2, infoFont, "P" + depPlatform, Graphics.TEXT_JUSTIFY_RIGHT);
                    }

                    if (r < departures.size() - 1) {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawLine(leftMargin, rowTop + rowHeight - 1, rightEdge, rowTop + rowHeight - 1);
                    }

                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                }

                if (subRegion != null) {
                    var subCenterX = subRegion.x + (subRegion.width / 2);
                    var subCenterY = subRegion.y + (subRegion.height / 2);
                    
                    // Draw countdown in subscreen
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(subCenterX, subCenterY, Graphics.FONT_MEDIUM, countdown, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            } else {
                var activeStationCode = ScheduleHelper.getActiveStationCode();
                var activeStationName = StationData.getStationNameFromCode(activeStationCode);
                if (subRegion != null) {
                    var subCenterX = subRegion.x + (subRegion.width / 2);
                    var subCenterY = subRegion.y + (subRegion.height / 2);
                    dc.drawText(subCenterX, subCenterY, Graphics.FONT_SMALL, "-", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
                var headerY = (height * 0.25).toNumber();
                dc.drawText(width / 2, headerY, Graphics.FONT_SMALL, activeStationName, Graphics.TEXT_JUSTIFY_CENTER);
                
                var msgY = headerY + dc.getFontHeight(Graphics.FONT_SMALL) + 15;
                if (mIsLoading) {
                    dc.drawText(width / 2, msgY, Graphics.FONT_TINY, "Loading...", Graphics.TEXT_JUSTIFY_CENTER);
                } else if (mError != null) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(width / 2, msgY, Graphics.FONT_TINY, mError, Graphics.TEXT_JUSTIFY_CENTER);
                } else {
                    dc.drawText(width / 2, msgY, Graphics.FONT_TINY, "No trains", Graphics.TEXT_JUSTIFY_CENTER);
                }
            }
            
            // Draw a small loading indicator if we have cached data but are fetching fresh data
            if (mIsLoading && departures.size() > 0) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(width - 5, 5, 2);
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

}

class GotrainInputDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        SettingsMenu.pushMainMenu();
        return true;
    }

    function onTap(clickEvent) as Boolean {
        return onMenu();
    }
}
