# Known Issues

Open problems found while reviewing the code (2026-11-23). None of them is fixed yet.

## Tag Engine Core

### 1. Remove Tag and Destruct drop their internal errors

**Where:** `Core/Remove Tag.vi`, `Core/Destruct.vi` (Tag Core.lvclass)

Errors raised inside these VIs are not passed to `error out`. A failure while removing a Tag or
destroying the registry goes unreported.

**Fix:** wire the internal error chain through to `error out`.

### 2. Get Tag LUT returns a freed DVR after Destruct

**Where:** `Core/Get Tag LUT.vi`

The lookup-table DVR is created on First Call? and kept in an uninitialized shift register. After
Tag Core's Destruct frees it, Get Tag LUT keeps returning the freed reference until LabVIEW unloads
the VI. The registry is not recreated on the next call, so Tag Engine can't be used again after
Destruct in the same session.

**Fix:** after Destruct, or whenever the stored DVR is no longer valid, create a new one instead of
returning the old reference.

### 3. New Tag leaks user events when the name is rejected

**Where:** `API/New Tag.vim`

When New Tag fails with error 5609 (illegal character in the name) or 5610 (name longer than 256
characters), the ValChange and SetRequest user events created for the Tag are never destroyed.

**Fix:** destroy the Tag (and its events) on those errors, or check the name before creating the
events.

## Tag Expr

### 4. Error 5605 names the placeholder, not the Tag

**Where:** `Tag Expr/Lookup Tag Values.vi`

The message "Tag %s type %s cannot be coerced to DBL for expression eval" is given the placeholder
variable name, so it reads "Tag TAG00 type ..." instead of the Tag's real name.

**Fix:** pass the Tag name (for example from the Tag reference) as the first parameter.

### 5. Signed enums are not supported

**Where:** `Tag Expr/Lookup Tag Values.vi`

The signed-integer case is `"I8".."I64"`. Unlike the unsigned case, which also lists
`"Enum U8".."Enum U64"`, it has no `"Enum I8".."Enum I64"`. A Tag holding a signed enum falls
through to the default case and returns error 5605.

**Fix:** add `"Enum I8".."Enum I64"` to the signed-integer case.

### 6. `TagVarNames` field name is misleading

**Where:** `Tag Expr/Tag Expr.lvclass` private data, `Tag Expr/Read TagVarNames.vi`

The `TagVarNames` field holds the placeholder names (TAG00, TAG01, ...), but Read TagVarNames
returns the real Tag names, which it reads through the stored references.

**Fix:** rename the field (for example to `TagPlaceholders`), or make the accessor match the field.

### 7. Read TagVarNames ignores errors

**Where:** `Tag Expr/Read TagVarNames.vi`

Errors from the Property Node that reads each Tag's name are not wired out. A reference to a Tag
that has been destroyed returns an empty name and no error.

**Fix:** chain the Property Node errors to `error out`.

## Tag Watchlist

### 8. Tag list is not refreshed

**Where:** `Watchlist/Tag Watchlist UI.vi`

The list of all Tags is filled only when the window opens (Get All Tags in the "init" case). Tags
created later don't appear until the window is reopened.

**Fix:** refresh the list periodically, or add a refresh button or menu item.

### 9. SetRequests from the pop-up have no Source

**Where:** `Watchlist/ValueEntry/Tag_Value_Entry_PopUp.vi`

The Source input of Send Tag SetRequest_ByRef is not wired, so requests are anonymous. If the Tag
is locked, the 5611 message doesn't show that the request came from the Watchlist.

**Fix:** wire a constant such as "Tag Watchlist" to Source.

### 10. Several types fall back to JSON editing

**Where:** `Watchlist/ValueEntry/Tag_Value_Entry_PopUp.vi`

Enums, I64, U64 and EXT have no typed pop-up. They open the string pop-up with the value as JSON,
which is easy to get wrong.

**Fix:** add cases for these types (for example a ring pop-up for enums, and the I32/U32/DBL pop-ups
widened or duplicated for 64-bit and EXT).

## Files

### 11. Compiled code saved in source-only files

These files are marked "Separate compiled code from source" but still contain compiled code (a
VICD block), or have the option turned off:

- `Examples/Benchmark (SubVI).vi`
- `Examples/Benchmark VIReg(SubVI).vi` (option turned off)
- `Examples/Tag Engine Test 1.vi`
- `Examples/Tag Watchlist Example.vi`
- `Tag/Unflatten from JSON Config.vi`
- `Types/SetRequest Cluster.ctl`
- `Types/ValChange Cluster.ctl`
- `Unit Tests/Tag Engine_general.utest.vi`
- `Unit Tests/TagExpr_general.utest.vi`
- `Watchlist/Tag_Details_PopUp.vi`

Compiled code in source files causes needless diffs and recompiles in source control.

**Fix:** turn on "Separate compiled code from source file" where it is off, then force a recompile
and save (Ctrl+Shift+click Run, or mass compile) so LabVIEW rewrites the files without compiled code.

## Documentation

### 12. Lists in VI descriptions don't render in the Antidoc docs

**Where:** the descriptions of `Tag Expr/Lookup Tag Values.vi`,
`Watchlist/ValueEntry/Tag_Value_Entry_PopUp.vi` and `Watchlist/Tag Watchlist UI.vi`

Antidoc puts VI descriptions in table cells that render plain paragraphs only, so "- item" lists
run together on one line.

**Fix:** end each list line with ` +` (an AsciiDoc line break), or rewrite the lists as sentences.
