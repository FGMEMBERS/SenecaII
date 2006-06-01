#############################################################################
BaseElement = {};

BaseElement.new = func {
  obj = {};
  obj.parents = [BaseElement];
  obj.node = arg[0];
  return obj;
}

BaseElement.baseElementUpdate = func {
}

BaseElement.update = func {
  me.baseElementUpdate(arg[0]);
}

BaseElement.insert = func {
  vector = arg[0];
  object = arg[1];
  position = 0;
  if( size(arg) > 2 ) {
    position = arg[2];
  }
  setsize( vector, size(vector) + 1 );
  for( i = size(vector)-1; i > position; i = i - 1 ) {
    vector[i] = vector[i-1];
  }
  vector[position] = object;
}

BaseElement.interpolate = func {
  x = arg[0];
  pairs = arg[1];

  n = size(pairs)-1;
  if( x <= pairs[0][0] ) {
    return pairs[0][1];
  }
  if( x >= pairs[n][0] ) {
    return pairs[n][0];
  }
  for( i = 0; i < n; i = i + 1 ) {
    if( x > pairs[i][0] and x <= pairs[i+1][0] ) {
      x1 = pairs[i][0];
      x2 = pairs[i+1][0];
      y1 = pairs[i][1];
      y2 = pairs[i+1][1];
      return (x - x1)/(x2-x1)*(y2-y1)+y1;
    }
  }
  print( "BaseElement.interpolate() is junk!" );
  return 0;
}

BaseElement.getLowPass = func {
  current = arg[0];
  target  = arg[1];
  timeratio = arg[2];

  if ( timeratio < 0.0 ) {
    if ( timeratio < -1.0 ) {
      #time went backwards; kill the filter
      current = target;
    } else {
      # ignore mildly negative time
    }
    return current;
  } 
  if ( timeratio < 0.2 ) {
    # Normal mode of operation; fast
    #  approximation to exp(-timeratio)
    current = current * (1.0 - timeratio) + target * timeratio;
    return current;
  } 

  if ( timeratio > 5.0 ) {
    # Huge time step; assume filter has settled
    current = target;
  } else {
    # Moderate time step; non linear response
    keep = math.exp(-timeratio);
    current = current * keep + target * (1.0 - keep);
  }
  return current;
}


#############################################################################
# a simple linear element, resistors, lights, batteries, generators etc.
#############################################################################
LinearElement = {};

# create a new linear element
# args: node ri [u0]
LinearElement.new = func {
  obj = BaseElement.new(arg[0]);
  obj.insert( obj.parents, LinearElement );
  obj.ri = arg[1];
  obj.u0 = 0;
  if( size(arg) > 2 ) {
    obj.u0 = arg[2];
  }
  # the current, that runs into our ri
  # so a load (drain) has a positive sign here and
  # a generator/battery (source) has a negative sign
  obj.i  = 0;

  obj.riNode = obj.node.getNode("ri","true");
  obj.u0Node = obj.node.getNode("u0","true");
  s = obj.node.getNode( "i-property" );
  if( s != nil ) {
    obj.iNode  = props.globals.getNode(s.getValue(),"true");
  } else {
    obj.iNode  = obj.node.getNode("i","true");
  }

  return obj;
}

LinearElement.linearElementUpdate = func {
  me.baseElementUpdate();
  u = me.node.getParent().getNode("u-volts").getValue();
  if( me.isConnected() ) {
    me.i = (u - me.u0) / me.ri;
  } else {
    me.i = 0;
  }
  me.riNode.setDoubleValue( me.ri );
  me.u0Node.setDoubleValue( me.u0 );
  me.iNode.setDoubleValue( me.i );
}

LinearElement.update = func {
  me.linearElementUpdate(arg[0]);
}

LinearElement.isConnected = func {
  return 1;
}

#############################################################################
# a simple load element 
#############################################################################
LoadElement = {};

