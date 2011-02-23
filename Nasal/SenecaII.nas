#############################################################################
# This file is part of FlightGear, the free flight simulator
# http://www.flightgear.org/
#
# Copyright (C) 2009 Torsten Dreyer, Torsten (at) t3r _dot_ de
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#############################################################################

var seneca_init = func {
  props.globals.initNode( "autopilot/CENTURYIII/controls/mode", 2, "INT" );
  props.globals.initNode( "autopilot/CENTURYIII/controls/manual-trim", 0, "INT" );
  props.globals.initNode( "autopilot/CENTURYIII/controls/disconnect", 0, "BOOL" );
  aircraft.data.add(
    "instrumentation/airspeed-indicator/tas-face-rotation",
    "instrumentation/attitude-indicator[0]/horizon-offset-deg",
    "instrumentation/attitude-indicator[1]/horizon-offset-deg",
    "instrumentation/altimeter[0]/setting-inhg",
    "instrumentation/altimeter[1]/setting-inhg",
    "instrumentation/radar-altimeter/decision-height",
    "instrumentation/comm[0]/volume",
    "instrumentation/comm[0]/frequencies/selected-mhz",
    "instrumentation/comm[0]/frequencies/standby-mhz",
    "instrumentation/comm[0]/test-btn",
    "instrumentation/nav[0]/audio-btn",
    "instrumentation/nav[0]/power-btn",
    "instrumentation/nav[0]/frequencies/selected-mhz",
    "instrumentation/nav[0]/frequencies/standby-mhz",
    "instrumentation/comm[1]/volume",
    "instrumentation/comm[1]/frequencies/selected-mhz",
    "instrumentation/comm[1]/frequencies/standby-mhz",
    "instrumentation/comm[1]/test-btn",
    "instrumentation/nav[1]/audio-btn",
    "instrumentation/nav[1]/power-btn",
    "instrumentation/nav[1]/frequencies/selected-mhz",
    "instrumentation/nav[1]/frequencies/standby-mhz",
    "instrumentation/nav[1]/radials/selected-deg",
    "instrumentation/dme/frequencies/selected-mhz",
    "instrumentation/dme/switch-position",
    "instrumentation/adf/model",
    "instrumentation/adf/rotation-deg",
    "sim/model/hide-yoke",
    "sim/model/hide-windshield-deice",
    "engines/engine[0]/egt-bug",
    "engines/engine[1]/egt-bug",
    "controls/engines/engine[0]/cowl-flaps-norm",
    "controls/engines/engine[1]/cowl-flaps-norm",
    "autopilot/CENTURYIII/controls/mode",
    "controls/electric/battery-switch",
    "controls/electric/avionic-switch"
  );
  ki266.new(0);
};

setlistener("/sim/signals/fdm-initialized", seneca_init );

var paxDoor = aircraft.door.new( "/sim/model/door-positions/pax-door", 1, 0 );
var baggageDoor = aircraft.door.new( "/sim/model/door-positions/baggage-door", 2, 0 );
var rightDoor = aircraft.door.new( "/sim/model/door-positions/right-door", 1, 0 );

var beacon = aircraft.light.new( "/sim/model/lights/beacon", [0.05, 0.05, 0.05, 0.45 ], "/controls/lighting/beacon" );
var strobe = aircraft.light.new( "/sim/model/lights/strobe", [0.05, 0.05, 0.05, 0.05, 0.05, 0.35 ], "/controls/lighting/strobe" );

setprop( "/instrumentation/nav[0]/ident", 0 );
setprop( "/instrumentation/nav[1]/ident", 0 );

########################################
# Sync the magneto switches with magneto properties
########################################
var setmagneto = func {
  var eng = arg[0];
  var mag = arg[1];
  var on = props.globals.getNode( "/controls/engines/engine[" ~ eng ~ "]/magneto[" ~ mag ~ "]" ).getValue();
  var m = props.globals.getNode( "/controls/engines/engine[" ~ eng ~ "]/magnetos" );

  var v = m.getValue();

  # I wish nasal had binary operators...
  if( on ) {
    if( mag == 0 ) {
      if( v == 0 or v == 2 ) {
        v = v + 1;
      }
    }
    if( mag == 1 ) {
      if( v == 0 or v == 1 ) {
        v = v + 2;
      }
    }
  } else {
    if( mag == 0 ) {
      if( v == 1 or v == 3 ) {
        v = v - 1;
      }
    }
    if( mag == 1 ) {
      if( v ==2 or v == 3 ) {
        v = v - 2;
      }
    }
  }

  m.setIntValue( v );
}

