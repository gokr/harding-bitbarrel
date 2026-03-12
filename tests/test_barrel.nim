## ============================================================================
## BitBarrel Integration Tests
## Tests for BitBarrel database integration with Harding
## ============================================================================
##
## This test file is part of the bitbarrel external library.
## It can be run via the harding test infrastructure:
##   nimble test
##
## Or directly (when compiled with -d:harding_bitbarrel):
##   nim c -r -d:harding_bitbarrel tests/test_barrel.nim
##

when defined(harding_bitbarrel):
  import std/[osproc, strutils, unittest]

  suite "BitBarrel Integration":
    test "external BitBarrel classes load in harding":
      ## Test that the BitBarrel library classes are available
      let cmd = "./harding -e \"Barrel class name println. BarrelTable class name println. BarrelSortedTable class name println\""
      let (output, exitCode) = execCmdEx(cmd)
      check exitCode == 0
      check output.contains("Barrel")
      check output.contains("BarrelTable")
      check output.contains("BarrelSortedTable")

    test "BarrelTable can be instantiated":
      ## Test basic BarrelTable creation
      let cmd = "./harding -e \"t := BarrelTable new. t class name println\""
      let (output, exitCode) = execCmdEx(cmd)
      check exitCode == 0
      check output.contains("BarrelTable")

else:
  echo "BitBarrel tests skipped (compile with -d:harding_bitbarrel)"