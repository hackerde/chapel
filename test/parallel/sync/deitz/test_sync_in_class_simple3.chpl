class C {
  var s: sync int;
}

begin {
  var c = C();

  c.s = 2;

  var r: int = c.s;

  writeln(r);

  c.s = 3;

  r = c.s;

  writeln(r);
}
