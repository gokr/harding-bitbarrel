import harding/core/types
import harding/packages/package_api

import ./barrel
import ./barrel_table
import ./barrel_sorted_table

const
  BootstrapHrd = staticRead("../../lib/bitbarrel/Bootstrap.hrd")
  BarrelHrd = staticRead("../../lib/bitbarrel/Barrel.hrd")
  BarrelTableHrd = staticRead("../../lib/bitbarrel/BarrelTable.hrd")
  BarrelSortedTableHrd = staticRead("../../lib/bitbarrel/BarrelSortedTable.hrd")

proc registerBitbarrelPrimitives(interp: var Interpreter) {.nimcall.} =
  registerBarrelPrimitives(interp)
  registerBarrelTablePrimitives(interp)
  registerBarrelSortedTablePrimitives(interp)

proc installBitbarrel*(interp: var Interpreter) =
  let spec = HardingPackageSpec(
    name: "BitBarrel",
    version: "0.1.0",
    bootstrapPath: "lib/bitbarrel/Bootstrap.hrd",
    sources: @[
      (path: "lib/bitbarrel/Bootstrap.hrd", source: BootstrapHrd),
      (path: "lib/bitbarrel/Barrel.hrd", source: BarrelHrd),
      (path: "lib/bitbarrel/BarrelTable.hrd", source: BarrelTableHrd),
      (path: "lib/bitbarrel/BarrelSortedTable.hrd", source: BarrelSortedTableHrd)
    ],
    registerPrimitives: registerBitbarrelPrimitives
  )

  discard installPackage(interp, spec)
