#########################################################################################
# $Id$
# this are the helper functions for the dme indicator ki266
# Maintainer: Torsten Dreyer (Torsten at t3r dot de)
#
# $Log$
# Revision 1.1  2006/06/01 12:58:33  mfranz
# Torsten Dreyer: version 0.3 of the PA34-200T Seneca II (2006.05.30)
#
#
# Basically, we listen to the "time to station", "distance to station" and "speed"
# properties and generate the values to show on the displays, based on the switch-
# setting.
#

dmePowerButtonNode = props.globals.getNode( "/instrumentation/dme/power-btn", "true" );
if( dmePowerButtonNode.getValue() == nil ) {
  dmePowerButtonNode.setBoolValue( 1 );
}

dmeDistNode = props.globals.getNode( "/instrumentation/dme/indicated-distance-nm", "true" );
if( dmeDistNode.getValue() == nil ) {
  dmeDistNode.setDoubleValue( 0.0 );
}

dmeTimeNode = props.globals.getNode( "/instrumentation/dme/indicated-time-min", "true" );
if( dmeTimeNode.getValue() == nil ) {
  dmeTimeNode.setDoubleValue( 0.0 );
}

dmeKtsNode = props.globals.getNode( "/instrumentation/dme/indicated-ground-speed-kt", "true" );
if( dmeKtsNode.getValue() == nil ) {
  dmeKtsNode.setDoubleValue( 0.0 );
}

dmeMinKtsSwitchNode = props.globals.getNode( "/instrumentation/dme/switch-min-kts", "true" );
if( dmeMinKtsSwitchNode.getValue() == nil ) {
  dmeMinKtsSwitchNode.setBoolValue( 1 );
}

dmeMinKtsDisplayNode = props.globals.getNode( "/instrumentation/dme/min-kts-display", "true" );
if( dmeMinKtsDisplayNode.getValue() == nil ) {
  dmeMinKtsDisplayNode.setDoubleValue( 0.0 );
}

dmeMilesDisplayNode = props.globals.getNode( "/instrumentation/dme[0]/miles-display", "true" );
if( dmeMilesDisplayNode.getValue() == nil ) {
  dmeMilesDisplayNode.setDoubleValue( 0.0 );
}

dmeLeftDotNode = props.globals.getNode( "/instrumentation/dme[0]/left-dot", "true" );
if( dmeLeftDotNode.getValue() == nil ) {
  dmeLeftDotNode.setBoolValue( 1 );
}

dmeUpdate = func {
  v = 0.0;
  if( dmeMinKtsSwitchNode.getValue() ) {
    v = dmeKtsNode.getValue();
  } else {
    v = dmeTimeNode.getValue();
  }
  if( v > 999.0 ) {
    v = 999.0;
  }
  if( v < 0.0 ) {
    v = 0.0;
  }
  dmeMinKtsDisplayNode.setDoubleValue( v );
}

dmeUpdate2 = func {
  v = cmdarg().getValue();
  if( v > 999.9 ) {
    v = 999.9;
  }
  if( v < 0.0 ) {
    v = 0.0;
  }
  if( v < 100.0 ) {
    dmeMilesDisplayNode.setDoubleValue( v * 10.0 );
    dmeLeftDotNode.setBoolValue( 1 );
  } else {
    dmeMilesDisplayNode.setDoubleValue( v );
    dmeLeftDotNode.setBoolValue( 0 );
  }
}

setlistener( "/instrumentation/dme/indicated-ground-speed-kt", dmeUpdate );
setlistener( "/instrumentation/dme/indicated-time-min", dmeUpdate );
setlistener( "/instrumentation/dme/indicated-distance-nm", dmeUpdate2 );
