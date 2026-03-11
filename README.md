# Harding BitBarrel

BitBarrel integration for Harding as an external library.

This library packages:
- Harding classes under `lib/bitbarrel/`
- native Nim primitives that bind those classes to the BitBarrel Nim client

It depends on the upstream Nim client package `bitbarrel_client`.

## Install In Harding

From a Harding checkout:

```bash
./harding lib install bitbarrel
nimble harding
```

If you cloned this library manually into `external/bitbarrel`, regenerate imports first:

```bash
nimble discover
nimble harding
```

## Runtime Requirement

You still need a running BitBarrel server.

By default the Harding classes connect to `localhost:9876`.

## Library Layout

```text
bitbarrel/
├── bitbarrel.nimble
├── README.md
├── lib/
│   └── bitbarrel/
│       ├── Barrel.hrd
│       ├── BarrelSortedTable.hrd
│       ├── BarrelTable.hrd
│       └── Bootstrap.hrd
└── src/
    └── bitbarrel/
        ├── barrel.nim
        ├── barrel_sorted_table.nim
        ├── barrel_table.nim
        └── bitbarrel.nim
```
