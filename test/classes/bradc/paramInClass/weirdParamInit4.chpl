class C {
  param x: int;
}

class D {
  var c: C;
  param y: int = c.x;
}

var c = C(2);

var d = D(c);

writeln("c is: ", c);
writeln("d is: ", d);
