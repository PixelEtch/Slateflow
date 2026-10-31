# Slateflow domain

Terms used in code, docs and reviews. Use these names; don't invent synonyms.

- **Project**: one numbered folder Slateflow builds, `NNN - <template>/`, ready for a Final Cut Pro edit. Building one is shown as "Create Project" in the app.
- **Template name**: the user's name for the project (labelled "Project name" in the app), sanitised to one safe path component. The number is added at build time.
- **Project Layout**: the on-disk shape of a Project (folder tree, `FCP/<root>.fcpxml`, `.slateflow.json`) and the build that writes it. Owned by `ProjectLayout`; the Folder Preview shows its plan. `Backup`, `FCP` and `Footage` are fixed; the other folders are the user's **Folders**.
- **Folders**: the editable part of the Project Layout, saved in Saved Settings as `/`-separated paths (`Admin/Scripts`).
- **Destination**: the folder new Projects go into, remembered across launches as an app-scoped bookmark.
- **Saved Settings**: the form state and its rules (`SavedSettings`), restored at launch: loaded once when the store is created and saved whole on every change. Footage Sources change only through it, so their linked Smart Collections stay in step.
- **Build Snapshot**: the configuration one build uses, captured once before any disk I/O. The Project, its manifest and its Build Archives entry all come from it.
- **Build Archives**: the local history of successful builds (`BuildRecord`), used to reapply a past configuration (shown as "Recent Projects" in the app). Stores format and naming, not roles, collections or sources.
- **Manifest**: the hidden `.slateflow.json` in each Project, describing how it was built.
- **Footage Source**: a camera or capture source (shown as "Cameras" in the app); each enabled one becomes a `Footage/` subfolder and can link a Smart Collection.
- **Smart Collection**: a Final Cut Pro event collection written into the FCPXML (by role, media type, keyword, text or camera angle).
