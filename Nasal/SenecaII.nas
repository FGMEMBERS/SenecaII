##################################################
# Engines
##################################################
# input properties
# /engines/engine[n]/oil-pressure-psi
# /engines/engine[n]/mp-osi
# output properties
# /instrumentation/annunciator/oil
##################################################
var Engines = {};
Engines.new = func {
  var obj = {};
  obj.parents = [Engines];

  obj.enginesNode = props.globals.getNode( "/engines" );
  obj.engineNodes = obj.enginesNode.getChildren( "engine" );

  obj.annunciatorNode = props.globals.getNode( "/instrumentation/annunciator" );
  obj.oilNode = obj.annunciatorNode.initNode( "oil", 0, "BOOL" );

  for( var i = 0; i < size(obj.engineNodes); i = i+1 ) {
    var s = "overboost[" ~ i ~ "]";
    var n = obj.annunciatorNode.initNode( s, 0, "BOOL" );
  }
  obj.overboostNodes = obj.annunciatorNode.getChildren( "overboost" );

  obj.jsbEngineNodes = props.globals.getNode("/fdm/jsbsim/propulsion",1).getChildren("engine");
  obj.pressureNode      = props.globals.getNode( "/systems/static/pressure-inhg" );
  obj.totalPressureNode = props.globals.getNode( "/systems/pitot/total-pressure-inhg" ).getValue();

  obj.controlsNodes = props.globals.getNode( "/controls/engines" ).getChildren( "engine" );

  obj.cowlFlapsPosNode = props.globals.getNode( "/surface-positions/speedbrake-pos-norm", 1 );
  return obj;
}

Engines.update = func {
  me.oil = 0;

  for( var i = 0; i < size(me.engineNodes); i = i+1 ) {
    var oil_pressure_psi = me.engineNodes[i].getNode("oil-pressure-psi").getValue();
    if( oil_pressure_psi != nil and oil_pressure_psi < 30 ) {
      me.oil = 1;
      break;
    }

    me.mp_osi = me.engineNodes[i].getNode("mp-osi").getValue();
    if( me.mp_osi != nil and me.mp_osi > 40.0 ) {
      me.overboostNodes[i].setBoolValue( 1 );
    } else {
      me.overboostNodes[i].setBoolValue( 0 );
    }

    # create a rpm-norm-inv property for propdisc transparency
    me.rpm = me.engineNodes[i].getNode( "rpm", 1 ).getValue();
    if( me.rpm == nil ) {
      me.rpm = 0.0;
    }
    var rpm_norm = me.rpm/2575;
    if( rpm_norm > 1 ) {
      rpm_norm = 1;
    }
    me.engineNodes[i].getNode( "rpm-norm-inv", 1 ).setDoubleValue( 1-rpm_norm );

    if( i < size(me.jsbEngineNodes) ) {
      # twiggle with manifold pressure
      var mapAdjustNode = me.jsbEngineNodes[i].getNode( "map-adjust" );
      if( mapAdjustNode != nil ) {

        # map depends on RPM
        var ma = rpm_norm*0.37 + 0.63;
        mapAdjustNode.setDoubleValue( ma );

        # and on ram pressure
       if( me.pressureNode != nil and me.totalPressureNode != nil ) {
         var d = me.pressureNode.getValue();
         if( d != 0 ) {
           ma *= me.totalPressureNode.getValue() / d;
         }
       }

      }
    }

    # adjust cooling area of engine depending of position of cowl flaps
    # range 2 - 2.5
    if( me.cowlFlapsPosNode != nil and i < size(me.jsbEngineNodes) ) {
      var n = me.jsbEngineNodes[i].getNode("cooling-area");
      if( n != nil ) {
        n.setDoubleValue( me.cowlFlapsPosNode.getValue()*0.5 + 2 );
      }
    }

    # check for prop feather
    var featherN = me.controlsNodes[i].getChild( "propeller-feather" );
    if( me.controlsNodes[i].getChild( "propeller-pitch" ).getValue() < 0.1 ) {
      if( featherN.getBoolValue() == 0 and me.rpm > 800 ) {
        featherN.setBoolValue( 1 );
      }
    } else { 
      if( featherN.getBoolValue() == 1 and me.rpm > 400 ) {
        featherN.setBoolValue( 0 );
      }
    }
  }
  me.oilNode.setBoolValue( me.oil );
}

##################################################
# Gear in Transit 
##################################################
# input properties
# /gear/gear[n]/position-norm
# output properties
# /gear/in-transit if any position-norm not 0 and not 1
##################################################
var GearInTransit = {};
GearInTransit.new = func {
  var obj = {};
  obj.parents = [GearInTransit];
  obj.gearNode = props.globals.getNode( "/gear" );
  obj.gearNodes = obj.gearNode.getChildren( "gear" );
  obj.inTransitNode = obj.gearNode.initNode( "in-transit", 0 "BOOL" );
  return obj;
}

