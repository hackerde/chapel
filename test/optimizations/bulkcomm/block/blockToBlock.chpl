use util;
use BlockDist;

config const n = 60;

config const debug = false;

proc printDebug(msg: string...) {
  if debug then writeln((...msg));
}

proc buildDenseStride(MakeDense : domain, MakeStride : domain, stride : int) {
  const retStride = MakeStride by stride;
  var rngs = MakeDense.dims();
  for i in 1..MakeDense.rank {
    rngs(i) = rngs(i) # retStride.dim(i).size;
  }
  const retDense = {(...rngs)};
  return (retDense, retStride);
}

proc testCore(DestDom : domain, DestLocales : [],
              SrcDom  : domain, SrcLocales  : []) {
  const AD = DestDom dmapped Block(DestDom, DestLocales);
  const BD = SrcDom dmapped Block(SrcDom, SrcLocales);

  var A : [AD] int;
  var B : [BD] int;

  printDebug("      Simple Whole-Array Assignment");
  stridedAssign(A, B);

  // Simple strided --> strided assignment
  printDebug("      Simple Strided Assignment");
  stridedAssign(A, DestDom by 2, B, SrcDom by 2);

  // Test assignment when at least one side is strided. Both sides might be
  // strided if the domain sliced by the dense domain is already strided.
  //
  // Also tests the interesting case of slicing by a strided domain where the
  // strides do not match. E.g., (1..100 by 3)[1.. by 2]
  {
    printDebug("      Strided Slice <-- Dense Slice");
    var (DestStride, SrcDense) = buildDenseStride(DestDom, SrcDom, 2);
    stridedAssign(A, DestStride, B, SrcDense);
  }
  {
    printDebug("      Dense Slice <-- Strided Slice");
    var (SrcStride, DestDense) = buildDenseStride(SrcDom, DestDom, 2);
    stridedAssign(A, DestDense, B, SrcStride);
  }

  printDebug("      Single-Element Slice");
  stridedAssign(A, DestDom by DestDom.shape, B, SrcDom by SrcDom.shape);

  // Test assignment between middle of domains
  // Use '-4' to chop off a quarter off each end of a dimension. Multiply by
  // the stride so that the correct amount is removed from each side.
  {
    printDebug("      Half-Domain Assignment");
    var HalfDest = DestDom.expand((DestDom.shape / -4) * DestDom.stride);
    var HalfSrc  = SrcDom.expand((SrcDom.shape / -4) * SrcDom.stride);
    stridedAssign(A, HalfDest, B, HalfSrc);
  }
}

proc testDim(param rank : int, DestLocales : [], SrcLocales : []) {
  printDebug("  ----- rank=", rank:string, " -----");
  var denseRanges : rank*range;
  for i in 1..rank do denseRanges(i) = 1..n;

  var stridedRanges : rank*range(stridable=true);
  for i in 1..rank do stridedRanges(i) = 1.. by (i + 1) # n;

  const Dense = {(...denseRanges)};
  const Strided = {(...stridedRanges)};

  printDebug("    ##### Dense <-- Dense #####");
  testCore(Dense, DestLocales, Dense, SrcLocales);

  printDebug("    ##### Dense <-- Strided #####");
  testCore(Dense, DestLocales, Strided, SrcLocales);
  printDebug("    ##### Strided <-- Dense #####");
  testCore(Strided, DestLocales, Dense, SrcLocales);
}

proc testLocales(DestLocales: [], SrcLocales: []) {
  testDim(1, DestLocales, SrcLocales);
  testDim(2, DestLocales, SrcLocales);
  testDim(3, DestLocales, SrcLocales);
}

proc main() {
  util.errorIfMismatch = true;
  util.debugDefault = debug;

  const half = max(1, if numLocales/2 % 2 == 0 then numLocales/2
               else numLocales/2 - 1);
  const HalfLocales = [i in 0..#half] Locales[i*2];

  printDebug("===== All Locales =====");
  testLocales(Locales, Locales);
  printDebug("===== All <-- Half =====");
  testLocales(Locales, HalfLocales);
  printDebug("===== Half <-- All =====");
  testLocales(HalfLocales, Locales);
}
