import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

module LayoutSystem {

    class Rect {
        var x as Number;
        var y as Number;
        var width as Number;
        var height as Number;

        function initialize(_x as Number, _y as Number, _width as Number, _height as Number) {
            x = _x;
            y = _y;
            width = _width;
            height = _height;
        }
    }

    class LayoutManager {
        
        var topLeftRegion as Rect or Null = null;
        var subScreenRegion as Rect or Null = null;
        var mainBodyRegion as Rect or Null = null;

        function initialize(dc as Graphics.Dc) {
            var screenWidth = dc.getWidth();
            var screenHeight = dc.getHeight();
            
            var subscreen = null;
            if (WatchUi has :getSubscreen) {
                subscreen = WatchUi.getSubscreen();
            }

            if (subscreen != null) {
                // Physical subscreen device (e.g. Instinct 2/3)
                subScreenRegion = new Rect(subscreen.x, subscreen.y, subscreen.width, subscreen.height);

                var horizontalMargin = (screenWidth * 0.12).toNumber();
                var topMargin = (screenHeight * 0.08).toNumber();
                var bottomMargin = (screenHeight * 0.12).toNumber();

                // Top-left stops before the cutout
                topLeftRegion = new Rect(
                    horizontalMargin, 
                    topMargin, 
                    subscreen.x - horizontalMargin, 
                    (subscreen.y + subscreen.height) - topMargin
                );

                // Main body sits below the subscreen, spans full width with margins
                var bodyStartY = subscreen.y + subscreen.height + 5;
                mainBodyRegion = new Rect(
                    horizontalMargin,
                    bodyStartY,
                    screenWidth - (horizontalMargin * 2),
                    screenHeight - bodyStartY - bottomMargin
                );
            } else {
                // Standard device fallback
                var shape = System.getDeviceSettings().screenShape;
                var horizontalMargin = 0;
                var verticalMargin = 0;
                
                if (shape == System.SCREEN_SHAPE_ROUND) {
                    // For round screens, use a larger margin to avoid corner clipping
                    horizontalMargin = (screenWidth * 0.15).toNumber();
                    verticalMargin = (screenHeight * 0.15).toNumber();
                } else if (shape == System.SCREEN_SHAPE_RECTANGLE) {
                    // Rectangular screens don't suffer from corner clipping
                    horizontalMargin = (screenWidth * 0.05).toNumber();
                    verticalMargin = (screenHeight * 0.05).toNumber();
                } else {
                    // Semi-round or other
                    horizontalMargin = (screenWidth * 0.10).toNumber();
                    verticalMargin = (screenHeight * 0.10).toNumber();
                }

                mainBodyRegion = new Rect(
                    horizontalMargin,
                    verticalMargin,
                    screenWidth - (horizontalMargin * 2),
                    screenHeight - (verticalMargin * 2)
                );
            }
        }
    }
}
