sigma.publicPrototype.myCircularLayout = function() {
  var R = 100,
      i = 0,
      L = this.getNodesCount();

  this.iterNodes(function(n){
    n.x = Math.cos(Math.PI*(i++)/L)*R;
    n.y = Math.sin(Math.PI*(i++)/L)*R;
  });

  return this.position(0,0,1).draw();
};

// The following method will parse the related sigma instance nodes
// and set its position to as random in a square around the center:
sigma.publicPrototype.myRandomLayout = function() {
  var W = 100,
      H = 100;
  
  this.iterNodes(function(n){
    n.x = W*Math.random();
    n.y = H*Math.random();
  });

  return this.position(0,0,1).draw();
};