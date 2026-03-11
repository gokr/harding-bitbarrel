import std/tables
import harding/core/types
import harding/interpreter/objects
import bitbarrel_client

proc getTableClient(self: Instance): ptr BitBarrelClient =
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

proc barrelTableAtImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 1:
    return nilValue()

  let client = self.getTableClient()
  if client == nil:
    return nilValue()

  try:
    client[].get(args[0].toString()).toValue()
  except ClientError:
    nilValue()

proc barrelTableAtPutImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 2:
    return self.toValue()

  let client = self.getTableClient()
  if client == nil:
    return self.toValue()

  try:
    discard client[].set(args[0].toString(), args[1].toString())
  except ClientError:
    discard

  self.toValue()

proc barrelTableIncludesKeyImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 1:
    return falseValue

  let client = self.getTableClient()
  if client == nil:
    return falseValue

  try:
    return if client[].exists(args[0].toString()): trueValue else: falseValue
  except ClientError:
    falseValue

proc barrelTableRemoveKeyImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 1:
    return nilValue()

  let client = self.getTableClient()
  if client == nil:
    return nilValue()

  try:
    discard client[].delete(args[0].toString())
  except ClientError:
    discard

  nilValue()

proc barrelTableKeysImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  let client = self.getTableClient()
  if client == nil:
    return nilValue()

  try:
    let keys = client[].listKeys()
    let arrayClass = arrayClassCache
    if arrayClass == nil:
      return nilValue()
    let result = newInstance(arrayClass)
    for key in keys:
      result.elements.add(key.toValue())
    return result.toValue()
  except ClientError:
    nilValue()

proc barrelTableSizeImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  let client = self.getTableClient()
  if client == nil:
    return 0.toValue()

  try:
    client[].count().toValue()
  except ClientError:
    0.toValue()

proc registerBarrelTablePrimitives*(interp: var Interpreter) =
  if not interp.globals[].hasKey("BarrelTable"):
    warn("BarrelTable class not found")
    return

  let tableValue = interp.globals[]["BarrelTable"]
  if tableValue.kind != vkClass:
    warn("BarrelTable class is not a class value")
    return

  let tableClass = tableValue.classVal
  tableClass.isNimProxy = true
  tableClass.hardingType = "BarrelTable"

  let atMethod = createCoreMethod("at:")
  atMethod.nativeImpl = cast[pointer](barrelTableAtImpl)
  atMethod.hasInterpreterParam = true
  addMethodToClass(tableClass, "at:", atMethod)

  let atPutMethod = createCoreMethod("at:put:")
  atPutMethod.nativeImpl = cast[pointer](barrelTableAtPutImpl)
  atPutMethod.hasInterpreterParam = true
  addMethodToClass(tableClass, "at:put:", atPutMethod)

  let includesKeyMethod = createCoreMethod("includesKey:")
  includesKeyMethod.nativeImpl = cast[pointer](barrelTableIncludesKeyImpl)
  includesKeyMethod.hasInterpreterParam = true
  addMethodToClass(tableClass, "includesKey:", includesKeyMethod)

  let removeKeyMethod = createCoreMethod("removeKey:")
  removeKeyMethod.nativeImpl = cast[pointer](barrelTableRemoveKeyImpl)
  removeKeyMethod.hasInterpreterParam = true
  addMethodToClass(tableClass, "removeKey:", removeKeyMethod)

  let keysMethod = createCoreMethod("keys")
  keysMethod.nativeImpl = cast[pointer](barrelTableKeysImpl)
  keysMethod.hasInterpreterParam = true
  addMethodToClass(tableClass, "keys", keysMethod)

  let sizeMethod = createCoreMethod("size")
  sizeMethod.nativeImpl = cast[pointer](barrelTableSizeImpl)
  sizeMethod.hasInterpreterParam = true
  addMethodToClass(tableClass, "size", sizeMethod)
