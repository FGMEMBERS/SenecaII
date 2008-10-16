# 
# This Timer is for stop-watches
#
# ./time       (double)    elapsed time since last start or reset
#
# ./running    (bool)      true if timer is running, false if stopped
# ./start-time (double)    timestamp when the timer was last started or reset

var elapsedTimeSecN = props.globals.getNode( "/sim/time/elapsed-sec" );

var timer = {
  new : func {
    var m = { parents: [timer] };
    m.base = arg[0];
    m.baseN = props.globals.getNode( m.base, 1 );

    m.timeN = m.baseN.getNode( "time", 1 );
    if( m.timeN.getValue() == nil ) {
      m.timeN.setDoubleValue( 0.0 );
    }

    m.runningN = m.baseN.getNode( "running", 1 );
    if( m.runningN.getValue() == nil ) {
      m.runningN.setBoolValue( 0 );
    }

    m.startTimeN = m.baseN.getNode( "start-time", 1 );
    if( m.startTimeN.getValue() == nil ) {
      m.startTimeN.setDoubleValue( -1.0 );
    }

    return m;
  },

  getTime : func {
    return me.timeN.getDoubleValue();
  },

  start : func { 
    me.runningN.setBoolValue( 1 );
  },

  stop : func { 
    me.runningN.setBoolValue( 0 ); 
  },

  reset : func {
    me.startTimeN.setDoubleValue( elapsedTimeSecN.getValue() );
    me.timeN.setDoubleValue( 0 );
  },

  restart : func {
    me.reset();
    me.start();
  },

  # return integer coded time as hmmss
  computeBCDTime : func {
    var t = me.timeN.getValue();
    var h = int(t / 3600);
    var t = t - (h*3600);
    var m = int(t / 60 );
    var t = t - (m*60);
    var s = int(t);
    return h * 10000 + m * 100 + s;
  },

  update : func {
    if( me.runningN.getValue() ) {
      me.timeN.setDoubleValue( elapsedTimeSecN.getValue() - me.startTimeN.getValue() );
    }
  }

};

####################################################################
# KR87

var kr87 = {
  new : func {
    var m = { parents: [kr87] };
    m.base = arg[0];
    m.baseN = props.globals.getNode( m.base, 1 );

    m.flt = timer.new( m.base ~ "/flight-timer" );
    m.flt.restart();
    m.et  = timer.new( m.base ~ "/enroute-timer" );
    m.et.restart();

    m.displayModeN = m.baseN.getNode( "display-mode",1 );
    if( m.displayModeN.getValue() == nil ) {
      m.displayModeN.setIntValue( 0 );
    }

    m.rightDisplayN = m.baseN.getNode( "right-display", 1 );
    m.standbyFrequencyN = m.baseN.getNode( "frequencies/standby-khz", 1 );

    setlistener( m.base ~ "/set-btn", func(n) { m.setButtonListener(n) } );
    setlistener( m.base ~ "/power-btn", func(n) { m.powerButtonListener(n) } );

#   will be set from audiopanel
#    m.baseN.getNode( "ident-audible" ).setBoolValue( 1 );
    m.volumeNormN = m.baseN.getNode( "volume-norm", 1 );
    if( m.volumeNormN.getValue() == nil ) {
      m.volumeNormN.setDoubleValue( 0.0 );
    }

    m.power = 0;

    m.powerButtonN = m.baseN.getNode( "power-btn", 1 );
    if( m.volumeNormN.getValue() == 0 ) {
      m.powerButtonN.setBoolValue( 0 );
    } else {
      m.powerButtonN.setBoolValue( 1 );
    }


    m.adfButtonN = m.baseN.getNode( "adf-btn" );
    if( m.adfButtonN.getValue() == nil ) {
      m.adfButtonN.setBoolValue( 0 );
    }

    m.bfoButtonN = m.baseN.getNode( "bfo-btn" );
    if( m.bfoButtonN.getValue() == nil ) {
      m.bfoButtonN.setBoolValue( 0 );
    }

    m.modeN = m.baseN.getNode( "mode" );
    setlistener( m.base ~ "/adf-btn", func { m.modeButtonListener() } );
    setlistener( m.base ~ "/bfo-btn", func { m.modeButtonListener() } );
    m.modeButtonListener();

    return m;
  },

  modeButtonListener : func {
    if( me.adfButtonN.getBoolValue() ) {
      if( me.bfoButtonN.getBoolValue() ) {
        me.modeN.setValue( "bfo" );
      } else {
        me.modeN.setValue( "adf" );
      }
    } else {
      me.modeN.setValue( "ant" );
    }
  },

  setButtonListener : func(n) {
    if( n.getBoolValue() ) {
      me.et.restart();
    }
  },

  powerButtonListener : func(n) {
    if( n.getBoolValue() and !me.power ) {
      # power on, restart timer and start with FRQ display
      me.et.restart();
      me.flt.restart();
      me.displayModeN.setIntValue( 0 );
    }
    me.power = me.powerButtonN.getValue();
  },

  update : func {
    me.flt.update();
    me.et.update(); 
    var m = me.displayModeN.getValue();

    if( m == 0 ) {
      # FRQ
      me.rightDisplayN.setIntValue( me.standbyFrequencyN.getValue() );
    } 

    # the display works up to 99h, 59m, 59s and then
    # displays 00:00 again. Don't know if this is the like the true kr87
    # handles this - never flewn that long...
    if( m == 1 ) {
      # FLT, show mm:ss up to 59:59, then hh:mm
      var t = me.flt.computeBCDTime();
      if( t >= 10000 ) {
        t = t / 100;
      }
      me.rightDisplayN.setIntValue( t );
    } 
    if( m == 2 ) {
      # ET, show mm:ss up to 59:59, then hh:mm
      t = me.et.computeBCDTime();
      if( t >= 10000 ) {
        t = t / 100;
      }
      me.rightDisplayN.setIntValue( t );
    }
  }
};

var kr87_0 = kr87.new( "/instrumentation/adf[0]" );

var timer_update = func {
  kr87_0.update();
  settimer( timer_update, 0.2 );
}

timer_update();

