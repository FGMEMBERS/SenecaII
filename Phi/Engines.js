define([
        'jquery', 'knockout', 'text!./Engines.html', 'kojqui/slider'
], function(jquery, ko, htmlString) {

    function DualGauge(v1, v2) {
        this.v1 = v1;
        this.v1 = v2;
    }

    function EngineControl(idx, label) {
        var self = this;

        self.engineControl = "/controls/engines/engine";
        self.engineData = "/engines/engine";
        self.fuelData = "/consumables/fuel/tank";
        self.fuelControl = "/controls/fuel/tank";
        self.busData = "/systems/electrical/bus/element[" + (1 + idx).toString() + "]/";
        if (idx > 0) {
            self.engineControl += "[" + idx.toString() + "]";
            self.engineData += "[" + idx.toString() + "]";
            self.fuelControl += "[" + idx.toString() + "]";
            self.fuelData += "[" + idx.toString() + "]";
        }
        self.engineControl += "/";
        self.engineData += "/";
        self.fuelControl += "/";
        self.fuelData += "/";

        self.idx = idx;
        self.label = label;
        self.map = ko.observable(0).extend({
            observedProperty : self.engineData + "mp-inhg"
        });
        self.rpm = ko.observable(0).extend({
            observedProperty : self.engineData + "rpm"
        });

        self.ff = ko.observable(0).extend({
            observedProperty : self.engineData + "fuel-flow-gph"
        });
        self.egt = ko.observable(0).extend({
            observedProperty : self.engineData + "egt-degf"
        });
        self.suction = ko.observable(0);
        self.amps = ko.observable(0).extend({
            observedProperty : self.busData + "i"
        });
        self.cht = ko.observable(0).extend({
            observedProperty : self.engineData + "cht-degf"
        });
        self.oilTemp = ko.observable(0).extend({
            observedProperty : self.engineData + "oil-temperature-degf"
        });
        self.oilPress = ko.observable(0).extend({
            observedProperty : self.engineData + "oil-pressure-psi"
        });
        self.fuel = ko.observable(0).extend({
            observedProperty : self.fuelData + "level-gal_us"
        });

        self.throttle = ko.observable(0).extend({
            observedProperty : self.engineControl + "throttle"
        });
        self.mixture = ko.observable(0).extend({
            observedProperty : self.engineControl + "mixture"
        });
        self.pitch = ko.observable(0).extend({
            observedProperty : self.engineControl + "propeller-pitch"
        });

        self.magnetos = ko.observable(0).extend({
            observedProperty : self.engineControl + "magnetos"
        });

        function getBoolIcon(b) {
            return {
                primary : b ? 'ui-icon-check' : 'ui-icon-radio-off'
            }
        }

        self.magnetoRIcon = ko.pureComputed(function() {
            return getBoolIcon((self.magnetos() & 2) == 2);
        });

        self.magnetoLIcon = ko.pureComputed(function() {
            return getBoolIcon((self.magnetos() & 1) == 1);
        });
        
        self.toggleLMagneto = function() {
            var l = ~(self.magnetos() & 1);
            var r = (self.magnetos() & 2);
            self.magnetos.fgSetPropertyValue( (l|r)&3 );
        }

        self.toggleRMagneto = function() {
            var l = (self.magnetos() & 1);
            var r = ~(self.magnetos() & 2);
            self.magnetos.fgSetPropertyValue( (l|r)&3 );
        }

        self.primer = ko.observable(false).extend({
            observedProperty : self.engineControl + "primer"
        });

        self.primerIcon = ko.pureComputed(function() {
            return getBoolIcon(self.primer());
        });

        self.togglePrimer = function() {
            self.primer.fgSetPropertyValue( !self.primer() );
        }

        self.starter = ko.observable(false).extend({
            observedProperty : self.engineControl + "starter-switch"
        });

        self.starterIcon = ko.pureComputed(function() {
            return getBoolIcon(self.starter());
        });

        self.toggleStarter = function() {
            self.starter.fgSetPropertyValue( !self.starter() );
        }

        self.fuelPump = ko.observable(false).extend({
            observedProperty : self.engineControl + "fuel-pump"
        });

        self.toggleFuelPump = function() {
            self.fuelPump.fgSetPropertyValue( !self.fuelPump() );
        }

        self.fuelPumpIcon = ko.pureComputed(function() {
            return getBoolIcon(self.fuelPump());
        });

        self.cowlFlaps = ko.observable(false).extend({
            observedProperty : self.engineControl + "cowl-flaps-norm"
        });

        self.cowlFlapsIcon = ko.pureComputed(function() {
            return getBoolIcon(self.cowlFlaps());
        });

        self.toggleCowlFlaps = function() {
            self.cowlFlaps.fgSetPropertyValue( !self.cowlFlaps() );
        }

        self.altAir = ko.observable(false).extend({
            observedProperty : self.engineControl + "alternate-air"
        });

        self.altAirIcon = ko.pureComputed(function() {
            return getBoolIcon(self.altAir());
        });
        
        self.toggleAltAir = function() {
            self.altAir.fgSetPropertyValue( !self.altAir() );
        }

        self.fuelSelector = ko.observable(0).extend({
            observedProperty : self.fuelControl + "fuel_selector-position"
        });

        self.fuelTankOnIcon = ko.pureComputed(function() {
            return getBoolIcon(self.fuelSelector() > 0);
        });

        self.fuelTankOffIcon = ko.pureComputed(function() {
            return getBoolIcon(self.fuelSelector() == 0);
        });

        self.fuelTankXIcon = ko.pureComputed(function() {
            return getBoolIcon(self.fuelSelector() < 0);
        });
        
        self.fuelTankOn = function() {
            self.fuelSelector.fgSetPropertyValue( 1 );
        }

        self.fuelTankOff = function() {
            self.fuelSelector.fgSetPropertyValue( 0 );
        }

        self.fuelTankX = function() {
            self.fuelSelector.fgSetPropertyValue( -1 );
        }

        self.setThrottle = function(evt, ui) {
            self.throttle.fgSetPropertyValue( ui.value );
        }

        self.setMixture = function(evt, ui) {
            self.mixture.fgSetPropertyValue( ui.value );
        }

        self.setPitch = function(evt, ui) {
            self.pitch.fgSetPropertyValue( ui.value );
        }
    }

    EngineControl.prototype.dispose = function() {
        var self = this;

        for ( var pn in self) {
            var p = self[pn];
            if (typeof (p) === 'function' && typeof (p.dispose) === 'function') {
                p.dispose();
            }
        }
    }

    function ViewModel() {
        var self = this;

        self.engineControls = [
                new EngineControl(0, 'Left Engine'), new EngineControl(1, 'Right Engine'),
        ];

        self.leftRPM = self.engineControls[0].rpm;
        self.rightRPM = self.engineControls[1].rpm;

        self.leftMAP = self.engineControls[0].map;
        self.rightMAP = self.engineControls[1].map;

        self.leftFF = self.engineControls[0].ff;
        self.rightFF = self.engineControls[1].ff;

        self.leftEGT = self.engineControls[0].egt;
        self.rightEGT = self.engineControls[1].egt;

        self.leftCHT = self.engineControls[0].cht;
        self.rightCHT = self.engineControls[1].cht;

        self.leftOilTemp = self.engineControls[0].oilTemp;
        self.rightOilTemp = self.engineControls[1].oilTemp;

        self.leftOilPress = self.engineControls[0].oilPress;
        self.rightOilPress = self.engineControls[1].oilPress;

        self.leftAmps = ko.pureComputed(function() {
            return -self.engineControls[0].amps();
        });

        self.rightAmps = ko.pureComputed(function() {
            return -self.engineControls[1].amps();
        });

        self.leftFuel = self.engineControls[0].fuel;
        self.rightFuel = self.engineControls[1].fuel;
    }

    ViewModel.prototype.dispose = function() {
        var self = this;
        self.engineControls.forEach(function(e) {
            e.dispose();
            delete e;
        });
    }

    return {
        viewModel : ViewModel,
        template : htmlString
    }
});
