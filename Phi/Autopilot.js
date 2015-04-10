define([
        'jquery', 'knockout', 'text!./Autopilot.html', 'kojqui/slider'
], function(jquery, ko, htmlString) {

    function getBoolIcon(b) {
    }
    
    function controlProperty(p) {
        return "/autopilot/CENTURYIII/controls/" + p + "/button-state";
    }
    
    function ToggleButtonVM(ctrl) {
        var self = this;

        self.prop = ko.observable(false).extend({
            observedProperty : controlProperty(ctrl)
        });
        
        self.icon = ko.pureComputed(function() {
            return {
                primary : self.prop() ? 'ui-icon-check' : 'ui-icon-radio-off'
            }
        });

        self.toggle = function() {
            self.prop.fgSetPropertyValue( !self.prop() );
        }
    }

    ToggleButtonVM.prototype.dispose = function() {
      this.prop.dispose();
    }

    function ModeButtonVM(prop,pos) {
        var self = this;

        self.icon = ko.pureComputed(function() {
            return {
                primary : prop() == pos ? 'ui-icon-check' : 'ui-icon-radio-off'
            }
        });

        self.set = function() {
            prop.fgSetPropertyValue( pos );
        }
    }

    function SliderVM(p,min,max,step) {
        var self = this;

        self.value = ko.observable(false).extend({
            observedProperty : p
        });

        self.set = function(evt, ui) {
            self.value.fgSetPropertyValue( ui.value );
        }

        self.min = min;
        self.max = max;
        self.step = step || ((max-min)/10);
    }

    SliderVM.prototype.dispose = function() {
      this.value.dispose();
    }

    function ViewModel() {
        
        var self = this;
        
        self.mode = ko.observable(false).extend({
            observedProperty : "/autopilot/CENTURYIII/controls/mode"
        });
        
        self.roll = new ToggleButtonVM("roll");
        self.hdg = new ToggleButtonVM("hdg");
        self.alt = new ToggleButtonVM("alt");
        self.pitch = new ToggleButtonVM("pitch");

        self.targetRoll = new SliderVM("/autopilot/CENTURYIII/settings/roll-knob-deg",-20,20,.5);
        self.targetPitch = new SliderVM("/autopilot/CENTURYIII/settings/pitch-wheel-deg",-10,10,.25);
        self.omniMode = new ModeButtonVM(self.mode,0);
        self.navMode = new ModeButtonVM(self.mode,1);
        self.hdgMode = new ModeButtonVM(self.mode,2);
        self.locMode = new ModeButtonVM(self.mode,3);
        self.locrevMode = new ModeButtonVM(self.mode,4);
    }

    ViewModel.prototype.dispose = function() {
        var self = this;
        for( var p in self ) {
          if( p.dispose ) { 
            p.dispose();
            delete p;
          }
        }
    }

    return {
        viewModel : ViewModel,
        template : htmlString
    }
});
