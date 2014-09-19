var FGFS = {};

FGFS.Property = function(path) {
  if (path == null)
    throw new Error('path is null');
  // path must be absolute
  if (path.lastIndexOf("/", 0) !== 0)
    path = "/".concat(path);

  this.path = path.lastIndexOf("/", 0) === 0 ? path : "/".concat(path);
  this.value = null;
}

FGFS.Property.prototype.getPath = function() {
  return this.path;
}

FGFS.Property.prototype.setValue = function(val) {
  // TODO: send this out
  this.value = val;
}

FGFS.Property.prototype.hasValue = function() {
  return this.value != null;
}

FGFS.Property.prototype.getValue = function(val) {
  return this.value;
}

FGFS.Property.prototype.getStringValue = function(val) {
  return this.value == null ? null : this.value.toString();
}

FGFS.Property.prototype.getNumValue = function(val) {
  var reply = this.value == null ? null : Number(this.value);
  return (isNaN(reply) || reply == null) ? 0 : reply;
}

FGFS.PropertyListener = function(arg) {
  this._listeners = {};
  this._nextId = 1;
  this._ws = new WebSocket('ws://' + location.host + '/PropertyListener');

  function defaultOnClose(ev) {

    var msg = 'Lost connection to FlightGear. Please reload this page and/or restart FlightGear.';
    alert(msg);
    throw new Error(msg);
  }

  function defaultOnError(ev) {
    var msg = 'Error communicating with FlightGear. Please reload this page and/or restart FlightGear.';
    alert(msg);
    throw new Error(msg);
  }

  this._ws.propertyListener = this;
  this._ws.onopen = arg.onopen;
  this._ws.onclose = defaultOnClose;
  this._ws.onerror = defaultOnError;
  this._ws.onmessage = function(ev) {
    try {
      this.propertyListener.fire(JSON.parse(ev.data));
    } catch (e) {
    }
  };

  this.fire = function(node) {
    this._listeners[node.path].forEach(function(callback) {
      callback.cb(node);
    });
  };

  this.addProperty = function(prop, callback) {
    var path = prop.getPath();

    var o = this._listeners[path];
    var newProperty = false;
    if (typeof (o) == 'undefined') {
      newProperty = true;
      o = [];
      this._listeners[path] = o;
    }

    o.push({
      cb : callback,
      "prop" : prop,
      id : this._nextId++
    });

    if (newProperty) {
      this._ws.send(JSON.stringify({
        command : 'addListener',
        node : path
      }));
      this._ws.send(JSON.stringify({
        command : 'get',
        node : path
      }));
    }
    return this._nextId;
  };

  this.removeProperty = function(prop) {
    throw new Error('removeProperty not yet implemented');
  };

}

FGFS.PropertyMirror = function(mirroredProperties) {
  var listener = new FGFS.PropertyListener({
    onopen : function() {
      var keys = Object.keys(mirroredProperties);
      for (var i = 0; i < keys.length; i++) {
        listener.addProperty(mirroredProperties[keys[i]], function(n) {
          if (typeof (n.value) != 'undefined')
            this.prop.value = n.value;
        });
      }
      ;
    },
  });

  this.listener = listener;
}

FGFS.interpolate = function(x, pairs) {
  var n = pairs.length - 1;
  if (x <= pairs[0][0]) {
    return pairs[0][1];
  }
  if (x >= pairs[n][0]) {
    return pairs[n][1];
  }
  for (var i = 0; i < n; i = i + 1) {
    if (x > pairs[i][0] && x <= pairs[i + 1][0]) {
      var x1 = pairs[i][0];
      var x2 = pairs[i + 1][0];
      var y1 = pairs[i][1];
      var y2 = pairs[i + 1][1];
      return (x - x1) / (x2 - x1) * (y2 - y1) + y1;
    }
  }
  return pairs[i][1];
}

