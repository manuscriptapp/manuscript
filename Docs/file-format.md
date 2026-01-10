# Manuscript File Format Specification

Version: 1.0 (Draft)

## Overview

Manuscript uses a folder-based `.manuscript` format. Each project is a directory containing plain Markdown files, JSON metadata, and assets. This format is:

- **Human-readable** — Edit files with any text editor
- **Git-friendly** — Track changes, diff, branch, and merge
- **Portable** — Move projects between devices and apps
- **Extensible** — Add new features without breaking existing projects

## Directory Structure

```
MyNovel.manuscript/
├── project.json                # Project metadata and settings
├── contents/                   # All project content
│   ├── draft/                  # Main manuscript
│   │   ├── folder.json
│   │   ├── 01-chapter-one.md
│   │   ├── 02-chapter-two.md
│   │   └── 03-chapter-three/   # Nested folder (e.g., chapter with scenes)
│   │       ├── folder.json
│   │       ├── 01-scene-one.md
│   │       └── 02-scene-two.md
│   ├── notes/                  # Project notes
│   │   ├── folder.json
│   │   └── characters.md
│   └── research/               # Research materials
│       ├── folder.json
│       └── locations.md
├── snapshots/                  # Version history
│   ├── 2026-01-10T15-30-00.json
│   └── 2026-01-10T16-10-00.json
├── trash/                      # Deleted items (recoverable)
│   └── folder.json
└── assets/                     # Images, PDFs, and other media
    ├── cover.jpg
    └── map.png
```

## File Schemas

### project.json

The root metadata file for the project.

```json
{
  "version": "1.0",
  "title": "My Novel",
  "author": "Jane Writer",
  "created": "2026-01-10T10:00:00Z",
  "modified": "2026-01-10T16:30:00Z",
  "settings": {
    "defaultFont": "Georgia",
    "defaultFontSize": 14,
    "editorTheme": "light",
    "spellCheck": true,
    "autoSave": true,
    "snapshotInterval": 300
  },
  "compile": {
    "title": "My Novel",
    "author": "Jane Writer",
    "format": "pdf",
    "template": "novel"
  },
  "targets": {
    "draft": {
      "wordCount": 80000,
      "deadline": "2026-06-01"
    },
    "session": {
      "wordCount": 1000
    }
  },
  "labels": [
    { "id": "label-1", "name": "Chapter", "color": "#4A90D9" },
    { "id": "label-2", "name": "Scene", "color": "#7ED321" },
    { "id": "label-3", "name": "Idea", "color": "#F5A623" }
  ],
  "statuses": [
    { "id": "status-1", "name": "To Do" },
    { "id": "status-2", "name": "In Progress" },
    { "id": "status-3", "name": "First Draft" },
    { "id": "status-4", "name": "Revised" },
    { "id": "status-5", "name": "Done" }
  ]
}
```

### folder.json

Metadata for each folder in `contents/`. Defines document order, titles, and per-document metadata.

```json
{
  "id": "draft",
  "title": "Draft",
  "type": "draft",
  "created": "2026-01-10T10:00:00Z",
  "modified": "2026-01-10T16:30:00Z",
  "expanded": true,
  "items": [
    {
      "id": "doc-001",
      "file": "01-chapter-one.md",
      "title": "Chapter One",
      "type": "document",
      "label": "label-1",
      "status": "status-3",
      "keywords": ["opening", "hook"],
      "synopsis": "The story begins with our hero waking up.",
      "includeInCompile": true,
      "created": "2026-01-10T10:00:00Z",
      "modified": "2026-01-10T14:20:00Z"
    },
    {
      "id": "doc-002",
      "file": "02-chapter-two.md",
      "title": "Chapter Two",
      "type": "document",
      "label": "label-1",
      "status": "status-2",
      "keywords": ["conflict"],
      "synopsis": "Trouble arrives.",
      "includeInCompile": true,
      "created": "2026-01-10T11:00:00Z",
      "modified": "2026-01-10T16:30:00Z"
    },
    {
      "id": "folder-001",
      "file": "03-chapter-three",
      "title": "Chapter Three",
      "type": "folder",
      "label": "label-1",
      "status": "status-1",
      "synopsis": "The climax.",
      "includeInCompile": true,
      "created": "2026-01-10T12:00:00Z",
      "modified": "2026-01-10T15:00:00Z"
    }
  ]
}
```

### Document Files (*.md)