GearInTransit.update = func {
  var inTransit = 0;

  for( i = 0; i < size(me.gearNodes); i = i+1 ) {
    var position_norm = me.gearNodes[i].getNode("position-norm").getValue();
    if( position_norm != nil and position_norm > 0.0 and position_norm < 1.0 ) {
      inTransit = 1;
      break;
    }
  }
  me.inTransitNode.setBoolValue( inTransit );
}

##################################################
# Suction 
##################################################
# input properties
# /system/vacuum[n]/suction-inhg
# output properties
# /instrumentation/vacuum/suction-inhg    max of all suction-inhg
# /instrumentation/vacuum/inoperative[n]  true if suction-inhg is less 3.5
# /instrumentation/annunciator/suction    true if any suction is inoperative
##################################################
var Suction= {};

Suction.new = func {
  var obj = {};
  obj.parents = [Suction];
  obj.vacuumNodes = props.globals.getNode("/systems").getChildren("vacuum");

  obj.instrumentationNode = props.globals.getNode( "/instrumentation/vacuum", 1 );
  obj.suctionNode = obj.instrumentationNode.getNode( "suction-inhg", 1 );
  
  for( var i = 0; i < size(obj.vacuumNodes); i = i+1 ) {
    var s = "inoperative[" ~ i ~ "]";
    var n = obj.instrumentationNode.getNode( s, 1 );
    n.setBoolValue( 1 );
  }
  obj.inoperativeNodes = obj.instrumentationNode.getChildren( "inoperative" );

  obj.annunciatorNode = props.globals.getNode( "/instrumentation/annunciator/vacuum", 1 );

  return obj;
}

Suction.update = func {
  me.suction_inhg = 0.0;
  me.annunciator = 0;

  # find max(suction-inhg) of all vacuum systems
  # end set warning-flag if U/S

  for( var i = 0; i < size(me.vacuumNodes); i = i+1 ) {
    me.suction = me.vacuumNodes[i].getNode("suction-inhg").getValue();
    if( me.suction > me.suction_inhg ) {
      me.suction_inhg = me.suction;
    }
    if( me.suction < 3.5 ) {
      me.inoperativeNodes[i].setBoolValue( 1 );
      me.annunciator = 1;
    } else {
      me.inoperativeNodes[i].setBoolValue( 0 );
    }
  }
  me.suctionNode.setDoubleValue( me.suction_inhg );
  me.annunciatorNode.setBoolValue( me.annunciator );
}

##################################################
var heightNode = props.globals.initNode( "/position/altitude-agl-ft", 0.0 );
var dhNode = props.globals.initNode( "/instrumentation/radar-altimeter/decision-height", 0.0 );
var dhFlagNode = props.globals.initNode( "/instrumentation/radar-altimeter/decision-height-flag", 0, "BOOL" );

###################################################
# set DH Flag
var dhflag = -1;
var radarAltimeter = func {
  var d = 0;
  if( heightNode.getValue() <= dhNode.getValue() ) {
    d = 1;
  }
  if( d != dhflag ) {
    dhflag = d;
    dhFlagNode.setBoolValue( dhflag );
  }
}
###################################################
# Slaved Gyro
# fast mode: 180deg/min - 3deg/sec
# slow mode: 3deg/min   - 0.05deg/sec
var SlavedGyro = {};
SlavedGyro.new = func {
  var obj = {};
  obj.parents = [SlavedGyro];

  obj.hiNode = props.globals.getNode( "/instrumentation/heading-indicator" );
  obj.errorIndicatorNode = obj.hiNode.initNode( "error-indicator", 0.0 );
  obj.offsetNode = obj.hiNode.getNode( "offset-deg", 1 );
  obj.modeNode = obj.hiNode.getNode( "mode-auto", 1 );
  obj.rotateNode = obj.hiNode.initNode( "rotate", 0, "INT" );
  obj.timeNode = props.globals.getNode( "/sim/time/elapsed-sec" );
 
  obj.fastrate = 3;
  obj.slowrate = 0.05;
  obj.last = obj.timeNode.getValue();
  obj.dt = 0;

  return obj;
}

SlavedGyro.update = func {
  var now = me.timeNode.getValue();
  me.dt = now - me.last;
  me.last = now;

  if( me.modeNode.getBoolValue() ) {
    # slaved
    var offset = me.offsetNode.getValue();
 
    var rate = 0.0;
    if( offset >= 0.0 ) {
      rate = me.slowrate;
    }
    if( offset > 3.0 ) {
      rate = me.fastrate;
    } 
    if( offset < 0.0 ) {
      rate = -me.slowrate;
    } 
    if( offset < -3.0 ) {
      rate = -me.fastrate;
    } 
    me.rotate( rate );

  } else {
    # free
    me.rotate( me.fastrate * me.rotateNode.getValue() );
  }
}

