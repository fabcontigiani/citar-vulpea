# citar-vulpea

Emacs package integrating [citar](https://github.com/emacs-citar/citar) bibliography management with [vulpea](https://github.com/d12frosted/vulpea) note database.

## Features

- Create bibliography notes from selected citations using Vulpea's note system
- Find notes associated with a citation key
- Citar integration with note indicators and completion
- Add or remove citation references in existing notes

### Screenshots

<img width="1242" height="425" alt="msrdc_dk347g9y9O" src="https://github.com/user-attachments/assets/b55e778a-2b4c-4230-a8f8-398177beee28" />
<img width="1242" height="453" alt="msrdc_h2pi26a9Dq" src="https://github.com/user-attachments/assets/7dfae854-3034-4574-8f8a-5a33029eef22" />

## Installation

### Requirements

- Emacs 27.2+
- [citar](https://github.com/emacs-citar/citar) 1.4+
- [vulpea](https://github.com/d12frosted/vulpea) 2.0+

### Install from source

Clone this repository somewhere on your `load-path`, or use `package-vc-install` if you are on Emacs 29+.

### Configuration

```elisp
(use-package citar-vulpea
  :load-path "/path/to/citar-vulpea"
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
| `citar-vulpea-dwim` | Open a citation from the current note, or add one if none exists |

### Creating Notes

With `citar-vulpea-mode` enabled, use `M-x citar-open-notes` or citar's regular interface. When selecting a bibliography entry without an existing note, a new vulpea note will be created with:

- Title derived from the entry (configurable via `citar-vulpea-note-title-template`)
- A refs property containing the citation key so the note can be found again later (default: `ROAM_REFS` for org-roam compatibility; configurable via `citar-vulpea-refs-property`)
- `bib` filetag (configurable via `citar-vulpea-keyword`)

The refs property is the link between a note and one or more citekeys. The package reads that property when searching for notes by citation key.

### DWIM Command

`citar-vulpea-dwim` looks at the current Org note and does the most useful thing:

- if the note already has citation refs, it opens one of them in `citar`
- if the note has multiple refs, it lets you choose which one to open
- if the note has no refs, it offers to add one

It only works in `org-mode`.

## Customization

```elisp
;; Tag for bibliographic notes (default: "bib")
(setq citar-vulpea-keyword "bib")

;; Property for storing citation keys (default: "ROAM_REFS" for org-roam compatibility)
(setq citar-vulpea-refs-property "ROAM_REFS")

;; Note title template (default: "${author}, ${title}")
(setq citar-vulpea-note-title-template "${author} (${date}) ${title}")

;; Notes directory (default: nil; uses vulpea-default-notes-directory when unset)
(setq citar-vulpea-notes-directory "references")
```

## Related

- [citar-org-roam](https://github.com/emacs-citar/citar-org-roam) — Similar integration for [org-roam](https://github.com/org-roam/org-roam)
- [citar-denote](https://github.com/pprevos/citar-denote) — Similar integration for [Denote](https://github.com/protesilaos/denote)

## License

GPL-3.0-or-later