var magnetolistener = func(m) {

  var eng = m.getParent();
  var m2 = eng.getChildren("magneto");
  var v = m.getValue();
  if( v == 0 ) {
    m2[0].setBoolValue( 0 );
    m2[1].setBoolValue( 0 );
  }
  if( v == 1 ) {
    m2[0].setBoolValue( 1 );
    m2[1].setBoolValue( 0);
  }
  if( v == 2 ) {
    m2[0].setBoolValue( 0 );
    m2[1].setBoolValue( 1 );
  }
  if( v == 3 ) {
    m2[0].setBoolValue( 1 );
    m2[1].setBoolValue( 1 );
  }
};

var magnetoswitchlistener = func(m) {
  setmagneto( m.getParent().getIndex(), m.getIndex() );
};

setlistener( "/controls/engines/engine[0]/magnetos", magnetolistener );
setlistener( "/controls/engines/engine[1]/magnetos", magnetolistener );
setlistener( "/controls/engines/engine[0]/magneto[0]", magnetoswitchlistener, 1, 0 );
setlistener( "/controls/engines/engine[0]/magneto[1]", magnetoswitchlistener, 1, 0 );
setlistener( "/controls/engines/engine[1]/magneto[0]", magnetoswitchlistener, 1, 0 );
setlistener( "/controls/engines/engine[1]/magneto[1]", magnetoswitchlistener, 1, 0 );

########################################
# Sync the dimmer controls with the according properties
########################################

var instrumentsFactorNode = props.globals.initNode( "/sim/model/material/instruments/factor", 1.0 );
var dimmerlistener = func(n) {
  if( n != nil )
    instrumentsFactorNode.setValue( n.getValue() );
}

setlistener( "/controls/lighting/instruments-norm", dimmerlistener, 1, 0 );

###############################################
# propagate the emergency gear extension switch 
# to the fcs of jsbsim
###############################################
var emergencyGearNode = props.globals.initNode( "controls/gear/gear-emergency-extend", 0, "BOOL" );
var normalGearNode = props.globals.initNode( "controls/gear/gear-down", 0, "BOOL" );
var fcsGearNode = props.globals.getNode( "fdm/jsbsim/gear/gear-cmd-emergency-norm", 1 );

# emergency extend at any time
setlistener( emergencyGearNode, func {
  if( emergencyGearNode.getValue() == 1 ) {
    fcsGearNode.setBoolValue( 1 );
  }
});

# remove emergency extend only if gear is down
setlistener( normalGearNode, func {
  if( normalGearNode.getValue() == 1 and emergencyGearNode.getValue() == 0 ) {
    fcsGearNode.setBoolValue( 0 );
  }
});

# reset compass rose rotation for the ki228
setlistener( "/instrumentation/adf[0]/model", func(n) {
  if( n != nil ) {
    var v = n.getValue();
    if( v != nil and v == "ki228" )
      setprop("instrumentation/adf[0]/rotation-deg", 0 );
  }
}, 1, 0 );

var MouseHandler = {
  new : func() {
    var obj = { parents : [ MouseHandler ] };

    obj.property = nil;
    obj.factor = 1.0;

    obj.YListenerId = setlistener( "devices/status/mice/mouse/accel-y", 
      func(n) { obj.YListener(n); }, 1, 0 );

    return obj;
  },

  YListener : func(n) {
    me.property == nil and return;
    me.factor == 0 and return;
    n == nil and return;
    var v = n.getValue();
    v == nil and return;
    fgcommand("property-adjust", props.Node.new({ 
      "offset" : v,
      "factor" : me.factor,
      "property" : me.property
    }));
  },

  set : func( property = nil, factor = 1.0 ) {
    me.property = property;
    me.factor = factor;
  },

};

var mouseHandler = MouseHandler.new();
