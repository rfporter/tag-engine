# Tag Engine for LabVIEW

Named, typed, event-driven tag variables for LabVIEW, like the tag database in a SCADA system.

Tag Engine gives a LabVIEW application a central store of named variables, called **tags**, like the tag database in a SCADA system. Any part of the application can create, read, write or watch a tag by name, without passing wires or queues between loops.

Each tag holds a value of any LabVIEW data type, a timestamp, and properties such as description, units and limits. It also has two events: **ValChange**, fired when the value changes, and **SetRequest**, which lets other code ask the tag's owner to change the value instead of writing it directly. Tags can be locked so that set requests are blocked under certain conditions.

It was inspired by the [NI Current Value Table Toolkit](https://www.vipm.io/package/ni_lib_cvt/) and [GPower VI Register Toolkit](https://www.vipm.io/package/gpower_lib_viregister/), and adds events, properties, locking and JSON configuration.

## Features

* **Any data type**: values are stored as variants. The type is fixed by the initial value, and malleable VIs read and write values in their native type.
* **Access by name or reference**: look tags up by name (not case-sensitive), or keep the tag's reference for faster access.
* **Namespaces**: group tags as `Namespace:Name`; the separator can be configured.
* **Events**: ValChange on every write, with old and new values. SetRequest for requested changes, optionally synchronous with a timeout, and tagged with the requester's Source.
* **Locking**: named locks block SetRequests (error 5611) until every lock is released, so requests can be refused under certain conditions. Direct writes are not affected.
* **Properties**: description, units, min, max, default, format string and more, filled in automatically from the tag's data type. Custom properties can be added too.
* **Staleness and timestamps**: every value carries the time of its last write and a Stale flag.
* **JSON configuration**: save and restore tag definitions as JSON.
* **Expressions**: use tags in math expressions with `${TAG_NAME}` syntax, through the Tag Expr library (built on muParser).
* **Watchlist UI**: a ready-made window to watch and edit tag values at run time.
* **PPL-ready**: the core (Tag Engine Core.lvlib) is kept separate so it can be built into a packed project library.

This library is open source and licensed under BSD 2-Clause.

# Requirements

* LabVIEW 2020 or later
* [muParser Expression Parser](https://www.vipm.io/package/lv_muparser/) v3.1.2.1 or later
* [JSONText](https://www.vipm.io/package/jdp_science_jsontext/) v1.9.1.125 or later

# Installation

Install the vip package using VI Package Manager.

# Changes

v2.0.1.1

* Variant data to string now simply calls JSONText's variant to string

V2.0.2.1

* Removed relaxed type feature from read tag value. It was too heavy.
* Removed "out" from output name of Init ValChange Events Cluster.vim

V2.0.3.1

* Removed relaxed type feature from get tag property

V2.0.4.4

* Flattened VIMs to try to avoid build issues.

V2.0.5.1

* Fix Init Valchange Events Cluster - Valchange event lookup

V2.0.6.1

* Fixed issues 3-6
* Added tag details popup to watch window.

V2.1.0.2

* Restructure to allow for use as a PPL (breaking change).

V2.2.0.1

* Add source string to Set Request event data. Can be used to indicate from where the Request is made.
* Add lock list per tag. Used to block tag's Set Request events.
* Change Tag Expression syntax (breaking change). Tag names must be wrapped in ${TAG\_NAME} in order to be marked as tags instead of variables. This loosens restrictions on tag naming, allowing for "/" character as tag namespace delimiter.

# Known Issues

* All expressions are evaluated as DBL type. Must be aware that tag values are converted to DBL for eval.
* Need to be aware of the lifetime of DVRs. When a DVR creator's VI hierarchy leaves memory, so does the DVR.

# Support

Contact Porter on LAVA (https://lavag.org) or NI Forums (https://forums.ni.com/)

# Acknowledgements

Thanks to EZ-TechStop LLC and Canter Automation Inc for supporting this project.

# Setting Up the Development Environment

To work on Tag Engine itself (not just use it), set up a Windows PC as follows. The versions are the ones the project is currently developed with; newer versions should work.

1. **LabVIEW 2020 SP1** (32-bit). The project is saved in LabVIEW 2020, so don't save it in a newer version.
2. **VI Package Manager (VIPM)**, to install the packages below and to build the Tag Engine package from `Tag Engine.vipb`.
3. Install these packages into LabVIEW 2020 with VIPM:

   | Package | Version | Used for |
   |---|---|---|
   | JSONtext (JDP Science) | 1.9.1.125 | Runtime dependency |
   | muParser Expression Parser (`lv_muparser`) | 3.1.2.1 | Runtime dependency (Tag Expr) |
   | Caraya (JKI) | 1.4.4.148 | Unit tests |
   | G-CLI (Wiresmith Technology) | 3.0.1.98 | Running the unit tests and Antidoc from the command line; installs `g-cli.exe` in `C:\Program Files\G-CLI\bin` |
   | Antidoc (Wovalab) | 3.3.2.887 | Project documentation |
   | Antidoc add-on: LabVIEW Project documentation | 3.3.0.411 | Project documentation |
   | Antidoc CLI | 3.4.0.126 | Running Antidoc through G-CLI |
   | AsciiDoc for LabVIEW (Wovalab) | 1.12.1.492 | Rendering the docs; installs the Ruby, Asciidoctor and Asciidoctor PDF used by `build-docs.rb` |

   VIPM installs the packages these depend on (OpenG, JKI State Machine and others).
4. **Antidoc settings:** create `%USERPROFILE%\Documents\LabVIEW Data\Antidoc\Antidoc.ini` as described under [Prerequisites](#prerequisites) in Building the Documentation.
5. **Git**, to clone the repository. The scripts don't depend on where it is cloned.

Don't install the Tag Engine package itself into the LabVIEW used for development. Its VIs have the same names and libraries as the project's, so LabVIEW could load the installed copies instead of the ones in the repository.

To check the setup, open `Tag Engine.lvproj` (no missing dependencies should be reported), close it, then [run the unit tests](#running-the-unit-tests) and [build the documentation](#building-the-documentation).

# Running the Unit Tests

The unit tests are [Caraya](https://github.com/JKISoftware/Caraya) tests in `Unit Tests/` (every `*.utest.vi`). To run them in the LabVIEW editor, run a test VI.

To run them all from the command line, use [G-CLI](https://github.com/wiresmith-tech/G-CLI) with `Unit Tests/Run Unit Tests.vi`. It needs LabVIEW 2020 with Caraya and G-CLI installed:

```
g-cli --lv-ver 2020 "C:\LabVIEW\tag-engine\Unit Tests\Run Unit Tests.vi" -- [report path]
```

* It writes a JUnit XML report to the report path, or to `Unit Tests/Unit Tests-TestReport.xml` if no path is given. Report files are ignored by git.
* The exit code is 0 when every test passes, and the Caraya error code (7002) when a test fails.
* `Run Unit Tests.vi` is set to run when opened, so opening it in the editor runs the tests. Wait for it to finish (or abort it) before editing it.

# Building the Documentation

The documentation has two parts:

* **Project documentation** in `Antidoc-Output/` (`Tag Engine.html` and `Tag Engine.pdf`), generated from the project by [Antidoc](https://wovalab.gitlab.io/open-source/docs/antidoc/latest/).
* **User manual** in `UserManual/Tag Engine User Manual.pdf`, built from the hand-written chapters in `UserManual/src/` and a palette reference generated from the functions palette in `Tag Engine.vipb`.

Both show the version of the Source Distribution build spec in `Tag Engine.lvproj`.

## Prerequisites

* LabVIEW 2020 with Antidoc and its CLI add-on (from VIPM)
* AsciiDoc for LabVIEW (from VIPM), which installs the Ruby and Asciidoctor that the scripts use
* G-CLI
* An Antidoc settings file, `%USERPROFILE%\Documents\LabVIEW Data\Antidoc\Antidoc.ini`, containing the following, so that the cover page shows the package version and author:

  ```ini
  [Custom Attributes]
  version-label=Version
  author=Ryan Porter
  revremark!=
  ```

## Building

1. Close `Tag Engine.lvproj` in LabVIEW. Antidoc reads an open project from memory, so unsaved or on-disk changes would be missed.
2. Run `build-docs.cmd` from the project folder (or double-click it in Explorer).

The script builds the Antidoc HTML, then the Antidoc PDF, then the user manual, and stops with an error if any step fails. Options:

| Option | Effect |
|---|---|
| `--only-antidoc` | Build only the project documentation |
| `--only-manual` | Build only the user manual (needs the connector pane images in `Antidoc-Output/Images` from an earlier Antidoc run) |
| `--formats html,pdf` | Antidoc formats to render (default: both) |
| `--lv-ver 2020` | LabVIEW version G-CLI uses (default: 2020) |

To build or check only the user manual, run `UserManual\build-manual.cmd`; `--render html` writes HTML and `--render none` checks the document without writing it.

Regenerate the documentation after changing VI descriptions, adding or removing VIs, or changing the palette, and commit `Antidoc-Output/` together with the code change.

# Building a Release

Build a release in this order, so that the package contains tested code and up-to-date documentation. Paths are relative to the repository folder.

1. **Set the version.** Use the same version in both places:
   * the **Source Distribution** build spec in `Tag Engine.lvproj` (Properties > Version Information). The documentation takes its version from here.
   * `Tag Engine.vipb` (open it in VIPM; the version is at the top of the build window).

   Add the release to [Changes](#changes) in this README.
2. **Run the unit tests** (see [Running the Unit Tests](#running-the-unit-tests)) and check that every test passes (exit code 0).
3. **Build the documentation.** Close `Tag Engine.lvproj` in LabVIEW, then run `build-docs.cmd` (see [Building the Documentation](#building-the-documentation)). Check that the covers of `Antidoc-Output/Tag Engine.pdf` and `UserManual/Tag Engine User Manual.pdf` show the new version.
4. **Build the Source Distribution.** Delete `../builds/Tag Engine/Source Distribution` if it exists, so files removed from the project don't stay in the package. Open `Tag Engine.lvproj`, right-click **Build Specifications > Source Distribution** and select **Build**. The output goes to `../builds/Tag Engine/Source Distribution`.
5. **Build the VIPM package.** Open `Tag Engine.vipb` in VIPM and click **Build**. It packages the Source Distribution output (not the project folder), with the functions palette defined in the `.vipb`. The package (`tag_engine-<version>.vip`) goes to `../builds/Tag Engine`.
6. **Test the package.** Install it with VIPM in a LabVIEW that isn't used for development (see [Setting Up the Development Environment](#setting-up-the-development-environment)), and check the palette and an example.
7. **Commit and tag.** Commit the version change, the changelog and the regenerated `Antidoc-Output/`, and tag the commit with the version (for example `v2.2.0.2`).
