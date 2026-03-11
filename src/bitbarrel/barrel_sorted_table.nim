import std/[tables, strutils]
import harding/core/types
import harding/interpreter/objects
import bitbarrel_client

proc getSortedTableClient(self: Instance): ptr BitBarrelClient =
  if self == nil:
    return nil

  if self.nimValue != nil:
    return cast[ptr BitBarrelClient](self.nimValue)

  let barrelSlot = self.class.getSlotIndex("barrel")
  if barrelSlot < 0:
    return nil

  let barrelValue = getSlot(self, barrelSlot)
  if barrelValue.kind != vkInstance or barrelValue.instVal == nil or barrelValue.instVal.nimValue == nil:
    return nil

  self.nimValue = barrelValue.instVal.nimValue
  cast[ptr BitBarrelClient](self.nimValue)

proc toHardingTable(interp: var Interpreter, pairs: seq[(string, string)]): NodeValue =
  let tableClass = tableClassCache
  if tableClass == nil:
    return nilValue()
  let result = newInstance(tableClass)
  for (key, value) in pairs:
    result.entries[key.toValue()] = value.toValue()
  result.toValue()

proc barrelSortedTableAtImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 1:
    return nilValue()

  let client = self.getSortedTableClient()
  if client == nil:
    return nilValue()

  try:
    client[].get(args[0].toString()).toValue()
  except ClientError:
    nilValue()

proc barrelSortedTableAtPutImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 2:
    return self.toValue()

  let client = self.getSortedTableClient()
  if client == nil:
    return self.toValue()

  try:
    discard client[].set(args[0].toString(), args[1].toString())
  except ClientError:
    discard

  self.toValue()

proc barrelSortedTableKeysImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  let client = self.getSortedTableClient()
  if client == nil:
    return nilValue()

  try:
    let (keys, _, _) = client[].rangeQueryKeys(limit = 1000)
    let arrayClass = arrayClassCache
    if arrayClass == nil:
      return nilValue()
    let result = newInstance(arrayClass)
    for key in keys:
      result.elements.add(key.toValue())
    return result.toValue()
  except ClientError:
    nilValue()

proc barrelSortedTableSizeImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  let client = self.getSortedTableClient()
  if client == nil:
    return 0.toValue()

  try:
    client[].count().toValue()
  except ClientError:
    0.toValue()

proc barrelSortedTableRangeQueryImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len < 2:
    return nilValue()

  let client = self.getSortedTableClient()
  if client == nil:
    return nilValue()

  let limit = if args.len >= 3: parseInt(args[2].toString()) else: 1000

  try:
    let (pairs, _, _) = client[].rangeQuery(args[0].toString(), args[1].toString(), limit)
    toHardingTable(interp, pairs)
  except ClientError:
    nilValue()

proc barrelSortedTablePrefixQueryImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len < 1:
    return nilValue()

  let client = self.getSortedTableClient()
  if client == nil:
    return nilValue()

  let limit = if args.len >= 2: parseInt(args[1].toString()) else: 1000

  try:
    let (pairs, _, _) = client[].prefixQuery(args[0].toString(), limit)
    toHardingTable(interp, pairs)
  except ClientError:
    nilValue()

proc registerBarrelSortedTablePrimitives*(interp: var Interpreter) =
  if not interp.globals[].hasKey("BarrelSortedTable"):
    warn("BarrelSortedTable class not found")
    return

  let sortedValue = interp.globals[]["BarrelSortedTable"]
  if sortedValue.kind != vkClass:
    warn("BarrelSortedTable class is not a class value")
    return

  let sortedClass = sortedValue.classVal
  sortedClass.isNimProxy = true
  sortedClass.hardingType = "BarrelSortedTable"

  let atMethod = createCoreMethod("at:")
  atMethod.nativeImpl = cast[pointer](barrelSortedTableAtImpl)
  atMethod.hasInterpreterParam = true
  addMethodToClass(sortedClass, "at:", atMethod)

  let atPutMethod = createCoreMethod("at:put:")
  atPutMethod.nativeImpl = cast[pointer](barrelSortedTableAtPutImpl)
  atPutMethod.hasInterpreterParam = true
  addMethodToClass(sortedClass, "at:put:", atPutMethod)

  let keysMethod = createCoreMethod("keys")
  keysMethod.nativeImpl = cast[pointer](barrelSortedTableKeysImpl)
  keysMethod.hasInterpreterParam = true
  addMethodToClass(sortedClass, "keys", keysMethod)

  let sizeMethod = createCoreMethod("size")
  sizeMethod.nativeImpl = cast[pointer](barrelSortedTableSizeImpl)
  sizeMethod.hasInterpreterParam = true
  addMethodToClass(sortedClass, "size", sizeMethod)

  let rangeMethod = createCoreMethod("rangeFrom:to:limit:")
  rangeMethod.nativeImpl = cast[pointer](barrelSortedTableRangeQueryImpl)
  rangeMethod.hasInterpreterParam = true
  addMethodToClass(sortedClass, "rangeFrom:to:limit:", rangeMethod)

  let prefixMethod = createCoreMethod("prefix:limit:")
  prefixMethod.nativeImpl = cast[pointer](barrelSortedTablePrefixQueryImpl)
  prefixMethod.hasInterpreterParam = true
  addMethodToClass(sortedClass, "prefix:limit:", prefixMethod)
