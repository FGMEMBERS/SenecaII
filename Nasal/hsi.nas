
var aphb = props.globals.getNode( "/autopilot/settings/heading-bug-deg" );
var v = aphb.getValue();
if( v == nil ) {
  aphb.setDoubleValue( 0.0 );
}
var rad = props.globals.getNode( "/instrumentation/nav[0]/radials/selected-deg" );
var v = rad.getValue();
if( v == nil ) {
  rad.setDoubleValue( 0.0 );
}

var hsihb = props.globals.getNode( "/instrumentation/hsi/heading-bug-rotation-deg", "true" );
var hsics = props.globals.getNode( "/instrumentation/hsi/cursor-rotation-deg", "true" );

setlistener( "/instrumentation/heading-indicator/indicated-heading-deg", func {
  h = cmdarg().getValue();

  var v = h - aphb.getValue();
  if( v < 0.0 ) {
    v = v + 360.0;
  }
  hsihb.setDoubleValue( v );

  v = h - rad.getValue();
  if( v < 0.0 ) {
    v = v + 360.0;
  }
  hsics.setDoubleValue( v );
});
