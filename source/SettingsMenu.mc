import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;

class SettingsMenu {
    static function formatHour(hour as Number) as String {
        if (hour == 0) { return "12:00 AM"; }
        if (hour < 12) { return hour + ":00 AM"; }
        if (hour == 12) { return "12:00 PM"; }
        return (hour - 12) + ":00 PM";
    }

    static function pushMainMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Settings"});
        
        var routeId = Application.Storage.getValue("RouteId");
        if (routeId == null) { routeId = 0; }
        var routeName = StationData.getRoutes().get(routeId);
        
        var depId = Application.Storage.getValue("DepartureStation");
        if (depId == null) { depId = 0; }
        var depName = StationData.getStationName(depId as Number);
        
        var arrId = Application.Storage.getValue("ArrivalStation");
        if (arrId == null) { arrId = 1; }
        var arrName = StationData.getStationName(arrId as Number);

        var flipHour = Application.Storage.getValue("FlipHour");
        if (flipHour == null) { flipHour = 12; }
        var flipStr = formatHour(flipHour as Number);

        menu.addItem(new WatchUi.MenuItem("Route", routeName as String, "route", null));
        menu.addItem(new WatchUi.MenuItem("Morning Station", depName, "departure", null));
        menu.addItem(new WatchUi.MenuItem("Afternoon Station", arrName, "arrival", null));
        menu.addItem(new WatchUi.MenuItem("Switch Time", flipStr, "flip_time", null));
        
        WatchUi.pushView(menu, new MainMenuDelegate(menu), WatchUi.SLIDE_IMMEDIATE);
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mMenu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        mMenu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        
        if (id.equals("route")) {
            var menu = new WatchUi.Menu2({:title => "Select Route"});
            var routes = StationData.getRoutes();
            var keys = routes.keys();
            for (var i = 0; i < keys.size(); i++) {
                var key = keys[i] as Number;
                menu.addItem(new WatchUi.MenuItem(routes.get(key) as String, null, key, null));
            }
            WatchUi.pushView(menu, new RouteMenuDelegate(item, mMenu), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("departure") || id.equals("arrival")) {
            var menu = new WatchUi.Menu2({:title => id.equals("departure") ? "Morning Station" : "Afternoon Station"});
            var routeId = Application.Storage.getValue("RouteId");
            if (routeId == null) { routeId = 0; }
            var stations = StationData.getStationsForRoute(routeId as Number);
            
            for (var i = 0; i < stations.size(); i++) {
                var stId = stations[i] as Number;
                var name = StationData.getStationName(stId);
                menu.addItem(new WatchUi.MenuItem(name, null, stId, null));
            }
            WatchUi.pushView(menu, new StationMenuDelegate(item, id), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("flip_time")) {
            var menu = new WatchUi.Menu2({:title => "Select Time"});
            for (var i = 0; i < 24; i++) {
                menu.addItem(new WatchUi.MenuItem(SettingsMenu.formatHour(i), null, i, null));
            }
            WatchUi.pushView(menu, new FlipTimeMenuDelegate(item), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

class RouteMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mParentItem as WatchUi.MenuItem;
    private var mMainMenu as WatchUi.Menu2;

    function initialize(parentItem as WatchUi.MenuItem, mainMenu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        mParentItem = parentItem;
        mMainMenu = mainMenu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var routeId = item.getId() as Number;
        Application.Storage.setValue("RouteId", routeId);
        mParentItem.setSubLabel(item.getLabel());
        
        // Auto-update the departure and arrival stations to be on the new route
        var stations = StationData.getStationsForRoute(routeId);
        if (stations.size() >= 1) {
            var depId = stations[0];
            var arrId = stations.size() > 1 ? stations[1] : stations[0];
            
            Application.Storage.setValue("DepartureStation", depId);
            Application.Storage.setValue("ArrivalStation", arrId);
            
            var depItem = mMainMenu.getItem(1) as WatchUi.MenuItem;
            var arrItem = mMainMenu.getItem(2) as WatchUi.MenuItem;
            
            if (depItem != null) {
                depItem.setSubLabel(StationData.getStationName(depId));
            }
            if (arrItem != null) {
                arrItem.setSubLabel(StationData.getStationName(arrId));
            }
        }
        
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class StationMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mParentItem as WatchUi.MenuItem;
    private var mType as String;

    function initialize(parentItem as WatchUi.MenuItem, type as String) {
        Menu2InputDelegate.initialize();
        mParentItem = parentItem;
        mType = type;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var stationId = item.getId() as Number;
        if (mType.equals("departure")) {
            Application.Storage.setValue("DepartureStation", stationId);
        } else {
            Application.Storage.setValue("ArrivalStation", stationId);
        }
        mParentItem.setSubLabel(item.getLabel());
        
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class FlipTimeMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mParentItem as WatchUi.MenuItem;

    function initialize(parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        mParentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var hour = item.getId() as Number;
        Application.Storage.setValue("FlipHour", hour);
        mParentItem.setSubLabel(item.getLabel());
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