FGFS.InputValue = function(arg) {
  this.value = 0;
  this.property = null;
  this.offset = 0;
  this.scale = 1;
  this.interpolationTable = null;
  this.min = null;
  this.max = null;

  this.getValue = function() {
    var value = this.value;
    if (this.property != null)
      value = this.property.getNumValue();

    if (this.interpolationTable != null && this.interpolationTable.length > 0)
      return FGFS.interpolate(value, this.interpolationTable);

    value = value * this.scale + this.offset;
    if( this.min != null && value < this.min )
      return this.min;
    if( this.max != null && value > this.min )
      return this.max;
    return value;
  }

  if (typeof (arg) == 'number') {
    this.value = Number(arg);
  } else if (typeof (arg) == 'string') {
    this.property = fgGetNode(arg);
  } else if (typeof (arg) == 'object') {

    if (typeof (arg.property) != 'undefined')
      this.property = fgGetNode(arg.property);

    if (typeof (arg.value) != 'undefined')
      this.value = Number(arg.value);

    if (typeof (arg.scale) != 'undefined')
      this.scale = Number(arg.scale);

    if (typeof (arg.offset) != 'undefined')
      this.offset = Number(arg.offset);

    if (typeof (arg.interpolation == 'string')) {

      var target = this;
      if (typeof (arg.interpolation) == 'string') {
        this.interpolationTable = [];
        // load interpolation table
        $.ajax({
          type : "GET",
          dataType : "XML",
          url : arg.interpolation,
          success : function(data, status, xhr) {
            var entries = $(data).find("entry");
            $(data).find("entry").each(function() {
              var ind = $(this).find("ind").text();
              var dep = $(this).find("dep").text();
              target.interpolationTable.push([ Number(ind), Number(dep) ]);
            });
          },
          error : function(xhr, status, msg) {
            alert(status + " while reading '" + arg.interpolation + "': " + msg.toString());
          },
        });
      }
    }
  } else {
    throw new Error('Dont know how to handle "' + arg.toString() + '"' );
  }

}

FGFS.Transform = function(arg) {
}

FGFS.RotateTransform = function(arg) {
  this.__proto__ = new FGFS.Transform(arg);

  this.a = new FGFS.InputValue(arg.a);
  this.x = new FGFS.InputValue(arg.x);
  this.y = new FGFS.InputValue(arg.y);

  this.makeTransform = function() {
    return {
      type : "rotate",
      props : {
        a : this.a.getValue(),
        x : this.x.getValue(),
        y : this.y.getValue(),
        context : this,
      }
    }
  }
}

FGFS.TranslateTransform = function(arg) {
  this.__proto__ = new FGFS.Transform(arg);
  
  this.x = new FGFS.InputValue(arg.x);
  this.y = new FGFS.InputValue(arg.y);

  this.makeTransform = function() {
    return {
      type : "translate",
      props : {
        x : this.x.getValue(),
        y : this.y.getValue(),
        context : this,
      }
    }
  }
}

FGFS.Animation = function(arg) {
  this.element = arg.element;
  this.type = arg.type;

  this.__proto__.update = function(svg) {
    var t = typeof (this._element);
    if (typeof (this._element) == 'undefined') {
      this._element = $(svg).find(this.element);
    }

    this._element.fgAnimateSVG(this.makeAnimation());
  }

  this.__proto__.makeAnimation = function() {
    return {};
  }
}

FGFS.TransformAnimation = function(arg) {
  this.__proto__ = new FGFS.Animation(arg);

  this.transforms = [];
  for (var i = 0; i < arg.transforms.length; i++) {
    var t = arg.transforms[i];
    var transform = null;
    switch (t.type) {
      case 'rotate':
        transform = new FGFS.RotateTransform(t);
        break;
      case 'translate':
        transform = new FGFS.TranslateTransform(t);
        break;
    }
    if (transform != null)
      this.transforms[this.transforms.length] = transform;
  }

  this.makeAnimation = function() {
    var reply = {
      type : 'transform',
      transforms : [],
    };

    for (var i = 0; i < this.transforms.length; i++)
      reply.transforms[reply.transforms.length] = this.transforms[i].makeTransform();

    return reply;
  }
}

FGFS.Instrument = function(arg) {

  // load svg into target
  $.ajax({
    type : "GET",
    url : arg.src,
    async: false,
    dataType : "xml",
    context: this,
    success : function(xml, status, xhr) {
      this.svg = $(xml).find("svg")[0];
    },
    error : function(xhr, status, msg) {
      alert(status + " while reading '" + arg.src + "': " + msg.toString());
    },
  });

  this.animations = [];
  for (var i = 0; i < arg.animations.length; i++) {
    var a = arg.animations[i];
    var animation = null;

    switch (a.type) {
      case 'transform':
        animation = new FGFS.TransformAnimation(a);
        break;

    }
    if (animation != null)
      this.animations[this.animations.length] = animation;
  }

  this.__proto__.update = function() {
    // noop if svg is not (yet) loaded

    if (typeof (this.svg) == 'undefined')
      return;

    var svg = this.svg;

    this.animations.forEach(function(animation) {
      animation.update(svg);
    });
  }
}

