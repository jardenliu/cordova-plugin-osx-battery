var cordova = require('cordova');
var exec = require("cordova/exec");

var STATUS_CRITICAL = 5;
var STATUS_LOW = 20;

var OSXBattery = function () {
    this._level = null;
    this._isPlugged = null;
    this.channels = {
        batterystatus: cordova.addWindowEventHandler('batterystatus'),
        batterycritical: cordova.addWindowEventHandler('batterycritical'),
        batterylow: cordova.addWindowEventHandler('batterylow'),
    }
    for (var key in this.channels) {
        this.channels[key].onHasSubscribersChange = OSXBattery.onHasSubscribersChange;
    }
};

function handlers() {
    return battery.channels.batterystatus.numHandlers; +
    battery.channels.batterylow.numHandlers +
        battery.channels.batterycritical.numHandlers;
}

OSXBattery.onHasSubscribersChange = function () {
    if (this.numHandlers === 1 && handlers() === 1) {
        exec(battery._status, battery._error, 'OSXBattery', 'start', []);
    } else if (handlers() === 0) {
        exec(null, null, 'OSXBattery', 'stop', []);
    }
};

OSXBattery.prototype._status = function (info) {
    if (info) {
        if (battery._level !== info.level || battery._isPlugged !== info.isPlugged) {

            if (info.level === null && battery._level !== null) {
                return; // special case where callback is called because we stopped listening to the native side.
            }

            // Something changed. Fire batterystatus event
            cordova.fireWindowEvent('batterystatus', info);

            if (!info.isPlugged) { // do not fire low/critical if we are charging. issue: CB-4520
                // note the following are NOT exact checks, as we want to catch a transition from
                // above the threshold to below. issue: CB-4519
                if (battery._level > STATUS_CRITICAL && info.level <= STATUS_CRITICAL) {
                    // Fire critical battery event
                    cordova.fireWindowEvent('batterycritical', info);
                } else if (battery._level > STATUS_LOW && info.level <= STATUS_LOW) {
                    // Fire low battery event
                    cordova.fireWindowEvent('batterylow', info);
                }
            }
            battery._level = info.level;
            battery._isPlugged = info.isPlugged;
        }
    }
}

OSXBattery.prototype._error = function (e) {
    console.log('Error initializing OSXBattery: ' + e);
};

var battery = new OSXBattery();
module.exports = battery;