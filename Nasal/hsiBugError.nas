#  This timed loop updates /autopilot/internal/heading-bug-error-deg
#  according to what altimatic -IIIc mode is selected.

#   set up the properties read and updated

var power = "/systems/electrical/outputs/autopilot";

# internal

var internalHeadingBugErrorN = props.globals.initNode( "/autopilot/internal/heading-bug-error-deg", 0.0 );
var hsiHdgBugErrorDegN   = props.globals.initNode("/autopilot/internal/hsi-heading-bug-error-deg", 0.0 );
var headingN = props.globals.initNode("/instrumentation/heading-indicator/indicated-heading-deg", 0.0); 
var selectedRadialN = props.globals.initNode("/instrumentation/nav[0]/radials/selected-deg", 0.0 );

# Autopilot controls
var propAutopilotControlsN = props.globals.getNode("/autopilot/CENTURYIII/controls", 1);

#rollControl = propAutopilotControlsN.getNode("roll", 1);
var hdgControl = propAutopilotControlsN.getNode("hdg", 1);
var modeControl = propAutopilotControlsN.getNode("mode", 1);



var headingBugErrorUpdate = func {

  var headingBugError = 0.0;

  var mode = modeControl.getValue();
  if ( hdgControl.getValue() ) {
     if ( mode == 2 ) {
        # HDG mode
        headingBugError = internalHeadingBugErrorN.getValue();
     } elsif ( mode == 4 ) {
        # LOC REV mode
        headingBugError = selectedRadialN.getValue() - headingN.getValue() + 180;
     } else {
        # NAV or OMNI or LOC NORM modes
        headingBugError = selectedRadialN.getValue() - headingN.getValue();
     }
     while( headingBugError > 180 )
       headingBugError = headingBugError - 360;

     hsiHdgBugErrorDegN.setDoubleValue(headingBugError);
   }
   settimer(headingBugErrorUpdate, 0.5);
}

var L = setlistener(power, func {
   headingBugErrorUpdate();
   removelistener(L);
});   