LoadElement.new = func {
  node = arg[0];

  p = node.getNode("load-watts").getValue();
  u = node.getParent().getNode("volts").getValue();
  if( p != 0 ) {
    r = u * u / p;
  } else {
    r = 1e99;
  }

  obj = {};
  obj = LinearElement.new( arg[0], r );
  obj.insert( obj.parents, LoadElement );

  s = node.getNode("switch-property").getValue();
  obj.switchProperty = props.globals.getNode( s );

  return obj;
}

LoadElement.isConnected = func {
  return me.switchProperty.getValue();
}

#############################################################################
# a simple generator element 
#############################################################################
GeneratorElement = {};

GeneratorElement.new = func {
  node = arg[0];

  obj = {};
  obj = LinearElement.new( arg[0], 1, 0 );
  obj.insert( obj.parents, GeneratorElement );

  s = node.getNode("switch-property").getValue();
  obj.switchProperty = props.globals.getNode( s );

  s = node.getNode( "rpm-source" ).getValue();
  obj.rpmNode = props.globals.getNode( s );
  obj.maxVoltsNode = node.getNode( "max-volts" );
  obj.minVoltsNode = node.getNode( "min-volts" );
  obj.maxAmpsNode  = node.getNode( "max-amps" );
  obj.maxRPMNode   = node.getNode( "max-rpm" );
  obj.minRPMNode   = node.getNode( "min-rpm" );

  obj.lastupdate = 0;

  return obj;
}

GeneratorElement.generatorElementUpdate = func {
  me.linearElementUpdate();

  # if disconnected, it's just a high-ohm load
  if( !me.isConnected() ) {
    me.u0 = 0.0;
    me.ri = 1e6;
    return;
  }

  # if we where just connected, start with a low ri
  if( me.u0 == 0.0 ) {
    me.ri = 10;
  }

  rpm = me.rpmNode.getValue();
  if( rpm == nil ) {
    rpm = 0;
  }
  minRPM = me.minRPMNode.getValue();
  maxRPM = me.maxRPMNode.getValue();
  minVolts = me.minVoltsNode.getValue();
  maxVolts = me.maxVoltsNode.getValue();

  #if the output is above regulator voltage, switch generator off
  u = me.node.getParent().getNode("u-volts").getValue();

  if( rpm < minRPM ) {
    me.u0 = 0.0;
    me.ri = 10;
  } else {

    me.u0 = rpm/minRPM * minVolts;
    dri = (u-maxVolts) / me.i;
    me.ri = me.ri - dri;
    if( me.ri < 0.5 ) {
      me.ri = 0.5;
    }
  }
}

GeneratorElement.update = func {
  me.generatorElementUpdate(arg[0]);
}

GeneratorElement.isConnected = func {
  return me.switchProperty.getValue();
}

#############################################################################
# a simple battery element 
#############################################################################
BatteryElement = {};

BatteryElement.new = func {
  node = arg[0];


  u = node.getParent().getNode("volts").getValue();
  c  = node.getNode("capacity-ah").getValue();

  obj = {};
  obj = LinearElement.new( arg[0], 0.03 / c, u );
  obj.insert( obj.parents, BatteryElement );

  obj.charge_curve = [[0.0,0.0],[0.2,0.8],[0.9,1.1],[1.4,1.35]];

  obj.capacityNode = obj.node.getNode("capacity-ah","true");
  obj.capacityNormNode = obj.node.getNode("capacity-norm", "true" );
  obj.voltsNormNode = obj.node.getNode("volts-norm", "true" );

  obj.capacityNormNode.setDoubleValue( 1.0 );
  obj.voltsNormNode.setDoubleValue( 1.0 );


  obj.ri_factor = 0.03;
  obj.design_volts = u;
  obj.design_capacity = c;
  obj.lastupdate = 0;

  return obj;
}

