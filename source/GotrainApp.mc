import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

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

    // Return the initial glance view
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new GotrainView(), new GotrainInputDelegate() ];
    }

    // Return the glance view
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new GlanceView() ];
    }

}

function getApp() as GotrainApp {
    return Application.getApp() as GotrainApp;
}