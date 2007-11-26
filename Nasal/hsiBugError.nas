#  This timed loop updates /autopilot/internal/heading-bug-error-deg
#  according to what altimatic -IIIc mode is selected.

#   set up the properties read and updated

var hsi = "/instrumentation/hsi";
var power = "/systems/electrical/outputs/autopilot";
var autopilotControls = "/autopilot/CENTURYIII/controls";

# internal

var internalHeadingBugError = "/autopilot/internal/heading-bug-error-deg";

# hsi
var propHsi = props.globals.getNode(hsi, 1);

var hsiCursorRotationDeg = propHsi.getNode("cursor-rotation-deg", 1);
var hsiHdgBugErrorDeg    = propHsi.getNode("heading-bug-error-deg",1);

# Autopilot controls
var propAutopilotControls = props.globals.getNode(autopilotControls, 1);

#rollControl = propAutopilotControls.getNode("roll", 1);
var hdgControl = propAutopilotControls.getNode("hdg", 1);
var modeControl = propAutopilotControls.getNode("mode", 1);


var headingBugError = 0.0;

var headingBugErrorUpdate = func {

  var cursorRot     = hsiCursorRotationDeg.getValue();
  var mode          = modeControl.getValue();
  if ( hdgControl.getValue() ) {
     if ( mode == 2 ) {
        # HDG mode
        headingBugError = getprop(internalHeadingBugError);
     } elsif ( mode == 4 ) {
        # LOC REV mode
        headingBugError = 180 - cursorRot;
     } else {
        # NAV or OMNI or LOC NORM modes
        if (cursorRot < 180 ) {
           headingBugError = -cursorRot;
        } else {
           headingBugError = 360 - cursorRot;
        }
     }
     hsiHdgBugErrorDeg.setDoubleValue(headingBugError);
   }
   settimer(headingBugErrorUpdate, 0.5);
}

var L = setlistener(power, func {
   headingBugErrorUpdate();
   removelistener(L);
});   


