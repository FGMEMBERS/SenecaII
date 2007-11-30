GetPropertyPath = func(node) {
  if( node.getParent() != nil ) {
    return GetPropertyPath( node.getParent() ) ~ "/" ~ node.getName();
  }
  return "";
}

var listenerHash = {};

propertyListener = func(node) {
  var timer = listenerHash[ GetPropertyPath( node ) ];
  if( timer != nil ) {
    timer.listener();
  }
}

var timeNode = props.globals.getNode( "/sim/time/elapsed-sec" );

var Timer = {};

Timer.new = func {
  var obj = {};
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

  var s = GetPropertyPath( obj.startNode );
  listenerHash[s] = obj;

  return obj;
}

Timer.getProperty = func(prop) {
  var node = me.timerNode.getNode( prop );
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

var timers = [];

createTimer = func(timer) {
  var t = Timer.new( timer );
  append( timers, t );
}

var expireTimers = func {
  foreach( var timer; timers ) {
    timer.expire();
  }
}

# read the property-tree
var timersNode = props.globals.getNode( "/sim/timers");
var timerNodes = timersNode.getChildren( "timer" );
foreach( var timer; timerNodes ) {
  createTimer( timer );
}
