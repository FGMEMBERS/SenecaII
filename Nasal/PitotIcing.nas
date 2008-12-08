#########################################################################################
# $Id$
# Fail the airspeed indicator due to icing of the pitot tube
# Maintainer: Torsten Dreyer (Torsten at t3r dot de)
#
# $Log$
# Revision 1.3  2008/12/08 21:35:37  torsten
# initNode - not getNode. Thanks m.
#
# Revision 1.2  2008/12/08 21:23:38  torsten
# make use of initNode
#
# Revision 1.1  2007-11-29 18:26:49  mfranz
# Torsten DREYER:
#
# - add var to local variables
# - relaxed timer in electrical.nas
# - some cleanup
# - added support for pitot icing"
#
# 
# inputs
# /instrumentation/airspeed-indicator[n]/icing
#
# outputs
# /instrumentation/airspeed-indicator/serviceable          
# /instrumentation/airspeed-indicator/indicated-speed-kt
#########################################################################################

var PitotIcingHandler = {};
PitotIcingHandler.new = func {
  var m = {};
  m.parents = [PitotIcingHandler];

  m.failAtIcelevel = arg[1];

  m.baseNodeName = "/systems/pitot[" ~ arg[0] ~ "]";

  print( "creating PitotIcingHandler for " ~ m.baseNodeName );

  m.baseN = props.globals.getNode( m.baseNodeName );

  m.icingN = m.baseN.initNode( "icing", 0.0 );

  m.serviceableN = m.baseN.initNode( "serviceable", 1, "BOOL" );

  setlistener( m.icingN, func { m.listener() } );

  return m;
};

#########################################################################################
# The handler. Check if ice is above threshold, then fail the device
#########################################################################################

PitotIcingHandler.listener = func {

  if( me.icingN.getValue() < me.failAtIcelevel ) {
    # everything is fine

    if( me.serviceableN.getBoolValue() == 0 ) {
      # if the inidcator failed before, re-enable it
      print( me.baseNodeName ~ " is functional again" );
      me.serviceableN.setBoolValue( 1 );
    }

  } else {
    # pitot is iced

    if( me.serviceableN.getBoolValue() != 0 ) {
      # if the indicator was servicable before, fail it now
      print( me.baseNodeName ~ " is failing" );
      me.serviceableN.setBoolValue( 0 );
    }

  }
};

# Fail pitot at 0.03" of ice
PitotIcingHandler.new( 0, 0.03 );
