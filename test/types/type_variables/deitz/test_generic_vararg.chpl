class C {
  param k: int;
  var x: k*int;
}

proc foo(y: C, x: C ...y.k) {
  writeln(x);
}

foo(new borrowed C(2), new borrowed C(1), new borrowed C(3));
