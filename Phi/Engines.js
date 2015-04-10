define([
        'jquery', 'knockout', 'text!./Engines.html', 'kojqui/slider'
], function(jquery, ko, htmlString ) {
    
  function DualGauge( v1, v2 ) {
    this.v1 = v1;
    this.v1 = v2;
  }

  function EngineControl( idx, label ) {
    var self = this;

    self.engineControl = "/controls/engines/engine";
    self.engineData = "/engines/engine";
    self.fuelData = "/consumables/fuel/tank";
    self.busData = "/systems/electrical/bus/element[" + (1+idx).toString() + "]/";
    if( idx > 0 ) {
        self.engineControl += "["+idx.toString() + "]";
        self.engineData += "["+idx.toString() + "]";
        self.fuelData += "["+idx.toString() + "]";
    }
    self.engineControl += "/";
    self.engineData += "/";
    self.fuelData += "/";

    self.idx = idx;
    self.label = label;
    self.map = ko.observable(0).extend({observedProperty: self.engineData + "mp-inhg"});
    self.rpm = ko.observable(0).extend({observedProperty: self.engineData + "rpm"});
    
    self.ff = ko.observable(0).extend({observedProperty: self.engineData + "fuel-flow-gph"});
    self.egt = ko.observable(0).extend({observedProperty: self.engineData + "egt-degf"});
    self.suction = ko.observable(0);
    self.amps = ko.observable(0).extend({observedProperty: self.busData + "i"});
    self.cht = ko.observable(0).extend({observedProperty: self.engineData + "cht-degf"});
    self.oilTemp = ko.observable(0).extend({observedProperty: self.engineData + "oil-temperature-degf"});
    self.oilPress = ko.observable(0).extend({observedProperty: self.engineData + "oil-pressure-psi"});
    self.fuel = ko.observable(0).extend({observedProperty: self.fuelData + "level-gal_us"});

    self.throttle = ko.observable(0).extend({observedProperty: self.engineControl + "throttle"});
    self.mixture = ko.observable(0).extend({observedProperty: self.engineControl + "mixture"});
    self.pitch = ko.observable(0).extend({observedProperty: self.engineControl + "propeller-pitch"});

    self.magnetoL = ko.observable(false);
    self.magnetoR = ko.observable(false);
    self.primer = ko.observable(false);
    self.starter = ko.observable(false).extend({observedProperty: self.engineControl + "starter"});
    self.fpL = ko.observable(false);
    self.fpH = ko.observable(false);

    self.setThrottle = function(evt,ui) {
      ko.utils.knockprops.setPropertyValue( self.engineControl + "throttle", ui.value );
    }

    self.setMixture = function(evt,ui) {
      ko.utils.knockprops.setPropertyValue( self.engineControl + "mixture", ui.value );
    }

    self.setPitch = function(evt,ui) {
      ko.utils.knockprops.setPropertyValue( self.engineControl + "propeller-pitch", ui.value );
    }
  }

  EngineControl.prototype.dispose = function() {
    var self = this;
    self.rpm.dispose();
    self.map.dispose();
    self.ff.dispose();
    self.egt.dispose();
    self.amps.dispose();
    self.cht.dispose();
    self.oilTemp.dispose();
    self.oilPress.dispose();
    self.fuel.dispose();

    self.throttle.dispose();
    self.mixture.dispose();
    self.pitch.dispose();
  }

  function ViewModel() {
    var self = this;

    self.engineControls = [
      new EngineControl(0, 'Left Engine'),
      new EngineControl(1, 'Right Engine'),
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
      viewModel: ViewModel,
      template: htmlString
  }
});
