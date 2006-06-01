##################################################
# Engines
##################################################
# input properties
# /engines/engine[n]/oil-pressure-psi
# /engines/engine[n]/mp-osi
# output properties
# /instrumentation/annunciator/oil
##################################################
Engines = {};
Engines.new = func {
  obj = {};
  obj.parents = [Engines];

  obj.enginesNode = props.globals.getNode( "/engines" );
  obj.engineNodes = obj.enginesNode.getChildren( "engine" );

  obj.annunciatorNode = props.globals.getNode( "/instrumentation/annunciator" );
  obj.oilNode = obj.annunciatorNode.getNode( "oil", 1 );
  obj.oilNode.setBoolValue( 0 );

  for( i = 0; i < size(obj.engineNodes); i = i+1 ) {
    s = "overboost[" ~ i ~ "]";
    n = obj.annunciatorNode.getNode( s, 1 );
    n.setBoolValue( 0 );
  }
  obj.overboostNodes = obj.annunciatorNode.getChildren( "overboost" );
  return obj;
}

Engines.update = func {
  me.oil = 0;

  for( i = 0; i < size(me.engineNodes); i = i+1 ) {
    oil_pressure_psi = me.engineNodes[i].getNode("oil-pressure-psi").getValue();
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
GearInTransit = {};
GearInTransit.new = func {
  obj = {};
  obj.parents = [GearInTransit];
  obj.gearNode = props.globals.getNode( "/gear" );
  obj.gearNodes = obj.gearNode.getChildren( "gear" );
  obj.inTransitNode = obj.gearNode.getNode( "in-transit", 1 );
  obj.inTransitNode.setBoolValue( 0 );
  return obj;
}

GearInTransit.update = func {
  inTransit = 0;

  for( i = 0; i < size(me.gearNodes); i = i+1 ) {
    position_norm = me.gearNodes[i].getNode("position-norm").getValue();
    if( position_norm != nil and position_norm > 0.0 and position_norm < 1.0 ) {
      inTransit = 1;
      break;
    }
  }
  if( inTransit == 0 ) {
    me.inTransitNode.setBoolValue( 0 );
  } else {
    me.inTransitNode.setBoolValue( 1 );
  }
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
Suction= {};

Suction.new = func {
  obj = {};
  obj.parents = [Suction];
  obj.vacuumNodes = props.globals.getNode("/systems").getChildren("vacuum");

  obj.instrumentationNode = props.globals.getNode( "/instrumentation/vacuum", 1 );
  obj.suctionNode = obj.instrumentationNode.getNode( "suction-inhg", 1 );
  
  for( i = 0; i < size(obj.vacuumNodes); i = i+1 ) {
    s = "inoperative[" ~ i ~ "]";
    n = obj.instrumentationNode.getNode( s, 1 );
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

  for( i = 0; i < size(me.vacuumNodes); i = i+1 ) {
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
heightNode = props.globals.getNode( "/position/altitude-agl-ft", "true" );
heightNode.setDoubleValue( 0.0 );
dhNode = props.globals.getNode( "/instrumentation/radar-altimeter/decision-height", "true" );
dhNode.setDoubleValue( 0.0 );
dhFlagNode = props.globals.getNode( "/instrumentation/radar-altimeter/decision-height-flag", "true" );
dhFlagNode.setBoolValue( 0 );

###################################################
# set DH Flag
# do this by polling, because setlistener on /position/altitude-agl-ft does not trigger :-(
#
dhflag = -1;
radarAltimeter = func {
  d = 0;
  if( heightNode.getValue() <= dhNode.getValue() ) {
    d = 1;
  }
  if( d != dhflag ) {
    dhflag = d;
    dhFlagNode.setBoolValue( dhflag );
  }
  settimer( radarAltimeter, 0.5 );
}

settimer( radarAltimeter, 0.5 );

###################################################
# Slaved Gyro
# fast mode: 180deg/min - 3deg/sec
# slow mode: 3deg/min   - 0.05deg/sec
SlavedGyro = {};
SlavedGyro.new = func {
  obj = {};
  obj.parents = [SlavedGyro];

  obj.hiNode = props.globals.getNode( "/instrumentation/heading-indicator" );
  obj.errorIndicatorNode = obj.hiNode.getNode( "error-indicator", 1 );
  obj.errorIndicatorNode.setDoubleValue( 0 );

  obj.offsetNode = obj.hiNode.getNode( "offset-deg", 1 );

  obj.modeNode = obj.hiNode.getNode( "mode-auto", 1 );
  obj.modeNode.setBoolValue( 0 );

  obj.rotateNode = obj.hiNode.getNode( "rotate", 1 );
  obj.rotateNode.setIntValue( 0 );

  obj.timeNode = props.globals.getNode( "/sim/time/elapsed-sec" );
 
  obj.fastrate = 3;
  obj.slowrate = 0.05;
  obj.last = obj.timeNode.getValue();
  obj.dt = 0;

  return obj;
}

SlavedGyro.update = func {
  now = me.timeNode.getValue();
  me.dt = now - me.last;
  me.last = now;

  if( me.modeNode.getBoolValue() ) {
    # slaved
    offset = me.offsetNode.getValue();
 
    rate = 0.0;
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
  rate = arg[0];
  if( rate == 0 ) {
    return;
  }
  me.offsetNode.setDoubleValue( me.offsetNode.getValue() - me.dt * rate );
}



###################################################
gearInTransit = GearInTransit.new();
suction = Suction.new();
engines = Engines.new();

slavedGyro = SlavedGyro.new();

seneca_update = func {
  gearInTransit.update();
  suction.update();
  engines.update();
  slavedGyro.update();
  settimer(seneca_update, 0);
}

settimer(seneca_update, 0);

paxDoor = aircraft.door.new( "/sim/model/door-positions/pax-door", 1, 0 );
baggageDoor = aircraft.door.new( "/sim/model/door-positions/baggage-door", 2, 0 );
rightDoor = aircraft.door.new( "/sim/model/door-positions/right-door", 1, 0 );

sbc1 = aircraft.light.new( "/sim/model/lights/sbc1", 0.5, 0.3 );
sbc1.interval = 0.1;
sbc1.switch( 1 );

sbc2 = aircraft.light.new( "/sim/model/lights/sbc2", 0.2, 0.3, "/sim/model/lights/sbc1/state" );
sbc2.interval = 0;
sbc2.switch( 1 );

setlistener( "/sim/model/lights/sbc2/state", func {
  bsbc1 = sbc1.stateN.getValue();
  bsbc2 = cmdarg().getBoolValue();
  b = 0;
  if( bsbc1 and bsbc2 and getprop( "/controls/lighting/beacon") ) {
    b = 1;
  } else {
    b = 0;
  }
  setprop( "/sim/model/lights/beacon/enabled", b );

  if( bsbc1 and !bsbc2 and getprop( "/controls/lighting/strobe" ) ) {
    b = 1;
  } else {
    b = 0;
  }
  setprop( "/sim/model/lights/strobe/enabled", b );
});

beacon = aircraft.light.new( "/sim/model/lights/beacon", 0.05, 0.05 );
beacon.interval = 0;

strobe = aircraft.light.new( "/sim/model/lights/strobe", 0.05, 0.05 );
strobe.interval = 0;

setprop( "/instrumentation/nav[0]/ident", 0 );
setprop( "/instrumentation/nav[1]/ident", 0 );

########################################
# Watch the propeller pitch for feather
########################################
pitchlistener = func {
  node = cmdarg();
  featherN = node.getParent().getChild( "propeller-feather" );
  if( node.getValue() < 0.1 ) {
    if( featherN.getBoolValue() == 0 ) {
      featherN.setBoolValue( 1 );
    }
  } else { 
    if( featherN.getBoolValue() == 1 ) {
      featherN.setBoolValue( 0 );
    }
  }
};

setlistener( "/controls/engines/engine[0]/propeller-pitch", pitchlistener );
setlistener( "/controls/engines/engine[1]/propeller-pitch", pitchlistener );
########################################

########################################
# Sync the magneto switches with magneto properties
########################################
setmagneto = func {
  eng = arg[0];
  mag = arg[1];
  on = props.globals.getNode( "/controls/engines/engine[" ~ eng ~ "]/magneto[" ~ mag ~ "]" ).getValue();
  m = props.globals.getNode( "/controls/engines/engine[" ~ eng ~ "]/magnetos" );

  v = m.getValue();

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

magnetolistener = func {
  m = cmdarg();
  eng = m.getParent();
  m2 = eng.getChildren("magneto");
  v = m.getValue();
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

setlistener( "/controls/engines/engine[0]/magnetos", magnetolistener );
setlistener( "/controls/engines/engine[1]/magnetos", magnetolistener );

########################################
# Sync the fuel selector controls with the properties
#/controls/fuel/tank[n]/fuel_selector (boolean)
#/controls/fuel/tank[n]/to_engine (int)
########################################
fuelselectorlistener = func {
}

setlistener( "/controls/fuel/tank[0]/fuel_selector", fuelselectorlistener );
setlistener( "/controls/fuel/tank[1]/fuel_selector", fuelselectorlistener );
setlistener( "/controls/fuel/tank[0]/to_engine",     fuelselectorlistener );
setlistener( "/controls/fuel/tank[1]/to_engine",     fuelselectorlistener );

########################################
# create a rpm-norm property for propdisc transparency
########################################

rpmhandler = func {
  n = arg[0];
  t = n.getParent().getNode( "rpm-norm-inv", 1 );
  v = 1-n.getValue() / 2575;
  t.setDoubleValue( v );
}

lRPMN = props.globals.getNode( "/engines/engine[0]/rpm", 1 );
rRPMN = props.globals.getNode( "/engines/engine[1]/rpm", 1 );

#############################
# can do this with a timer
#rpmtimer = func {
#  rpmhandler( lRPMN );
#  rpmhandler( rRPMN );
#  settimer( rpmtimer, 0.5 );
#}
#rpmtimer();

rpmlistener = func {
  rpmhandler( cmdarg() );
}
#############################
# can do this with a listener
setlistener( lRPMN, rpmlistener );
setlistener( "/engines/engine[1]/rpm", rpmlistener );

########################################
# fuel pumps and primer
########################################
FuelPumpHandler = {};
FuelPumpHandler.new = func {
  m = {};
  m.parents = [FuelPumpHandler];
  m.engineControlRootN = props.globals.getNode( "/controls/engines/engine[" ~ arg[0] ~ "]" );
  m.annunciatorLightN = props.globals.getNode( "/instrumentation/annunciator/fuelpump[" ~ arg[0] ~ "]", 1 );
  if( m.annunciatorLightN.getValue() == nil ) {
    m.annunciatorLightN.setBoolValue( 0 );
  }

  m.fuelPumpControlN = m.engineControlRootN.getNode( "fuel-pump", 1 );
  if( m.fuelPumpControlN.getValue() == nil ) {
    m.fuelPumpControlN.setBoolValue( 0 );
  }
  m.primerControlN   = m.engineControlRootN.getNode( "primer", 1 );
  if( m.primerControlN.getValue() == nil ) {
    m.primerControlN.setBoolValue( 0 );
  }

  setlistener( m.fuelPumpControlN, func { m.listener() } );
  setlistener( m.primerControlN, func { m.listener() } );

  return m;
};

FuelPumpHandler.listener = func {
  v = me.fuelPumpControlN.getBoolValue();
  if( v == 0 ) {
    v = me.primerControlN.getBoolValue();
  }
  me.annunciatorLightN.setBoolValue( v );
};

FuelPumpHandler.new( 0 );
FuelPumpHandler.new( 1 );
