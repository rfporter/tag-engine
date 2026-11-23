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
* [muParser Expression Parser](https://www.vipm.io/package/lv_muparser/) v2.1.0.3
* [JSONText](https://www.vipm.io/package/jdp_science_jsontext/) v1.6.10 or later

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

