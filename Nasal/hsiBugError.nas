#  This timed loop updates /autopilot/internal/heading-bug-error-deg
#  according to what altimatic -IIIc mode is selected.

#   set up the properties read and updated

hsi = "/instrumentation/hsi";
power = "/systems/electrical/outputs/autopilot";
autopilotControls = "/autopilot/CENTURYIII/controls";

# internal

internalHeadingBugError = "/autopilot/internal/heading-bug-error-deg";

# hsi
propHsi = props.globals.getNode(hsi, 1);

hsiCursorRotationDeg = propHsi.getNode("cursor-rotation-deg", 1);
hsiHdgBugErrorDeg    = propHsi.getNode("heading-bug-error-deg",1);

# Autopilot controls
propAutopilotControls = props.globals.getNode(autopilotControls, 1);

#rollControl = propAutopilotControls.getNode("roll", 1);
hdgControl = propAutopilotControls.getNode("hdg", 1);
modeControl = propAutopilotControls.getNode("mode", 1);


headingBugError = 0.0;

headingBugErrorUpdate = func {

  cursorRot     = hsiCursorRotationDeg.getValue();
  mode          = modeControl.getValue();
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


