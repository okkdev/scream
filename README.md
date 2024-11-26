# script

Run Gleam files as scripts.

## Usage

```sh
# Run a gleam file as script
scream file.gleam

# By default only the stdlib is available
# Add more dependencies using the --dependencies (-d) flag
scream file.gleam -d simplifile@2

# Scream creates a temporary minimal project in which it runs the gleam file.
# If you need any additional files you can have them copied to the root of the
# project using the --extra (-e) flag
scream file.gleam -e extra.txt
```

## Help

```sh
scream

  run gleam scripts

Usage:

  scream [OPTIONS] SCRIPT

Arguments:

  SCRIPT                          	The Gleam script you want to run

Options:

  [--target TARGET]               	Gleam target (default: Error(Nil))
  [--runtime RUNTIME]             	Gleam runtime (default: Error(Nil))
  [--dependencies,-d DEPENDENCIES]	Comma separated Gleam dependencies (default: Error(Nil))
  [--extra,-e EXTRA]              	Comma separated extra files to include into project root (default: Error(Nil))
  [--help,-h]                     	Print this help
```

## Compile binary

```sh
gleam build
deno compile --no-check -o ./dist/scream -A ./glue.mjs

# 🎉
./dist/scream
```
