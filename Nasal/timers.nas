GetPropertyPath = func {
  node = arg[0];
  if( node.getParent() != nil ) {
    return GetPropertyPath( node.getParent() ) ~ "/" ~ node.getName();
  }
  return "";
}

listenerHash = {};

propertyListener = func {
  node = cmdarg();
  timer = listenerHash[ GetPropertyPath( node ) ];
  if( timer != nil ) {
    timer.listener();
  }
}

timeNode = props.globals.getNode( "/sim/time/elapsed-sec" );

Timer = {};

Timer.new = func {
  obj = {};
  obj.parents = [Timer];
  obj.timerNode = arg[0];
  obj.name = obj.timerNode.getNode( "name" ).getValue();
  obj.enableNode = obj.getProperty( "enable-property" );
  obj.startNode  = obj.getProperty( "start-property" );
  obj.outputNode = obj.getProperty( "output-property" );
  obj.outputNode.setBoolValue( 0 );
  obj.t0Node  = obj.timerNode.getNode( "t0" );
  obj.expires = 0;

  setlistener( obj.startNode, propertyListener );

  s = GetPropertyPath( obj.startNode );
  listenerHash[s] = obj;

  return obj;
}

Timer.getProperty = func {
  prop = arg[0];
  node = me.timerNode.getNode( prop );
  if( node == nil ) {
    return nil;
  }
  return props.globals.getNode( node.getValue() );
}

Timer.listener = func {
  if( ! me.outputNode.getBoolValue() and me.startNode.getBoolValue() ) {
    me.outputNode.setBoolValue( 1 );
    me.expires = timeNode.getValue() + me.t0Node.getValue();
    settimer( expireTimers, me.t0Node.getValue() );
  }
}

Timer.expire = func {
  if( me.outputNode.getBoolValue() and me.expires <= timeNode.getValue() ) {
    me.outputNode.setBoolValue( 0 );
  }
}

timers = [];

createTimer = func {
  timer = arg[0];
  t = Timer.new( timer );
  append( timers, t );
}

expireTimers = func {
  foreach( timer; timers ) {
    timer.expire();
  }
}

# read the property-tree
timersNode = props.globals.getNode( "/sim/timers");
timerNodes = timersNode.getChildren( "timer" );
foreach( timer; timerNodes ) {
  createTimer( timer );
}
