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

sigma.publicPrototype.starWeightedLayout = function() {
  this.dropNode('padding-top');
  this.dropNode('padding-bottom');

  var nodes = [];

  this.iterNodes(function(n) {
    nodes.push({
      size: n.size,
      id: n.id
    });
  });

  nodes.sort(function(a, b) {
    return a.size > b.size ? -1 : 1;
  });

  var rotateAngle = 10;
  var rotatePoint = function(x, y) {
    var rad = rotateAngle * Math.PI / 180;

    newX = x * Math.cos(rad) - y * Math.sin(rad);
    newY = y * Math.cos(rad) + x * Math.sin(rad);

    return [newX, newY]
  };

  var positions = [];

  var gridSize = Math.ceil(Math.sqrt(nodes.length));
  (function() {

    var x = 0, y = 0, dx = 0, dy = -1;
    var X = gridSize, Y = gridSize;
    var t = Math.max(X, Y);
    var maxI = t * t;
    var sizeMod = 0;
    var corners = -2;

    for (i = 0; i < maxI; i++) {
        if ((-X/2 <= x) && (x <= X/2) && (-Y/2 <= y) && (y <= Y/2)) {
            positions.push(rotatePoint(x + gridSize/2, y + gridSize/2));
        }

        if( (x == y) || ((x < 0) && (x == -y)) || ((x > 0) && (x == 1-y))) {
            t = dx;
            dx =- dy;
            dy = t;
        }
        x += dx;
        y += dy;
    }
  })();

  this.iterNodes(function(n) {
    for (i = 0; i < nodes.length; i++) {
      if (n.id == nodes[i].id) {
        n.x = positions[i][0];
        n.y = positions[i][1];
        break;
      }
    }
  });
  this.addNode('padding-top', {
    x: rotatePoint(0.4, 0.4)[0],
    y: rotatePoint(0.4, 0.4)[1],
    size: 0
  });
  this.addNode('padding-bottom', {
    x: rotatePoint(gridSize-0.4, gridSize-0.4)[0],
    y: rotatePoint(gridSize-0.4, gridSize-0.4)[1],
    size: 0
  });

  return this.position(0,0,1).draw();
};