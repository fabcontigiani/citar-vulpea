# citar-vulpea

Emacs package integrating [citar](https://github.com/emacs-citar/citar) bibliography management with [vulpea](https://github.com/d12frosted/vulpea) note database.

## Features

- Create bibliography notes using vulpea's powerful note system
- Query notes by citation key using vulpea's SQLite database
- Citar integration with note indicators and completion
- Add/remove citation references to existing notes

## Installation

### Dependencies

- Emacs 27.2+
- [citar](https://github.com/emacs-citar/citar) 1.4+
- [vulpea](https://github.com/d12frosted/vulpea) 2.0+

### Configuration

```elisp
(use-package citar-vulpea
  :after (citar vulpea)
  :config
  (citar-vulpea-mode 1))
```

## Usage

Enable the integration:

```elisp
(citar-vulpea-mode 1)
```

### Commands

| Command | Description |
|---------|-------------|
| `citar-vulpea-add-reference` | Add a citation reference to current note |
| `citar-vulpea-remove-reference` | Remove a citation reference from current note |
| `citar-vulpea-find-citation` | Find notes citing a reference |
| `citar-vulpea-dwim` | Smart action based on context |

### Creating Notes

With `citar-vulpea-mode` enabled, use `M-x citar-open-notes` or citar's regular interface. When selecting a bibliography entry without an existing note, a new vulpea note will be created with:

- Title derived from the entry (configurable via `citar-vulpea-note-title-template`)
- `ROAM_REFS` property containing the citation key
- `bib` filetag (configurable via `citar-vulpea-keyword`)

## Customization

```elisp
;; Tag for bibliographic notes (default: "bib")
(setq citar-vulpea-keyword "bib")

;; Property for storing citation keys (default: "ROAM_REFS")
(setq citar-vulpea-refs-property "ROAM_REFS")

;; Note title template (default: "${author}, ${title}")
(setq citar-vulpea-note-title-template "${author} (${date}) ${title}")

;; Subdirectory for bib notes (default: nil)
(setq citar-vulpea-subdir "references")
```

## License

GPL-3.0-or-later
