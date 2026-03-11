import std/[net, strutils, tables]
import harding/core/types
import harding/interpreter/objects
import bitbarrel_client

proc parseHostAndPort(host: string): tuple[host: string, port: Port] =
  result = (host: host, port: DefaultPort)

  if ":" notin host:
    return result

  let parts = host.rsplit(":", maxsplit = 1)
  if parts.len != 2 or parts[0].len == 0:
    return result

  try:
    result = (host: parts[0], port: parseInt(parts[1]).Port)
  except ValueError:
    discard

proc getClient(self: Instance): ptr BitBarrelClient =
  if self == nil or self.nimValue == nil:
    return nil

  cast[ptr BitBarrelClient](self.nimValue)

proc barrelConnectImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 1:
    return nilValue()

  let endpoint = parseHostAndPort(args[0].toString())
  var client = newClient(endpoint.host, endpoint.port)

  try:
    client.connect()
  except ClientError:
    return nilValue()

  let clientPtr = create(BitBarrelClient)
  clientPtr[] = client
  self.isNimProxy = true
  self.nimValue = cast[pointer](clientPtr)
  self.toValue()

proc barrelCreateImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 2:
    return falseValue

  let client = self.getClient()
  if client == nil:
    return falseValue

  let mode = if args[1].toString() == "critbit": bmCritBit else: bmHash

  try:
    return if client[].createBarrel(args[0].toString(), mode): trueValue else: falseValue
  except ClientError:
    falseValue

proc barrelUseImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  if args.len != 1:
    return falseValue

  let client = self.getClient()
  if client == nil:
    return falseValue

  try:
    return if client[].useBarrel(args[0].toString()): trueValue else: falseValue
  except ClientError:
    falseValue

proc barrelCloseImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  let client = self.getClient()
  if client == nil:
    return nilValue()

  client[].close()
  trueValue

proc barrelListBarrelsImpl(interp: var Interpreter, self: Instance, args: seq[NodeValue]): NodeValue {.nimcall.} =
  let client = self.getClient()
  if client == nil:
    return nilValue()

  try:
    let barrels = client[].listBarrels()
    let arrayClass = arrayClassCache
    if arrayClass == nil:
      return nilValue()
    let result = newInstance(arrayClass)
    for barrel in barrels:
      result.elements.add(barrel.toValue())
    return result.toValue()
  except ClientError:
    nilValue()

proc registerBarrelPrimitives*(interp: var Interpreter) =
  if not interp.globals[].hasKey("Barrel"):
    warn("Barrel class not found")
    return

  let barrelValue = interp.globals[]["Barrel"]
  if barrelValue.kind != vkClass:
    warn("Barrel class is not a class value")
    return

  let barrelClass = barrelValue.classVal
  barrelClass.isNimProxy = true
  barrelClass.hardingType = "Barrel"

  let connectMethod = createCoreMethod("connect:")
  connectMethod.nativeImpl = cast[pointer](barrelConnectImpl)
  connectMethod.hasInterpreterParam = true
  addMethodToClass(barrelClass, "connect:", connectMethod)

  let createMethod = createCoreMethod("create:mode:")
  createMethod.nativeImpl = cast[pointer](barrelCreateImpl)
  createMethod.hasInterpreterParam = true
  addMethodToClass(barrelClass, "create:mode:", createMethod)

  let useMethod = createCoreMethod("use:")
  useMethod.nativeImpl = cast[pointer](barrelUseImpl)
  useMethod.hasInterpreterParam = true
  addMethodToClass(barrelClass, "use:", useMethod)

  let closeMethod = createCoreMethod("close")
  closeMethod.nativeImpl = cast[pointer](barrelCloseImpl)
  closeMethod.hasInterpreterParam = true
  addMethodToClass(barrelClass, "close", closeMethod)

  let listMethod = createCoreMethod("listBarrels")
  listMethod.nativeImpl = cast[pointer](barrelListBarrelsImpl)
  listMethod.hasInterpreterParam = true
  addMethodToClass(barrelClass, "listBarrels", listMethod)
