import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;

(:background)
class GotrainApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    (:glance)
    function registerBackgroundEvent() {
        if (System has :ServiceDelegate) {
            try {
                var lastTime = Background.getLastTemporalEventTime();
                if (lastTime != null) {
                    var nextTime = lastTime.add(new Time.Duration(15 * 60));
                    Background.registerForTemporalEvent(nextTime);
                } else {
                    Background.registerForTemporalEvent(Time.now());
                }
            } catch (ex) {
                System.println("Background registration failed: " + ex.getErrorMessage());
            }
        }
    }

    // Return the initial view of your application here
    function getInitialView() {
        registerBackgroundEvent();
        
        return [ new GotrainView(), new GotrainInputDelegate() ];
    }
    
    // Return the glance view of your application here
    (:glance)
    function getGlanceView() {
        registerBackgroundEvent();
        return [ new GlanceView() ];
    }
    
    // Return the service delegate for background tasks
    function getServiceDelegate() {
        return [ new GotrainBackground() ];
    }
    
    // Handle data returned from the background process
    function onBackgroundData(data as Application.PersistableType) as Void {
        if (data != null && data instanceof Array) {
            var station = ScheduleHelper.getActiveStationCode();
            ScheduleHelper.saveLiveDepartures(station, data as Array<Dictionary>);
            WatchUi.requestUpdate();
        }
    }
}

function getApp() as GotrainApp {
    return Application.getApp() as GotrainApp;
}