# ===========================
# Immatriculation by Zakharov
# Tuned by Torsten Dreyer
# ===========================

var registrationDialog = gui.Dialog.new("/sim/gui/dialogs/SenecaII/status/dialog",
				  "Aircraft/SenecaII/Dialogs/registration.xml");

var l = setlistener("/sim/signals/fdm-initialized", func {
  var callsign = props.globals.getNode("/sim/multiplay/callsign",1).getValue();
  if( callsign == nil or callsign == "callsign" )
    callsign = "D-GEAR";
  props.globals.initNode( "/sim/multiplay/generic/string[0]", callsign, "STRING" );
  removelistener(l);
});
