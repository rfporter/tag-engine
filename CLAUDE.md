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

`build-docs.rb` in the project root builds all documentation: the Antidoc docs (HTML, then PDF)
and then the user manual. Run it with the Ruby that AsciiDoc for LabVIEW installs, or with
`build-docs.cmd` from `cmd` or Explorer:

```bash
RUBY="$LOCALAPPDATA/Asciidoc For LabVIEW/RubyInstance/bin/ruby.exe"
"$RUBY" build-docs.rb                  # --only-antidoc, --only-manual, --formats html|pdf, --lv-ver
```

Close `Tag Engine.lvproj` in LabVIEW first (Antidoc reads an open project from memory). The script
exits non-zero if a step fails; it also checks G-CLI's output, because G-CLI can return 0 after an
Antidoc error. It warns if `Antidoc.ini` lacks the cover-page settings below.

What it runs for Antidoc, per format (for reference, or to run by hand):

```bash
R='C:\LabVIEW\tag-engine'
V=$("$RUBY" -r ./UserManual/lib/lv_files -e 'puts LvFiles.build_version("Tag Engine.lvproj")')
env -u NoDefaultCurrentDirectoryInExePath g-cli --lv-ver 2020 antidoc -- -addon lvproj -pp "$R\Tag Engine.lvproj" -t "Tag Engine" -a "Ryan Porter" -configpath "$R\antidoc.config" -out "$R\Antidoc-Output" -commit "$V" -commitdate "$(date +%F)" -render html -close
```

- G-CLI is installed at `C:\Program Files\G-CLI\bin\g-cli`. The project is saved in LabVIEW 2020,
  so use `--lv-ver 2020`.
- **All paths must be absolute**: with relative paths Antidoc fails with error 1430 ("The path is
  empty or relative").
- `-render` takes one value per run: `html` or `pdf`. Leave it out to generate only the `.adoc`
  sources.
- `-close` closes the Antidoc VI when it finishes.
- The command needs LabVIEW 2020 with Antidoc and its CLI add-on installed. It opens LabVIEW if
  it isn't already running.
- Rendering uses the Asciidoctor copy bundled with AsciiDoc for LabVIEW
  (`%LOCALAPPDATA%\Asciidoc For LabVIEW\RubyInstance\bin`), which is run by name from that
  folder. If LabVIEW was started with `NoDefaultCurrentDirectoryInExePath` set (Claude Code's
  shell sets it), `cmd` won't look in the current folder and rendering fails with error 5003
  ("'asciidoctor' is not recognized"). `build-docs.rb` and the `env -u` above keep it out of a
  LabVIEW that G-CLI starts. A LabVIEW that is already running with it set must be quit and
  restarted.

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

The user manual (PDF) is built from the project folder by `UserManual/build-manual.rb`, a Ruby
script that uses Asciidoctor directly. It doesn't need the Source Distribution build. Antidoc's own toolkit add-on (`-addon toolkit`)
crashes LabVIEW on this palette, so it isn't used.

It runs with the Ruby that AsciiDoc for LabVIEW installs, which has Asciidoctor and Asciidoctor
PDF. AsciiDoc for LabVIEW and Antidoc are assumed to be installed.

```bash
R="$LOCALAPPDATA/Asciidoc For LabVIEW/RubyInstance/bin/ruby.exe"
"$R" UserManual/build-manual.rb              # PDF; --render html|none, --out DIR, --version X.Y.Z.W
```

From `cmd` or Explorer, `UserManual\build-manual.cmd` finds that Ruby and passes its arguments on.
`build-docs.rb` (see above) runs it after Antidoc, with the same version.

Order: the Antidoc project docs first (for the connector pane images in `Antidoc-Output/Images`),
then the manual. The PDF goes to `UserManual/Tag Engine User Manual.pdf`.
`--render none` only checks the document. The script exits with 1 if Asciidoctor or the palette
reference logged a warning (for example a missing connector pane image); the output is still
written.

- **Main document:** `UserManual/src/Tag Engine User Manual.adoc`, with the hand-written chapters
  (introduction, concepts, getting started) next to it. Edit these.
- **Palette reference:** generated during rendering by an Asciidoctor include processor
  (`UserManual/lib/palette_reference.rb`) for `include::palette:{vipb}[]`. It reads
  `Library_Palette_Definition` in `Tag Engine.vipb`: one chapter per palette (top level first, then
  the subpalettes in palette order), an overview table, and a section per item in row/column order.
  The built-in Property Node item lists the Tag class properties from `Tag/Tag.lvclass`.
- **Palette VIs → project VIs:** the `.vipb` names each VI by its path in the Source Distribution
  folder (`Library_Source_Folder`). That build keeps the project's folder layout, so the VI is read
  from the same relative path in the project. If that file doesn't exist, a VI with the same name
  is used if there is exactly one (names alone are ambiguous: there are four `Destruct.vi`).
- **VI descriptions:** read from the project's VIs (the `STRG` block, `UserManual/lib/lv_resource.rb`).
  The text is wrapped in `pass:c[]`, so it is never read as AsciiDoc markup. "- item" lines become
  lists. Fix wording in the VI, not in the output.
- **Third-party notices:** included from the project root (`{project-dir}/THIRD-PARTY-NOTICES.adoc`).
- **Version:** from the Source Distribution build spec, as for the Antidoc docs.
- **XML files** (`.vipb`, `.lvproj`, `.lvlib`, `.lvclass`) are read with REXML
  (`UserManual/lib/lv_files.rb`).
