# Compilation

All JT arcade cores depend on JTFRAME for compilation:

* [CAPCOM arcades prior to CPS1](https://github.com/jotego/jtgng)
* [CAPCOM SYSTEM](https://github.com/jotego/jtcps)
* [Technos Double Dragon 1 & 2](https://github.com/jotego/jtdd) arcade games
* [Konami Contra](https://github.com/jotego/jtcontra)
* [System 16](https://github.com/jotego/jts16)
* etc.

## Prerequisites

1. A linux machine
2. Quartus
3. Python and Go installed
4. Python `pypng` package

JTFRAME uses a submodule to give support to the *Analogue Pocket* target. This submodule is not open source and you will get an error if you try to initialize it. You can safely ignore this submodule, it is only needed to create Pocket files.

## Quick Steps

These are the minimum compilation steps, using _Pirate Ship Higemaru_ as the example core

```
> git clone --recursive https://github.com/jotego/jt_gng
> cd jt_gng
> source setprj.sh
> cd $JTFRAME/cc && make && cd -
> jtcore hige
```

That should produce the MiST output. If you have a fresh linux installation, you probably need to install more programs. These are the compilation steps in more detail

* You need linux. I use Ubuntu mate but any linux will work
* You need 32-bit support if you're going to compile MiST/SiDi cores
* There are some linux dependencies that you can sort out with `sudo apt install`, mostly Python, the pypng pythong package, Go and the YAML.v2 package
* Populate the arcade core repository including submodules recursively. I believe in using submodules to break up tasks and sometimes submodules may have their own submodules. So be sure to populate the repository recursively. Be sure to understand how git submodules work
* Now jtframe should be located in `core-folder/modules/jtframe` go there and enter the `cc` folder. Run `make`. Make sure all files compile correctly and install whatever you need to make them compile. All should be in your standard linux software repository. Nothing fancy is needed
* Now go to the `core-folder` and run `source setprj.sh`
* Now you can compile the core using the `jtcore` script.

The output file is stored in **releases/target** where target stands for the FPGA platform (mist, mister, etc.). Most platforms use files with a .rbf extension, but some use a different extension -though the underlying file type is the same.

## jtcore

jtcore is the script used to compile the cores. It does a lot of stuff and it does it very well. Taking as an example the [CPS0 games](https://github.com/jotego/jt_gng), these are some commands:

`jtcore gng -sidi`

Compiles Ghosts'n Goblins core for SiDi.

`jtcore tora -mister`

Compiles Tiger Road core for MiSTer.

Some cores, particularly if they only produce one RBF file, may alias jtcore. For [CPS1](https://github.com/jotego/jtcps1) do:

`jtcore cps1 -mister`

And that will produce the MiSTer version.

Run `jtcore -h` to get help on the commands.

jtcore can also program the FPGA (MiST or MiSTer) with the ```-p``` option. In order to use an USB Blaster cable in Ubuntu you need to setup two urules files. The script **jtblaster** does that for you.

## Macro definition

Macros for each core are defined in a **.def** file. This file is expected to be in the **hdl** folder. The syntax is:

* Each line contains a macro definition, with an optional value after `=`
* A value definition can be concatenated to a previos value by usin `+=` instead of `=`
* Each time a line starts with `[name]`, then a section starts that apply only to the FPGA platform called *name*
* It is possible to include another file by using `include myfile.def`
* `#` marks a comment

Example:

```
include common.def

CPS1
CORENAME=JTCPS1
GAMETOP=jtcps1_game
JTFRAME_CREDITS

CORE_OSD+=;O1,Original filter,Off,On;

[mister]
# OSD options
JTFRAME_ADPCM
JTFRAME_OSD_VOL
JTFRAME_OSD_SND_EN

JTFRAME_AVATARS
JTFRAME_CHEAT
```

Will include the file *common.def*, then define several macros and concatenate more values to those already present in CORE_OSD. Then, only for MiSTer, it will define some extra options

Macros are evaluated with `jtframe cfgstr <corename>`

## Folder and file locations

JTFRAME expects a specific environment. The following folders should exist:

Folder | Path       | Use
-------|------------|-----
cores  | root       | container for each core folder
foo    | cores      | container for core foo
hdl    | cores/foo  | HDL and include files for core foo
ver    | cores/foo  | verification files. A folder for each test bench
cfg    | cores/foo  | configuration files (macro, RTL generation...)
doc    | root       | documentation
rom    | root       | ROM files used for simulation. MRA scripts and .toml files
mra    | rom/mra    | MRA files

Each core can list the files that uses with a file called `jtcore.qip` (like jtgng.qip for the GnG core) or with a YAML file called `game.yaml`

### YAML files

As QIP files are cumbersome and specific to Quartus only, it is possible to bypass them and use a YAML format, like this:

```
game:
  - from: cps1
    get:
      - jtcps1_game.v
      - jtcps1_main.v
      - jtcps1_sound.v
      - common.yaml
jtframe:
  - from: sound
    get:
      - jtframe_uprate2_fir.yaml
      - jtframe_pole.v
modules:
  jt:
    - name: jt51
    - name: jt6295
  other:
    - from: jteeprom/hdl
      get:
      - jt9346.v
```

Each `from` key represents the location to gather the files from and it is combined with the upper key to make the full folder. For instance:

```
game:
  - from: cps1
    get:
    - jtcps1_game.v
```

will get the files `$CORES/cps1/hdl/jtcps1_game.v`

Files from the key `jtframe` are based in folder `$JTFRAME/HDL`. Files from `jt` modules will look directly for a file in `$MODULES/name/hdl/name.yaml`. And files from `other` are based in `$MODULES`

There is also a `target:` section but unless you are creating a new target for JTFRAME, you should not use it. Games cores should not directly reference files in the JTFRAME/target folder. An example of the `target:` section can be seen in [mist](../target/mist/common.yaml).

The utility `jtframe files` translates the yaml files to two files: a game.qip and a target.qip for compilation and a game.f and target.f for simulation. The compilation script [jtcore](../bin/jtcore) calls jtfiles in order to obtain the compilation files.
To get the simulation files call jtfiles as:

`jtframe files sim corename --target mister`

From the folder where you want the files game.f and target.f to be produced.