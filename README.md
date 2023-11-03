# Tag Engine for LabVIEW
A SCADA-like tag variable engine for LabVIEW.

This library aims to provide a tag variable engine to LabVIEW, similar to what would be found in most SCADA application development environments.

It is inspired by the [NI Current Value Table Toolkit](https://www.vipm.io/package/ni_lib_cvt/) and [GPower VI Register Toolkit](https://www.vipm.io/package/gpower_lib_viregister/).

Like these toolkits, it provides global access to named variables (called tags).

Key features of this library are:
- Tags can be programmatically created and destroyed.
- Data values stored as variant so that all LabVIEW data types are supported.
- ValueChanged event is triggered on tag write value
- SetRequest event allows request to change value without writing directly to the tag.
- Tags are stored in Data Value References. The API can use either tag's name or the tag's data value reference wire.
- Can store tag properties alongside the tag data. Standard properties are description, units, max value, min value.
- Tag names can be used in math expressions directly, using the provided Tag Expr library (extension of muParser for LabVIEW).
- Malleable VIs are used to provide a convenient interface for reading and writing tags.
- Tag configuration can be stored in JSON format.
- Timestamp of last value change is stored alongside the tag data.

This library is open source and licensed under BSD 2-Clause.

# Requirements
- LabVIEW 2020 or later
- [muParser Expression Parser](https://www.vipm.io/package/lv_muparser/) v2.1.0.3
- [JSONText](https://www.vipm.io/package/jdp_science_jsontext/) v1.6.10 or later

# Installation
Install the vip package using VI Package Manager.

# Changes
v2.0.1.1
- Variant data to string now simply calls JSONText's variant to string
V2.0.2.1
- Removed relaxed type feature from read tag value. It was too heavy.
- Removed "out" from output name of Init ValChange Events Cluster.vim
V2.0.3.1
- Removed relaxed type feature from get tag property
V2.0.4.3
- Flattened VIMs to try to avoid build issuse.

# Known Issues
- All expressions are evaluated as DBL type. Must be aware that tag values are converted to DBL for eval.
- Need to be aware of the lifetime of DVRs. When a DVR creator's VI hierarchy leaves memory, so does the DVR.

# Support
Contact Porter on LAVA (https://lavag.org) or NI Forums (https://forums.ni.com/)

# Acknowledgements
Thanks to EZ-TechStop LLC and Canter Automation Inc for supporting this project.