BatteryElement.batteryElementUpdate = func {
  me.linearElementUpdate();

  # i is negative for discharging
  factor = 1.0;
  if( me.i > 0 ) {
    factor = 0.8;
  }
  usedAh = me.i * factor * arg[0] / 3600.0;

  c = me.design_capacity * me.capacityNormNode.getValue() + usedAh;

  if( c < 0 ) {
    c = 0;
  }

  capacity_norm = c / me.design_capacity;
  me.capacityNormNode.setDoubleValue( capacity_norm );

  volts_norm = me.interpolate( capacity_norm, me.charge_curve );
  me.voltsNormNode.setDoubleValue( volts_norm );
  me.u0 = me.design_volts * volts_norm;

  if( c != 0 ) {
    me.ri = me.ri_factor / c;
  } else {
    me.ri = 1e99;
  }
}

BatteryElement.update = func {
  me.batteryElementUpdate(arg[0]);
}

#############################################################################
# a Bus
#############################################################################
Bus = {};

Bus.new = func {
  obj = BaseElement.new( arg[0] );
  obj.insert( obj.parents, Bus );

  obj.idx = arg[1];

  obj.elements = [];
  
  obj.load = 0; # the total load of the bus in Siemens
  obj.u = 0;    # the computed voltage on the bus
  obj.i  = 0;   # the computed load of the bus in Ampere

  obj.loadNode = obj.node.getNode( "load-siemens", "true" );
  obj.uNode = obj.node.getNode( "u-volts", "true" );
  obj.iNode = obj.node.getNode( "i-ampere", "true" );

  elementNodes = obj.node.getChildren( "element" );
  for( i = 0; i < size(elementNodes); i = i + 1 ) {
    append( obj.elements, obj.createElement(elementNodes[i], i) );
  }
  return obj;
}

Bus.createElement= func {
  node = arg[0];
  idx = arg[1];

  type = node.getNode("type").getValue();

  if( type == "battery" ) {
    return BatteryElement.new( node );
  } 

  if( type == "generator" ) {
    return GeneratorElement.new( node );
  } 


  if( type == "load" ) {
    return LoadElement.new( node );
  } 

  print("unknown element type " ~ type );
  return nil;
}

Bus.busUpdate = func {
  me.baseElementUpdate();

  me.load = 0.0;
  itot    = 0.0;
  gitot   = 0.0;
  foreach( element; me.elements ) {
    if( element.isConnected() == 1 ) {
      # a source
      itot = itot + element.u0 / element.ri;
      gitot = gitot + 1 / element.ri;

      if( element.u0 == 0 ) {
        # passive load
        me.load = me.load + 1/element.ri;
      }
    }
  }
  me.loadNode.setDoubleValue( me.load );

  if( gitot != 0 ) { # check for empty bus
    me.u = itot / gitot;
  } else {
    me.u = 0;
  }

  me.i = me.u * me.load;

  me.uNode.setDoubleValue( me.u );
  me.iNode.setDoubleValue( me.i );

  foreach( element; me.elements ) {
    element.update(arg[0]);
  }
}

Bus.update = func {
  me.busUpdate(arg[0]);
}

#############################################################################
# the electrical system
#############################################################################
ElectricSystem = {};

ElectricSystem.new = func {
  obj = {};
  obj.parents = [ElectricSystem];

  obj.bus = [];

  obj.electricSystemNode = props.globals.getNode( arg[0] );

  busNodes = obj.electricSystemNode.getChildren( "bus" );
  for( i = 0; i < size(busNodes); i = i + 1 ) {
    append( obj.bus, Bus.new( busNodes[i], i ));
  }

  return obj;
}

ElectricSystem.update = func {
  foreach( bus; me.bus ) {
    bus.update(arg[0]);
  }
}

#############################################################################
#

electricSystem = ElectricSystem.new("/systems/electrical");
elapsedTimeNode = props.globals.getNode( "/sim/time/elapsed-sec" );
t_now = 0;
t_last = 0;
update_electrical = func {

  t_now = elapsedTimeNode.getValue();
  dt = t_now - t_last;
  t_last = t_now;
  
  electricSystem.update(dt);
  settimer( update_electrical, 0 );
}

settimer( update_electrical, 0 );

