module taskpool {

use blockindices;

class taskpool {
  const poolSize;
  var taskarr : [0..poolSize-1] sync blockIndices; 
  var head, tail : sync int = 0;
  def add(blk: blockIndices) {
    const pos = tail;
    tail = (pos+1)%poolSize;
    taskarr(pos) = blk;
  }
  def remove() {
    const pos = head;
    head = (pos+1)%poolSize;
    return taskarr(pos);
  }
}
}