SlavedGyro.rotate = func {
  var rate = arg[0];
  if( rate == 0 ) {
    return;
  }
  me.offsetNode.setDoubleValue( me.offsetNode.getValue() - me.dt * rate );
}



###################################################
var gearInTransit = GearInTransit.new();
var suction = Suction.new();
var engines = Engines.new();

var slavedGyro = SlavedGyro.new();

var seneca_update = func {
  gearInTransit.update();
  suction.update();
  engines.update();
  slavedGyro.update();
  radarAltimeter();
  settimer(seneca_update, 0.1 );
}

var seneca_init = func {
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
    "instrumentation/nav[0]/radials/selected-deg",
    "instrumentation/comm[1]/volume",
    "instrumentation/comm[1]/frequencies/selected-mhz",
    "instrumentation/comm[1]/frequencies/standby-mhz",
    "instrumentation/comm[1]/test-btn",
    "instrumentation/nav[1]/audio-btn",
    "instrumentation/nav[1]/power-btn",
    "instrumentation/nav[1]/frequencies/selected-mhz",
    "instrumentation/nav[1]/frequencies/standby-mhz",
    "instrumentation/nav[1]/radials/selected-deg",
    "instrumentation/adf/frequencies/selected-khz",
    "instrumentation/adf/frequencies/standby-khz",
    "instrumentation/dme/frequencies/selected-mhz",
    "instrumentation/dme/switch-position",
    "instrumentation/adf/model",
    "instrumentation/adf/rotation-deg",
    "autopilot/settings/heading-bug-deg",
    "sim/model/hide-yoke",
    "sim/model/hide-windshield-deice"
  );
  ki266.new(0);

#  LightSpots.new( "/sim/model/light-spots" );

  seneca_update();
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
# Sync the fuel selector controls with the properties
#/controls/fuel/tank[n]/fuel_selector (boolean)
#/controls/fuel/tank[n]/to_engine (int)
########################################
#fuelselectorlistener = func {
#}

#setlistener( "/controls/fuel/tank[0]/fuel_selector", fuelselectorlistener );
#setlistener( "/controls/fuel/tank[1]/fuel_selector", fuelselectorlistener );
#setlistener( "/controls/fuel/tank[0]/to_engine",     fuelselectorlistener );
#setlistener( "/controls/fuel/tank[1]/to_engine",     fuelselectorlistener );

########################################
# Sync the dimmer controls with the according properties
########################################

var instrumentsFactorNode = props.globals.getNode( "/sim/model/material/instruments/factor" );
var dimmerlistener = func(n) {

  instrumentsFactorNode.setValue( n.getValue() );
}

setlistener( "/controls/lighting/instruments-norm", dimmerlistener, 1, 0 );

########################################
# fuel pumps and primer
########################################
var FuelPumpHandler = {};
FuelPumpHandler.new = func {
  var m = {};
  m.parents = [FuelPumpHandler];
  m.engineControlRootN = props.globals.getNode( "/controls/engines/engine[" ~ arg[0] ~ "]" );
  m.annunciatorLightN = props.globals.initNode( "/instrumentation/annunciator/fuelpump[" ~ arg[0] ~ "]", 0, "BOOL" );

  m.fuelPumpControlN = m.engineControlRootN.initNode( "fuel-pump", 0, "BOOL" );
  m.primerControlN   = m.engineControlRootN.initNode( "primer", 0, "BOOL" );

  setlistener( m.fuelPumpControlN, func { m.listener() }, 1, 0 );
  setlistener( m.primerControlN, func { m.listener() }, 1, 0 );

  return m;
};

FuelPumpHandler.listener = func {
  var v = me.fuelPumpControlN.getBoolValue();
  if( v == 0 ) {
    v = me.primerControlN.getBoolValue();
  }
  me.annunciatorLightN.setBoolValue( v );
};

FuelPumpHandler.new( 0 );
FuelPumpHandler.new( 1 );

########################################
# Battery Master
########################################

var BatteryMasterHandler = {};

BatteryMasterHandler.new = func {
  var obj = {};
  obj.parents = [BatteryMasterHandler];
  obj.switchN = props.globals.initNode( "/controls/electric/battery-switch", 0, "BOOL" );
  obj.clients = [
    props.globals.getNode( "/instrumentation/nav[0]/serviceable", 1 ),
    props.globals.getNode( "/instrumentation/nav[1]/serviceable", 1 ),
    props.globals.getNode( "/instrumentation/adf[0]/serviceable", 1 )
  ];

  setlistener( obj.switchN, func { obj.listener() }, 1, 0 );

  return obj;
};

BatteryMasterHandler.listener = func {
  var v = me.switchN.getValue();
  foreach( var client; me.clients ) {
    client.setValue( v );
  }
};

var batteryMasterHandler = BatteryMasterHandler.new();

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

