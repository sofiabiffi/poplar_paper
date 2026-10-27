# File cleanup, 27 October 2026

Removed superseded `archive/` snapshots, Word-note `_history/` backups, rendered `_qa/` pages/PDFs, scenario history/QA, RStudio state, Python bytecode and `Rplots.pdf`. The deleted-file manifest records paths and hashes; its template entries were relocated rather than discarded.

Five Word input templates required by the figure updater were retained byte-for-byte under `references/note_templates/`. The updater now reads those paths. Current Word notes, manual revisions, source data, analysis scripts, current figures/tables/models and editable scenario deliverables were retained. No analysis or Word document was regenerated.

Ignore rules keep future backups, rendering artefacts and editor state out of commits. Current source data and current deliverables remain trackable. Git history was not rewritten: deleting previously committed files reduces the working tree and future snapshots, but does not remove their old Git objects.

This cleanup applies to `C:/Users/sofia/Documents/poplar_paper`. The separate older `misc_Rstuff` repository is unchanged.

Spreadsheet inspection dumps were also removed. Note backup/render helpers and scenario builders now create their ignored backup/QA directories when needed, so cleanup does not remove required directory prerequisites. No scientific calculations or Word contents were changed by those directory-creation edits.
