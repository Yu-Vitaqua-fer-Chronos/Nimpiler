type MyObj = object
  x: int

proc `+`(o: MyObj, ob: MyObj): MyObj =
  return MyObj(x: ob.x+o.x)

var
  a:MyObj = MyObj(x:1)
  b:MyObj = MyObj(x:1)

echo a + b