Documents are standard Markdown files. Optional YAML frontmatter can store document-specific metadata (useful when editing outside Manuscript).

```markdown
---
title: Chapter One
synopsis: The story begins with our hero waking up.
---

# Chapter One

The morning sun crept through the blinds...
```

Note: The frontmatter is optional. Manuscript primarily uses `folder.json` for metadata but will read frontmatter if present (useful for external editing or imports).

### Snapshot Files

Snapshots capture the project state at a point in time. Stored in `snapshots/` with ISO 8601 timestamps.

```json
{
  "version": "1.0",
  "timestamp": "2026-01-10T15:30:00Z",
  "type": "auto",
  "description": "Auto-save",
  "stats": {
    "wordCount": 15234,
    "documentCount": 12
  },
  "changes": [
    {
      "path": "contents/draft/01-chapter-one.md",
      "action": "modified",
      "checksum": "sha256:abc123...",
      "previousChecksum": "sha256:def456..."
    },
    {
      "path": "contents/draft/folder.json",
      "action": "modified",
      "checksum": "sha256:789xyz..."
    }
  ],
  "state": {
    "project.json": "sha256:...",
    "contents/draft/folder.json": "sha256:...",
    "contents/draft/01-chapter-one.md": "sha256:...",
    "contents/draft/02-chapter-two.md": "sha256:..."
  }
}
```

**Snapshot types:**
- `auto` — Automatic save (interval-based)
- `manual` — User-created snapshot ("Save Version")
- `milestone` — Named milestone (e.g., "First Draft Complete")

**Storage options:**
1. **Checksums only** — Store checksums and reconstruct from Git history (if Git enabled)
2. **Full copies** — Store complete file copies in `snapshots/data/` (larger but self-contained)
3. **Diffs** — Store incremental diffs (smaller, requires reconstruction)

## Version Control

### Phase 1: Automatic Snapshots

Built-in version history without external dependencies.

- Snapshots created on save interval (default: 5 minutes)
- Manual snapshots via "Save Version" command
- Simple timeline UI: "Today", "Yesterday", "This Week", "Earlier"
- One-click restore to any previous version
- Compare versions with diff view

### Phase 2: Git Integration (Optional)

For power users who want full version control.

- Initialize Git repo in `.manuscript` folder
- Each snapshot becomes a Git commit
- Branch support for alternate versions
- Push/pull to GitHub or other remotes
- `.gitignore` for assets (optional)

Example `.gitignore`:
```
# Ignore large assets (sync separately)
assets/*.psd
assets/*.mov

# Ignore temporary files
.DS_Store
*.tmp
```

## File Naming Conventions

- **Documents**: `NN-title-slug.md` (e.g., `01-chapter-one.md`)
- **Folders**: `NN-title-slug/` (e.g., `03-chapter-three/`)
- **Snapshots**: ISO 8601 timestamp `.json` (e.g., `2026-01-10T15-30-00.json`)

The numeric prefix (`NN-`) is optional but helps maintain order when browsing in file managers. The actual order is defined in `folder.json`.

## MIME Type and UTI

- **Extension**: `.manuscript`
- **MIME Type**: `application/vnd.manuscript+json`
- **UTI**: `com.manuscript.project`

## Compatibility

### Forward Compatibility

New versions of Manuscript should:
- Ignore unknown fields in JSON files
- Preserve unknown fields when saving
- Handle missing optional fields gracefully

### Backward Compatibility

The `version` field in `project.json` indicates the format version. Manuscript should:
- Warn users when opening projects from newer versions
- Offer to upgrade projects from older versions

## Import/Export

### Import Sources

| Format | Notes |
|--------|-------|
| Scrivener (.scriv) | Map binder to contents/, import snapshots |
| Word (.docx) | Extract text, preserve basic formatting |
| Markdown (.md) | Direct copy, infer structure from headings |
| Plain text (.txt) | Import as single document |

### Export Targets

| Format | Notes |
|--------|-------|
| PDF | Compile with templates |
| Word (.docx) | Preserve formatting |
| EPUB | E-book with chapters |
| HTML | Web-ready output |
| LaTeX | Academic/typesetting |
| Fountain | Screenwriting format |
| Scrivener (.scriv) | Full project export |
| Markdown (.md) | Single file or folder |

## Security Considerations

- No executable code in project files
- Validate all JSON before parsing
- Sanitize file paths to prevent directory traversal
- Assets should be validated (file type, size limits)
