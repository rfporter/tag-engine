# Tag Engine

## Documentation: LabVIEW Antidoc

Project documentation is generated with Wovalab's **Antidoc** (the `lvproj` add-on), run from the
command line through **G-CLI**.

- **Configuration:** `antidoc.config` in the project root. It is a binary file written by Antidoc's
  own configuration editor. Don't edit it by hand; change it through Antidoc.
- **Output:** `Antidoc-Output/` in the project root (AsciiDoc sources, `Images/`, and the
  rendered `Tag Engine.html` / `Tag Engine.pdf`).
- **CLI reference:** https://wovalab.gitlab.io/open-source/docs/cli-tool-for-antidoc/latest/CLI.html

### Updating the docs

G-CLI is installed at `C:\Program Files\G-CLI\bin\g-cli`. The project is saved in LabVIEW 2020,
so use `--lv-ver 2020`. **All paths must be absolute**: with relative paths Antidoc fails with
error 1430 ("The path is empty or relative").

```bash
R='C:\LabVIEW\tag-engine'
# Package version from the "Source Distribution" build spec (unset parts count as 0)
V=$(perl -ne '$in=1 if /Type="Source Distribution"/; if($in && /Bld_version\.(major|minor|patch|build)" Type="Int">(\d+)/){$v{$1}=$2} $in=0 if $in && m{</Item>}; END{print join(".", map {$v{$_}//0} qw(major minor patch build))}' "$R/Tag Engine.lvproj")
for fmt in html pdf; do
  env -u NoDefaultCurrentDirectoryInExePath g-cli --lv-ver 2020 antidoc -- -addon lvproj -pp "$R\Tag Engine.lvproj" -t "Tag Engine" -a "Ryan Porter" -configpath "$R\antidoc.config" -out "$R\Antidoc-Output" -commit "$V" -commitdate "$(date +%F)" -render $fmt -close
done
```

- `-render` takes one value per run: `html` or `pdf`, hence the loop. Leave `-render` out to
  generate only the `.adoc` sources.
- `-close` closes the Antidoc VI when it finishes.
- The command needs LabVIEW 2020 with Antidoc and its CLI add-on installed. It opens LabVIEW if
  it isn't already running.
- Rendering uses the Asciidoctor copy bundled with AsciiDoc for LabVIEW
  (`%LOCALAPPDATA%\Asciidoc For LabVIEW\RubyInstance\bin`), which is run by name from that
  folder. If LabVIEW was started with `NoDefaultCurrentDirectoryInExePath` set (Claude Code's
  shell sets it), `cmd` won't look in the current folder and rendering fails with error 5003
  ("'asciidoctor' is not recognized"). The `env -u` above keeps it out of a LabVIEW that G-CLI
  starts. A LabVIEW that is already running with it set must be quit and restarted.

### Version on the cover page

The cover shows "Version <package version>, <date>", where the version is the Source Distribution
build spec's version. Antidoc has no version option, so this works around it:

- `-commit` and `-commitdate` become the AsciiDoc `revnumber` and `revdate`. Antidoc writes them
  only when both are given.
- Antidoc labels `revnumber` "Commit", writes `-tag` (or "No tag") as `revremark`, and puts
  "Antidoc vX.Y.Z" and "Antidoc CLI" in the author line. These are fixed in the `.adoc` header.
- Antidoc's per-user settings file overrides them at render time. It lives outside the repo, at
  `%USERPROFILE%\Documents\LabVIEW Data\Antidoc\Antidoc.ini`, and must contain:

  ```ini
  [Custom Attributes]
  version-label=Version
  author=Ryan Porter
  revremark!=
  ```

  It applies to every Antidoc run for this Windows user. Without it, the cover shows
  "Commit 2.2.0.0" and the Antidoc author entries again.
- The `.adoc` sources keep Antidoc's original header; only the rendered HTML and PDF change.

### Third-party licenses

Dependency licenses live in `THIRD-PARTY-NOTICES.adoc` in the project root. Antidoc doesn't detect
them (its "Product used in the project" section only knows DQMH and JKI State Machine), so the
project description in `Tag Engine.lvproj` ends with
`include::../../THIRD-PARTY-NOTICES.adoc[leveloffset=+2]`, which pulls the file into the docs.
The path is relative to `Antidoc-Output/Includes/`. Update the file when a dependency is added,
removed or upgraded.

Antidoc reads the project description from LabVIEW's memory when the project is open. Close the
project before generating the docs after editing the `.lvproj` on disk, and don't save it from
LabVIEW, or the edit is overwritten.

### When to update

Regenerate the docs after changing VI descriptions, adding or removing VIs, or changing the
project structure. Commit the regenerated `Antidoc-Output/` together with the code change.

## User manual

The user manual (PDF) is built from the Source Distribution build by `UserManual/build-manual.pl`.
Antidoc's own toolkit add-on (`-addon toolkit`) crashes LabVIEW on this palette, so it isn't used.

```bash
perl UserManual/build-manual.pl              # PDF; --render html|none, --out DIR, --version X.Y.Z.W
```

Order: Source Distribution build, then the Antidoc project docs (for the connector pane images in
`Antidoc-Output/Images`), then the manual. Output goes to `..\builds\Tag Engine\User Manual\`.

- **Palette:** read from `Library_Palette_Definition` in `Tag Engine.vipb`. One chapter per palette
  (top level first, then the subpalettes in palette order), with an overview table and a section
  per item in row/column order. The built-in Property Node item lists the Tag class properties
  from `Tag/Tag.lvclass`.
- **VI descriptions:** read from the built VIs (the `STRG` block, see `UserManual/lib/lvrsrc.pm`).
  "- item" lines become lists. Fix wording in the VI, not in the output.
- **Hand-written chapters:** `UserManual/src/` (main file `Tag Engine User Manual.adoc`, plus
  introduction, concepts, getting started). `THIRD-PARTY-NOTICES.adoc` is taken from the build.
- **Version:** from the Source Distribution build spec, as for the Antidoc docs.
- **Rendering:** the Asciidoctor PDF copy installed by AsciiDoc for LabVIEW, run through its own
  `ruby.exe` in `%LOCALAPPDATA%\Asciidoc For LabVIEW\RubyInstance\bin`. No PATH setup needed.
