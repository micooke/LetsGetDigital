using Toybox.WatchUi as Ui;

class LetsGetDigitalApp extends Toybox.Application.AppBase {
	hidden var LGD;
	function initialize() {
		AppBase.initialize();
	}

	function onStart(state) {
	}

	function onStop(state) {
	}

	function getInitialView() {
		LGD = new LetsGetDigitalView();
		return [ LGD ];
	}

	function onSettingsChanged() {
		LGD.onSettingsChanged();
	}

}
