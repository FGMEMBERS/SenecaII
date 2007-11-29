##################################################
# Nose Landding Gear
##################################################
# input properties:
# /gear/gear[0]/compression-norm
# output properties:
# /controls/gear/NLG_C_deg
# /controls/gear/NLG_D_deg
##################################################

var compression_norm = '/gear/gear[0]/compression-norm';

var a = 0.152346;
var b = 0.152297;
var d_zero = 0.2186;
var distanza = 0.1653;

# Converte radianti in gradi.
var rad_to_deg = func () {
  var deg = arg[0]*180/math.pi;
  return deg;
}


# Calcola il valore in radianti dell'angolo alfa conoscendo i lati a,b,d.
var alfa_radiants = func () {
   var a = arg[0];
   var b = arg[1];
   var d = arg[2];
   return (math.atan2((math.sqrt((4*a*a*d*d)-(a*a-b*b+d*d)*(a*a-b*b+d*d))) , (a*a-b*b+d*d)));
}

# Calcola il valore in radianti dell'angolo teta conoscendo i lati a,b,d.
var teta_radiants = func () {
   var a = arg[0];
   var b = arg[1];
   var d = arg[2];
   return (math.atan2((math.sqrt(4*a*a*d*d-(a*a-b*b+d*d)*(a*a-b*b+d*d))) , math.sqrt(4*b*b*d*d-4*a*a*d*d + (a*a-b*b+d*d)*(a*a-b*b+d*d))));
}

var alfa_zero_rad = alfa_radiants(a, b, d_zero);
var alfa_zero_deg = rad_to_deg(alfa_zero_rad);

var teta_zero_rad = teta_radiants(a, b, d_zero);
var teta_zero_deg = rad_to_deg (teta_zero_rad);

# calcola ed applica l'angolo di rotazione di NLG_D in funzione di compression-norm.
var braccio_D_angle_change = func () {
  var Xpos = getprop(compression_norm) * distanza;
  var d = d_zero - Xpos;
  var alfa_rad = alfa_radiants(a, b, d);
  var alfa_deg = rad_to_deg (alfa_rad);
  var delta_alfa_deg = alfa_deg - alfa_zero_deg;
  setprop("/controls/gear/NLG_D_deg", delta_alfa_deg);
}

var braccio_C_angle_change = func () {
  var Xpos = getprop(compression_norm) * distanza;
  var d = d_zero - Xpos; 
  var teta_rad = teta_radiants(a, b, d);
  var teta_deg = rad_to_deg (teta_rad);
  var delta_teta_deg = teta_deg - teta_zero_deg;
  setprop("/controls/gear/NLG_C_deg", delta_teta_deg);
}


var gear_init = func {
var i = setlistener("/gear/gear[0]/compression-norm", braccio_D_angle_change);
var k = setlistener("/gear/gear[0]/compression-norm", braccio_C_angle_change);
}

setlistener("/sim/signals/fdm-initialized", gear_init );
