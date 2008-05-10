##################################################
# Nose Landding Gear
##################################################
# input properties:
# /gear/gear[0]/compression-norm
# output properties:
# /controls/gear/NLG_C_deg
# /controls/gear/NLG_D_deg
##################################################

var a = 0.152346;
var b = 0.152297;
var d_zero = 0.2186;
var distanza = 0.1653;
var rad_to_deg = 180.0 / math.pi;

var compressionNormNode = props.globals.getNode( "gear/gear[0]/compression-norm", 1 );
if( compressionNormNode.getValue() == nil ) {
  compressionNormNode.setDoubleValue( 0.0 );
}
var DNode = props.globals.getNode( "controls/gear/NLG_D_deg", 1 );
var CNode = props.globals.getNode( "controls/gear/NLG_C_deg", 1 );

# Calcola il valore in radianti dell'angolo alfa conoscendo i lati a,b,d.
var alfa_radiants = func( a, b, d ) {
   var x = (4*a*a*d*d)-(a*a-b*b+d*d)*(a*a-b*b+d*d);
   return math.atan2( math.sqrt(x>0?x:0), a*a-b*b+d*d );
}

# Calcola il valore in radianti dell'angolo teta conoscendo i lati a,b,d.
var teta_radiants = func( a, b, d ) {
   var x = 4*a*a*d*d-(a*a-b*b+d*d)*(a*a-b*b+d*d);
   var y = 4*b*b*d*d-4*a*a*d*d + (a*a-b*b+d*d)*(a*a-b*b+d*d);
   return math.atan2(math.sqrt(x>0?x:0) , math.sqrt(y>0?y:0) );
}

var alfa_zero_deg = alfa_radiants(a, b, d_zero) * rad_to_deg;
var teta_zero_deg = teta_radiants(a, b, d_zero) * rad_to_deg;

var gear_init = func {
  setlistener( compressionNormNode, func {
    var d = d_zero - compressionNormNode.getValue() * distanza;

    DNode.setDoubleValue( alfa_radiants(a, b, d) * rad_to_deg - alfa_zero_deg );
    CNode.setDoubleValue( teta_radiants(a, b, d) * rad_to_deg - teta_zero_deg );
  }, 1, 0 );
}

setlistener("/sim/signals/fdm-initialized", gear_init );
