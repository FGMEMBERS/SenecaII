(function($) {
  
  function makeTranslate(a) {
    return makeTransform("translate", a);
  }

  function makeRotate(a) {
    return makeTransform("rotate", a);
  }
  
  function makeTransform( type, a ) {
    var t = type.concat("(");
    if( a != null ) {
      a.forEach( function(ele) {
        t = t.concat(ele).concat(" ");
      });
    }
    return t.concat(") ");
  }

  function evaluate( context,exp ) {
    if( typeof(exp) == 'function' )
      return exp.call(context);
    return exp;
  }

  $.fn.fgAnimateSVG = function(props) {
    if (props) {
      if (props.type == "transform" && props.transforms) {
        var a = "";
        props.transforms.forEach(function(transform) {
          switch (transform.type) {
            case "rotate":
              a = a.concat(makeRotate([ 
                evaluate(transform.props.context,transform.props.a), 
                evaluate(transform.props.context,transform.props.x), 
                evaluate(transform.props.context,transform.props.y) ]));
              break;
            case "translate":
              a = a.concat(makeTranslate([ 
                evaluate(transform.props.context,transform.props.x), 
                evaluate(transform.props.context,transform.props.y) ]));
              break;
          }
        });
        this.attr("transform", a);
      
      } else if( props.type == "text" ) {
        var tspans = this.children("tspan");
        if( 0 == tspans.length ) {
          this.text(props.text);
        } else {
          tspans.text(props.text);
        }
      }
    }
    return this;
  };

}(jQuery));
