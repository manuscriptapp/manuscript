# Scrivener File Format Specification

**Version:** 1.0
**Last Updated:** January 2026
**Document Type:** Technical Reference

---

## Table of Contents

1. [Overview](#1-overview)
2. [Bundle Structure](#2-bundle-structure)
3. [Complete Directory Structure](#3-complete-directory-structure)
4. [The .scrivx XML Format](#4-the-scrivx-xml-format)
5. [Content Files](#5-content-files)
6. [Version Differences (Scrivener 2 vs 3)](#6-version-differences-scrivener-2-vs-3)
7. [Metadata System](#7-metadata-system)
8. [Snapshots](#8-snapshots)
9. [Research and Media Files](#9-research-and-media-files)
10. [Settings Files](#10-settings-files)
11. [Compile Settings](#11-compile-settings)
12. [QuickLook Preview](#12-quicklook-preview)
13. [Annotations, Comments, and Footnotes](#13-annotations-comments-and-footnotes)
14. [Cross-Platform Compatibility](#14-cross-platform-compatibility)
15. [Mobile/iOS Format](#15-mobileios-format)
16. [Backup and Recovery Files](#16-backup-and-recovery-files)
17. [Format Limitations](#17-format-limitations)
18. [References](#18-references)

---

## 1. Overview

### 1.1 What is the Scrivener Format?

Scrivener is a writing application developed by Literature & Latte that uses a proprietary project format with the `.scriv` extension. Unlike traditional word processors that store documents as single monolithic files, Scrivener saves projects as **package bundles** (directories) containing multiple files and subdirectories.

### 1.2 Design Philosophy

The Scrivener format was designed with several key principles:

- **Modular Storage**: Each document is stored as a separate file, enabling incremental saves and reducing corruption risk
- **Rich Metadata**: Extensive support for organizational metadata (labels, statuses, keywords)
- **Cross-Platform Compatibility**: The same format works across macOS, Windows, and iOS
- **Human-Readable Index**: The main `.scrivx` file is XML, making structure inspection possible
- **Non-Destructive Workflow**: Original content preserved through snapshots and version tracking

### 1.3 Format History

| Version | Platform | Released | Key Changes |
|---------|----------|----------|-------------|
| 1.x | macOS | 2007 | Binary plist format, `.scrivproj` extension |
| 2.x | macOS/Windows | 2010 | XML-based `.scrivx`, RTF content in `Files/Docs/` |
| 3.x | macOS/Windows/iOS | 2017 | UUID-based storage in `Files/Data/`, enhanced metadata |

### 1.4 File Extension Registry

| Extension | Type | Description |
|-----------|------|-------------|
| `.scriv` | Directory (Package) | Complete Scrivener project bundle |
| `.scrivx` | XML File | Project index and structure definition |
| `.scrivproj` | Binary plist | Legacy Scrivener 1.x project file (macOS only) |

---

## 2. Bundle Structure

### 2.1 macOS Package Format

On macOS, Scrivener projects appear as single files in Finder due to the **Document Package** format. This is a system feature where directories with specific extensions are treated as opaque files by the operating system.

**Technical Details:**
- The `.scriv` extension is registered with Launch Services
- Finder displays the package with a custom icon
- Double-clicking opens the project in Scrivener
- Users can right-click and select "Show Package Contents" to view internal structure

### 2.2 Windows Folder Format

On Windows, `.scriv` projects appear as regular folders. Users navigate into the folder to find the `.scrivx` file (displayed with a Scrivener icon). This file serves as the entry point for opening the project.

**Important:** When transferring projects from Windows, always copy the **entire `.scriv` folder**, not just the `.scrivx` file inside.

### 2.3 Identifying a Valid Project

A valid Scrivener project must contain:

1. A `.scrivx` XML file (project index)
2. A `Files/` directory (content storage)
3. At minimum, one of:
   - `Files/Docs/` (Scrivener 2.x format)
   - `Files/Data/` (Scrivener 3.x format)

---

## 3. Complete Directory Structure

### 3.1 Scrivener 3.x Structure

```
MyProject.scriv/
├── MyProject.scrivx                    # Main XML index file
├── Files/
│   ├── Data/                           # Document content (UUID-organized)
│   │   ├── 921B4A08-54C0-4B69-94FD-428F56FDAB89/
│   │   │   ├── content.rtf             # Main document text
│   │   │   ├── notes.rtf               # Document notes
│   │   │   └── synopsis.txt            # Document synopsis
│   │   ├── A3F2E891-7C4D-4E8A-B123-456789ABCDEF/
│   │   │   └── content.rtf
│   │   └── docs.checksum               # Integrity verification
│   ├── binder.autosave                 # Auto-save state
│   ├── binder.backup                   # Binder backup
│   ├── search.indexes                  # Search index cache
│   ├── styles.xml                      # Document styles definitions
│   ├── version.txt                     # Format version identifier
│   └── writing.history                 # Writing session history
├── Settings/
│   ├── recents.txt                     # Recently accessed documents
│   ├── ui-common.xml                   # Shared UI state
│   └── ui.ini                          # Platform-specific UI settings
├── Snapshots/                          # Document version snapshots
│   ├── 921B4A08-54C0-4B69-94FD-428F56FDAB89/
│   │   ├── 2025-01-15-12-30-00.rtf     # Timestamped snapshot
│   │   └── snapshots.xml               # Snapshot metadata
│   └── ...
└── QuickLook/
    ├── Preview.html                    # macOS Quick Look preview
    └── Thumbnail.jpg                   # Project thumbnail
```

### 3.2 Scrivener 2.x Structure

```
MyProject.scriv/
├── project.scrivx                      # Main XML index file
├── Files/
│   ├── Docs/                           # Document content (ID-organized)
│   │   ├── 1.rtf                       # Document ID 1 content
│   │   ├── 1_notes.rtf                 # Document ID 1 notes
│   │   ├── 1_synopsis.txt              # Document ID 1 synopsis
│   │   ├── 2.rtf
│   │   ├── 2_notes.rtf
│   │   └── ...
│   ├── binder.autosave
│   ├── binder.backup
│   └── search.indexes
├── Settings/
│   └── compile.xml                     # Compile settings
├── Snapshots/
│   ├── 1/
│   │   ├── 2024-01-01-10-00-00.rtf
│   │   └── snapshot.xml
│   └── ...
└── QuickLook/
    └── Preview.html
```

### 3.3 File Purpose Reference

| File/Directory | Purpose |
|----------------|---------|
| `*.scrivx` | XML index containing binder structure and all metadata |
| `Files/Data/` | Scrivener 3 content storage (UUID folders) |
| `Files/Docs/` | Scrivener 2 content storage (numeric ID files) |
| `binder.autosave` | Temporary autosave state (internal use) |
| `binder.backup` | Binder structure backup (internal use) |
| `search.indexes` | Full-text search index cache |
| `styles.xml` | Custom paragraph and character style definitions |
| `version.txt` | Format version for compatibility detection |
| `writing.history` | Word count and writing session tracking |
| `Settings/` | UI state and preferences |
| `Snapshots/` | Document version history |
| `QuickLook/` | macOS preview generation files |

---

## 4. The .scrivx XML Format

### 4.1 Overview

The `.scrivx` file is the heart of a Scrivener project. It is an XML document that defines:

- Project title and metadata
- Complete binder hierarchy (folders and documents)
- Labels, statuses, and their colors
- Custom metadata field definitions
- Project-level targets and settings
- Bookmarks and collections

### 4.2 Root Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject
    Identifier="PROJECT-UUID-HERE"
    Version="2.0"
    Creator="Scrivener 3"
    Device="MacBookPro"
    Author="AuthorName"
    Modified="2025-01-15 14:30:00 -0500"
    ModID="MODIFICATION-UUID">

    <Binder>...</Binder>
    <Collections>...</Collections>
    <LabelSettings>...</LabelSettings>
    <StatusSettings>...</StatusSettings>
    <CustomMetaDataSettings>...</CustomMetaDataSettings>
    <ProjectBookmarks>...</ProjectBookmarks>
    <ProjectTargets>...</ProjectTargets>
    <RecentWritingHistory>...</RecentWritingHistory>
    <PrintSettings>...</PrintSettings>
    <Favorites>...</Favorites>

</ScrivenerProject>
```

### 4.3 Binder Structure

The `<Binder>` element contains the complete document hierarchy:

```xml
<Binder>
    <BinderItem
        UUID="DraftFolder-UUID"
        Type="DraftFolder"
        Created="2025-01-01 10:00:00 -0500"
        Modified="2025-01-15 14:30:00 -0500">
        <Title>Manuscript</Title>
        <MetaData>
            <IncludeInCompile>Yes</IncludeInCompile>
        </MetaData>
        <Children>
            <BinderItem
                UUID="921B4A08-54C0-4B69-94FD-428F56FDAB89"
                Type="Text"
                Created="2025-01-02 09:00:00 -0500"
                Modified="2025-01-10 16:45:00 -0500">
                <Title>Chapter One</Title>
                <MetaData>
                    <LabelID>1</LabelID>
                    <StatusID>2</StatusID>
                    <IncludeInCompile>Yes</IncludeInCompile>
                    <Target Type="Words">2500</Target>
                    <CustomMetaData>
                        <MetaDataItem>
                            <FieldID>POVCharacter</FieldID>
                            <Value>John</Value>
                        </MetaDataItem>
                    </CustomMetaData>
                </MetaData>
                <Synopsis>The story begins in a small coastal town.</Synopsis>
                <TextSettings>
                    <TextSelection>0,0</TextSelection>
                </TextSettings>
                <Children>
                    <!-- Nested scenes -->
                </Children>
            </BinderItem>

            <BinderItem UUID="..." Type="Folder">
                <Title>Chapter Two</Title>
                <Children>...</Children>
            </BinderItem>
        </Children>
    </BinderItem>

    <BinderItem UUID="ResearchFolder-UUID" Type="ResearchFolder">
        <Title>Research</Title>
        <Children>...</Children>
    </BinderItem>

    <BinderItem UUID="TrashFolder-UUID" Type="TrashFolder">
        <Title>Trash</Title>
        <Children>...</Children>
    </BinderItem>
</Binder>
```

### 4.4 BinderItem Types

| Type | Description | Special Behavior |
|------|-------------|------------------|
| `DraftFolder` | Main manuscript/draft container | Only text items allowed; compiled by default |
| `ResearchFolder` | Research materials container | Supports all media types |
| `TrashFolder` | Deleted items | Items here excluded from compile |
| `Folder` | User-created folder | Can contain text and subfolders |
| `Text` | Text document | Primary writing unit |
| `PDF` | PDF document | Stored in research |
| `Image` | Image file | Stored in research |
| `WebPage` | Archived web page | Usually .webarchive or HTML |
| `Other` | Other media types | Video, audio, etc. |

### 4.5 BinderItem Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `UUID` | String | Yes (v3) | Unique identifier (matches content folder name) |
| `ID` | Integer | Yes (v2) | Numeric identifier (matches content file name) |
| `Type` | String | Yes | Item type (see table above) |
| `Created` | DateTime | No | Creation timestamp |
| `Modified` | DateTime | No | Last modification timestamp |

### 4.6 MetaData Elements

```xml
<MetaData>
    <LabelID>1</LabelID>                    <!-- Reference to label -->
    <StatusID>2</StatusID>                  <!-- Reference to status -->
    <IncludeInCompile>Yes</IncludeInCompile> <!-- Boolean: Yes/No -->
    <Target Type="Words">2500</Target>      <!-- Word count target -->
    <Target Type="Characters">15000</Target> <!-- Alternative: character target -->
    <NotesSelection>0,0</NotesSelection>    <!-- Notes cursor position -->
    <CustomMetaData>
        <MetaDataItem>
            <FieldID>FieldName</FieldID>
            <Value>Field Value</Value>
        </MetaDataItem>
    </CustomMetaData>
</MetaData>
```

### 4.7 Label Settings

```xml
<LabelSettings>
    <Title>Label</Title>                    <!-- Column header name -->
    <DefaultLabelID>-1</DefaultLabelID>     <!-- Default for new items -->
    <Labels>
        <Label ID="-1" Color="1.0 1.0 1.0">No Label</Label>
        <Label ID="0" Color="0.993 0.227 0.172">Red</Label>
        <Label ID="1" Color="0.992 0.557 0.227">Orange</Label>
        <Label ID="2" Color="0.996 0.859 0.180">Yellow</Label>
        <Label ID="3" Color="0.539 0.906 0.243">Green</Label>
        <Label ID="4" Color="0.357 0.604 0.969">Blue</Label>
        <Label ID="5" Color="0.702 0.416 0.906">Purple</Label>
    </Labels>
</LabelSettings>
```

**Color Format:** RGB values as space-separated floats (0.0-1.0)

### 4.8 Status Settings

```xml
<StatusSettings>
    <Title>Status</Title>
    <DefaultStatusID>-1</DefaultStatusID>
    <StatusItems>
        <Status ID="-1">No Status</Status>
        <Status ID="0">To Do</Status>
        <Status ID="1">In Progress</Status>
        <Status ID="2">First Draft</Status>
        <Status ID="3">Revised Draft</Status>
        <Status ID="4">Final Draft</Status>
        <Status ID="5">Done</Status>
    </StatusItems>
</StatusSettings>
```

### 4.9 Custom Metadata Settings

```xml
<CustomMetaDataSettings>
    <MetaDataField ID="POVCharacter" Type="Text">
        <Title>POV Character</Title>
        <DefaultValue></DefaultValue>
        <ColumnWidth>100</ColumnWidth>
        <TextColor>0.0 0.0 0.0</TextColor>
    </MetaDataField>
    <MetaDataField ID="NeedsReview" Type="Checkbox">
        <Title>Needs Review</Title>
        <DefaultValue>No</DefaultValue>
    </MetaDataField>
    <MetaDataField ID="SceneType" Type="List">
        <Title>Scene Type</Title>
        <ListOptions>
            <Option>Action</Option>
            <Option>Dialogue</Option>
            <Option>Description</Option>
            <Option>Flashback</Option>
        </ListOptions>
    </MetaDataField>
    <MetaDataField ID="Deadline" Type="Date">
        <Title>Deadline</Title>
        <DateFormat>MMM dd, yyyy</DateFormat>
    </MetaDataField>
</CustomMetaDataSettings>
```

**Custom Metadata Types (Scrivener 3):**
- `Text` - Free-form text field
- `Checkbox` - Boolean (Yes/No)
- `List` - Dropdown selection
- `Date` - Date value

### 4.10 Project Targets

```xml
<ProjectTargets
    Notify="Yes"
    ShowTargets="Yes"
    IgnoreFrontMatter="Yes"
    IgnoreBackMatter="Yes"
    DeadlineDate="2025-06-01 00:00:00 -0500"
    DeadlineCountType="Writing Days">
    <DraftTarget
        Type="Words"
        CurrentCompileGroupOnly="No"
        Deadline="2025-06-01">80000</DraftTarget>
    <SessionTarget
        Type="Words"
        CountDraftOnly="Yes"
        ResetType="Midnight"
        ResetTime="00:00"
        CanExceedTarget="Yes"
        AllowNegatives="No">1000</SessionTarget>
</ProjectTargets>
```

### 4.11 Collections

```xml
<Collections>
    <Collection Type="Binder" ID="Collection-UUID-1">
        <Title>Main Characters</Title>
        <SearchSettings>
            <SearchScope>All</SearchScope>
        </SearchSettings>
        <Items>
            <ItemRef>Document-UUID-1</ItemRef>
            <ItemRef>Document-UUID-2</ItemRef>
            <ItemRef>Document-UUID-3</ItemRef>
        </Items>
        <Color>0.5 0.7 1.0</Color>
    </Collection>
    <Collection Type="Search" ID="Collection-UUID-2">
        <Title>Unfinished Scenes</Title>
        <SearchSettings>
            <SearchString>@status:To Do</SearchString>
        </SearchSettings>
    </Collection>
</Collections>
```

### 4.12 Project Bookmarks

```xml
<ProjectBookmarks>
    <Bookmark>Document-UUID-1</Bookmark>
    <Bookmark>Document-UUID-2</Bookmark>
    <Bookmark Type="External">file:///path/to/external/file.pdf</Bookmark>
    <Bookmark Type="URL">https://example.com/reference</Bookmark>
</ProjectBookmarks>
```

---

## 5. Content Files

### 5.1 RTF Document Format

Scrivener stores document content in **Rich Text Format (RTF)**, an open standard that preserves formatting while remaining readable by many applications.

**File Locations:**

| Version | Content Path | Notes Path | Synopsis Path |
|---------|--------------|------------|---------------|
| Scrivener 3 | `Files/Data/{UUID}/content.rtf` | `Files/Data/{UUID}/notes.rtf` | `Files/Data/{UUID}/synopsis.txt` |
| Scrivener 2 | `Files/Docs/{ID}.rtf` | `Files/Docs/{ID}_notes.rtf` | `Files/Docs/{ID}_synopsis.txt` |

### 5.2 RTF Features Supported

Scrivener's RTF files support:

- **Basic Formatting:** Bold, italic, underline, strikethrough
- **Paragraph Styles:** Alignment, indentation, spacing
- **Character Styles:** Font family, size, color
- **Lists:** Bulleted and numbered lists
- **Links:** Hyperlinks to URLs and internal documents
- **Images:** Embedded inline images
- **Tables:** Basic table support
- **Footnotes/Endnotes:** Inline and inspector-linked
- **Comments:** Inline annotations and linked comments

### 5.3 RTF Structure Example

```rtf
{\rtf1\ansi\ansicpg1252\cocoartf2761\cocoasubrtf600
{\fonttbl\f0\fswiss\fcharset0 Helvetica;\f1\fnil\fcharset0 Georgia;}
{\colortbl;\red255\green255\blue255;\red0\green0\blue0;}
{\*\expandedcolortbl;;\cssrgb\c0\c0\c0;}
\paperw11900\paperh16840\margl1440\margr1440\vieww10800\viewh8400
\pard\tx566\tx1133\pardirnatural\partightenfactor0

\f1\fs28 \cf2 Chapter One\
\
\f0\fs24 It was a dark and stormy night. The {\b wind howled} through the
trees as {\i Sarah} made her way home.\
\
{\field{\*\fldinst{HYPERLINK "scrivlnk://Document-UUID-HERE"}}{\fldrslt Internal Link}}\
}
```

### 5.4 Synopsis Files

Synopsis files are plain text (UTF-8 encoded) containing brief summaries:

```
synopsis.txt content:
Sarah arrives at the old mansion during a thunderstorm, unaware of what awaits her inside.
```

### 5.5 Notes Files

Notes are stored as RTF files with the same formatting capabilities as content files, allowing rich text notes for each document.

### 5.6 Scrivener Links

Internal document links use a special URL scheme:

```
scrivlnk://UUID-OF-TARGET-DOCUMENT
```

These are embedded in RTF as hyperlink fields and resolved by Scrivener at runtime.

---

## 6. Version Differences (Scrivener 2 vs 3)

### 6.1 Major Structural Changes

| Aspect | Scrivener 2.x | Scrivener 3.x |
|--------|---------------|---------------|
| Content Storage | `Files/Docs/{ID}.rtf` | `Files/Data/{UUID}/content.rtf` |
| Identifier Type | Numeric integers | UUID strings |
| Notes Location | `{ID}_notes.rtf` in Docs | `notes.rtf` in UUID folder |
| Synopsis Location | `{ID}_synopsis.txt` in Docs | `synopsis.txt` in UUID folder |
| Styles | Limited | Full styles system (`styles.xml`) |
| Custom Metadata | Text only | Text, Checkbox, List, Date |
| Collections | Basic | Enhanced with saved searches |

### 6.2 Detecting Version

```python
# Python pseudocode for version detection
def detect_scrivener_version(project_path):
    data_path = os.path.join(project_path, "Files", "Data")
    docs_path = os.path.join(project_path, "Files", "Docs")

    if os.path.exists(data_path):
        return "v3"
    elif os.path.exists(docs_path):
        return "v2"
    else:
        return "unknown"
```

### 6.3 Format Conversion

- **v2 → v3:** Opening a Scrivener 2 project in Scrivener 3 triggers automatic conversion
- **v3 → v2:** Scrivener 3 can export to Scrivener 2 format via File > Export > As Scrivener 2 Project
- **Warning:** Converted v3 projects cannot be opened in Scrivener 2 without explicit export

### 6.4 Windows Scrivener Compatibility

| Windows Scrivener | Compatible Mac Format |
|-------------------|----------------------|
| Windows 1.9.x | Mac Scrivener 2.x |
| Windows 3.x | Mac Scrivener 3.x |

---

## 7. Metadata System

### 7.1 Overview

Scrivener provides a comprehensive metadata system for organizing and tracking documents:

1. **Labels** - Color-coded categories (one per document)
2. **Status** - Progress markers (one per document)
3. **Keywords** - Tags (multiple per document)
4. **Custom Metadata** - User-defined fields

### 7.2 Labels

Labels provide visual markers throughout Scrivener's interface:

**Visibility Options:**
- Binder icons
- Corkboard card backgrounds
- Outliner columns
- Index card pins

**XML Storage:**
```xml
<Label ID="0" Color="0.993 0.227 0.172">Chapter</Label>
```

**Default Label Set:**
- No Label (white/transparent)
- Red, Orange, Yellow, Green, Blue, Purple

### 7.3 Status

Status values indicate document progress:

**Display Options:**
- Corkboard stamps (watermark text)
- Outliner columns
- Inspector panel

**Typical Status Values:**
- No Status
- To Do
- In Progress
- First Draft
- Revised Draft
- Final Draft
- Done

### 7.4 Keywords

Keywords allow multiple tags per document:

**Storage in .scrivx:**
```xml
<Keywords>
    <Keyword ID="Keyword-UUID-1">
        <Title>John (protagonist)</Title>
        <Color>0.5 0.7 1.0</Color>
    </Keyword>
    <Keyword ID="Keyword-UUID-2">
        <Title>Subplot A</Title>
        <Parent>Keyword-UUID-Parent</Parent>
    </Keyword>
</Keywords>
```

**Assignment to Documents:**
```xml
<BinderItem UUID="...">
    <MetaData>
        <Keywords>
            <KeywordRef>Keyword-UUID-1</KeywordRef>
            <KeywordRef>Keyword-UUID-2</KeywordRef>
        </Keywords>
    </MetaData>
</BinderItem>
```

### 7.5 Custom Metadata Types

**Scrivener 3 Custom Field Types:**

| Type | Description | XML Example |
|------|-------------|-------------|
| Text | Free-form text | `<Value>John Smith</Value>` |
| Checkbox | Boolean value | `<Value>Yes</Value>` or `<Value>No</Value>` |
| List | Dropdown selection | `<Value>Action</Value>` |
| Date | Date value | `<Value>2025-01-15</Value>` |

---

## 8. Snapshots

### 8.1 Purpose

Snapshots are frozen-in-time copies of individual documents, providing version history at the document level.

### 8.2 Snapshot Storage

**Scrivener 3:**
```
Snapshots/
├── 921B4A08-54C0-4B69-94FD-428F56FDAB89/
│   ├── 2025-01-15-14-30-00.rtf       # Timestamped content
│   ├── 2025-01-10-09-15-00.rtf
│   └── snapshots.xml                  # Metadata
```

**Scrivener 2:**
```
Snapshots/
├── 1/                                 # Document ID
│   ├── 2025-01-15-14-30-00.rtf
│   └── snapshot.xml
```

### 8.3 Snapshot Metadata (snapshots.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Snapshots>
    <Snapshot>
        <Date>2025-01-15 14:30:00 -0500</Date>
        <Title>Before major revision</Title>
        <File>2025-01-15-14-30-00.rtf</File>
    </Snapshot>
    <Snapshot>
        <Date>2025-01-10 09:15:00 -0500</Date>
        <Title>Original draft</Title>
        <File>2025-01-10-09-15-00.rtf</File>
    </Snapshot>
</Snapshots>
```

### 8.4 Snapshot Behavior

- Snapshots are stored with their parent document
- Deleting a document deletes all its snapshots
- Snapshots can be titled for identification
- Users can compare snapshots or roll back to previous versions

---

## 9. Research and Media Files

### 9.1 Research Folder Purpose

The Research folder (identified by `Type="ResearchFolder"` in the binder) can contain:

- Text documents
- PDF files
- Images (JPEG, PNG, TIFF, etc.)
- Web archives (.webarchive)
- Video files
- Audio files
- Any other file type

### 9.2 Media Storage

Non-text files are stored in their native format within the content directories:

**Scrivener 3:**
```
Files/Data/MediaDoc-UUID/
├── content.pdf           # For PDF items
├── content.png           # For image items
├── content.webarchive    # For web pages
└── content.mov           # For video items
```

### 9.3 Draft Folder Restrictions

The Draft/Manuscript folder (`Type="DraftFolder"`) **only accepts text documents**. Attempting to add media files to the Draft folder results in an error.

### 9.4 File Size Considerations

Large media files increase project size significantly. Best practices:

- Keep high-resolution images in external folders
- Link to large video/audio files rather than importing
- Use web archives sparingly

---

## 10. Settings Files

### 10.1 Settings Directory Contents

```
Settings/
├── recents.txt           # Recently accessed documents (line-separated UUIDs)
├── ui-common.xml         # Cross-platform UI state
└── ui.ini                # Platform-specific settings
```

### 10.2 recents.txt Format

```
921B4A08-54C0-4B69-94FD-428F56FDAB89
A3F2E891-7C4D-4E8A-B123-456789ABCDEF
B5C6D7E8-F901-2345-6789-ABCDEF012345
```

### 10.3 UI State (ui-common.xml)

Stores editor state, split views, and navigation history:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<UISettings>
    <Editors>
        <Editor Type="Primary">
            <Document>921B4A08-54C0-4B69-94FD-428F56FDAB89</Document>
            <Selection>150,0</Selection>
            <ScrollPosition>0.25</ScrollPosition>
        </Editor>
        <Editor Type="Secondary">
            <Document>A3F2E891-7C4D-4E8A-B123-456789ABCDEF</Document>
        </Editor>
    </Editors>
    <InspectorVisible>Yes</InspectorVisible>
    <BinderVisible>Yes</BinderVisible>
    <OutlinerColumns>
        <Column>Title</Column>
        <Column>Label</Column>
        <Column>Status</Column>
        <Column>WordCount</Column>
    </OutlinerColumns>
</UISettings>
```

---

## 11. Compile Settings

### 11.1 Overview

Compile settings control how the project is exported to various formats (PDF, Word, ePub, etc.).

### 11.2 Storage Location

Compile settings may be stored in:
- `Settings/compile.xml` (Scrivener 2)
- Embedded in the `.scrivx` file (Scrivener 3)
- System-level compile presets (shared across projects)

### 11.3 Compile Configuration Elements

```xml
<CompileSettings>
    <Format>PDF</Format>
    <SectionLayouts>
        <SectionLayout Type="Heading">
            <TitlePrefix>Chapter </TitlePrefix>
            <TitleSuffix></TitleSuffix>
            <TitleCase>Uppercase</TitleCase>
        </SectionLayout>
    </SectionLayouts>
    <FrontMatter>
        <Document>TitlePage-UUID</Document>
        <Document>Copyright-UUID</Document>
    </FrontMatter>
    <BackMatter>
        <Document>Appendix-UUID</Document>
    </BackMatter>
    <RemoveAnnotations>Yes</RemoveAnnotations>
    <RemoveComments>Yes</RemoveComments>
</CompileSettings>
```

---

## 12. QuickLook Preview

### 12.1 Purpose

On macOS, Quick Look allows users to preview files without opening them. Scrivener generates preview files for this feature.

### 12.2 QuickLook Directory

```
QuickLook/
├── Preview.html          # HTML preview of project content
├── Thumbnail.jpg         # Project thumbnail image
└── (generated files)
```

### 12.3 Preview.html Structure

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Project Title</title>
    <style>
        body { font-family: Georgia, serif; margin: 2em; }
        h1 { color: #333; }
        .document { margin-bottom: 2em; }
    </style>
</head>
<body>
    <h1>Project Title</h1>
    <div class="document">
        <h2>Chapter One</h2>
        <p>Opening paragraphs of content...</p>
    </div>
</body>
</html>
```

---

## 13. Annotations, Comments, and Footnotes

### 13.1 Inline Annotations

Inline annotations appear directly in the text with distinctive formatting (colored background, border). They are stored within the RTF content:

```rtf
{\*\Scrv_annot\Scrv_annot_bgcolor_red This is an inline annotation.}
```

### 13.2 Inspector Comments

Comments are linked to text ranges but stored separately in the Inspector. They appear as highlights in the text with content in the sidebar:

```rtf
{\*\Scrv_comment {\Scrv_comment_id UUID-HERE}Highlighted text}
```

Comment content is stored in the document's metadata or a separate comments structure.

### 13.3 Footnotes and Endnotes

Scrivener supports two footnote styles:

**Inline Footnotes:**
```rtf
Text with footnote\footnote{Footnote content here.} continuing.
```

**Inspector Footnotes:**
Linked like comments but rendered as footnotes during compile.

### 13.4 Export Behavior

| Annotation Type | RTF Export | Compile (Final) |
|-----------------|------------|-----------------|
| Inline Annotations | Preserved | Optionally removed |
| Comments | Converted to RTF comments | Optionally removed |
| Inspector Footnotes | Converted to inline | Rendered as footnotes/endnotes |

---

## 14. Cross-Platform Compatibility

### 14.1 Format Portability

The Scrivener project format is designed for cross-platform compatibility:

- Same `.scriv` bundle works on macOS, Windows, and iOS
- No conversion required when moving between platforms
- XML and RTF are platform-independent formats

### 14.2 Platform-Specific Considerations

**Path Separators:**
- macOS/iOS: Forward slash (`/`)
- Windows: Backslash (`\`) but Scrivener normalizes to forward slashes internally

**Font Handling:**
Fonts may not be available across platforms. Scrivener attempts to:
1. Use the specified font if available
2. Fall back to a similar system font
3. Default to Helvetica/Arial if no match found

**Line Endings:**
RTF files use platform-appropriate line endings, but Scrivener handles conversion automatically.

### 14.3 Transfer Best Practices

1. Always transfer the complete `.scriv` folder/package
2. Use Dropbox for reliable sync (recommended by Literature & Latte)
3. Close project completely before transfer
4. Verify project integrity after transfer

---

## 15. Mobile/iOS Format

### 15.1 iOS Project Format

Scrivener for iOS uses the same `.scriv` format as desktop versions, ensuring seamless synchronization.

### 15.2 Sync Methods

**Dropbox Sync (Recommended):**
- Default folder: `Dropbox/Apps/Scrivener/`
- Customizable location within Dropbox
- Requires Scrivener 2.8+ (Mac) or 1.9.5+ (Windows)

**iTunes/Finder File Sharing:**
- Manual copy via USB
- Projects copied to/from device storage

### 15.3 Mobile-Specific Files

During mobile sync, Scrivener creates a "mobile area" within the project to sequester changes made on iOS:

```
Files/
├── Data/
├── Mobile/                 # iOS-specific changes (temporary)
│   ├── pending_changes.xml
│   └── sync_state.xml
```

### 15.4 Why Not iCloud?

Literature & Latte does not recommend iCloud Drive because:
- iCloud may not download all files in a package
- Partial downloads can corrupt projects
- Scrivener's package format requires all files to be present

---

## 16. Backup and Recovery Files

### 16.1 Autosave System

Scrivener autosaves every 2 seconds (configurable) to prevent data loss.

**Autosave Files:**
- `Files/binder.autosave` - Temporary binder state
- `Files/binder.backup` - Binder backup

**Warning:** These files are for internal use. Do not open them directly.

### 16.2 Automatic Backups

Scrivener creates automatic backups (configurable):
- On project close
- Before sync
- On manual save (optional)

Default backup location:
- macOS: `~/Library/Application Support/Scrivener 3/Backups/`
- Windows: `%LOCALAPPDATA%\Scrivener\Backups\`

### 16.3 Recovery Scenarios

**Corrupted .scrivx:**
1. Check for `binder.backup` in `Files/`
2. Restore from automatic backup
3. Individual RTF files remain accessible

**Missing Content:**
1. Navigate to `Files/Data/` or `Files/Docs/`
2. RTF files can be opened in any RTF-compatible editor
3. Reconstruct project manually if necessary

### 16.4 Integrity Verification

Scrivener 3 includes `docs.checksum` for integrity verification:

```
921B4A08-54C0-4B69-94FD-428F56FDAB89:a1b2c3d4e5f6...
A3F2E891-7C4D-4E8A-B123-456789ABCDEF:f6e5d4c3b2a1...
```

---

## 17. Format Limitations

### 17.1 Known Limitations

| Limitation | Description |
|------------|-------------|
| No official specification | Format is proprietary; documentation derived from reverse engineering |
| RTF limitations | Some advanced formatting may not survive export/import cycles |
| Large project performance | Projects with thousands of documents may experience slowdowns |
| Media embedding | Large media files significantly increase project size |
| Sync conflicts | Simultaneous editing on multiple devices can cause issues |

### 17.2 Unsupported Features for Import/Export

Features that may not transfer when importing/exporting:

- Scrivener-specific links (internal document references)
- Collections (saved document groups)
- Compile format presets
- Project-specific styles (unless exported)
- Writing history and statistics

### 17.3 Third-Party Tool Support

The open nature of RTF content and XML structure allows limited third-party tool development:

- Content extraction from RTF files
- Binder structure reading from `.scrivx`
- Metadata parsing
- Search indexing

However, full round-trip editing requires careful preservation of Scrivener-specific elements.

---

## 18. References

### 18.1 Official Resources

- [Literature & Latte - Scrivener](https://www.literatureandlatte.com/scrivener/overview)
- [Scrivener Manual (PDF)](https://www.literatureandlatte.com/learn-and-support/user-guides)
- [Literature & Latte Support Knowledge Base](https://scrivener.tenderapp.com/help/kb)
- [Literature & Latte Forums](https://forum.literatureandlatte.com/)

### 18.2 Technical References

- [How a Scrivener Project is Structured - Literature & Latte Forums](https://forum.literatureandlatte.com/t/how-a-scrivener-project-is-structured/9717)
- [Scrivener - Just Solve the File Format Problem](http://justsolve.archiveteam.org/wiki/Scrivener)
- [Coding XML Formats in Cocoa - Literature & Latte Blog](https://www.literatureandlatte.com/blog/coding-xml-formats-in-cocoa)
- [Cross-Platform Compatibility - Knowledge Base](https://scrivener.tenderapp.com/help/kb/features-and-usage/cross-platform-compatibility)

### 18.3 Feature Documentation

- [Use Bookmarks in Scrivener Projects](https://www.literatureandlatte.com/blog/use-bookmarks-in-scrivener-projects-to-link-to-internal-and-external-files)
- [Understanding Scrivener's Project Settings](https://www.literatureandlatte.com/blog/understanding-scriveners-project-settings)
- [Use Annotations, Comments, & Footnotes](https://www.literatureandlatte.com/blog/use-annotations-comments-footnotes-in-your-scrivener-projects)
- [How to Back Up Your Scrivener Projects](https://www.literatureandlatte.com/blog/how-to-back-up-your-scrivener-projects)
- [Scrivener for iOS: Syncing](https://www.literatureandlatte.com/blog/scrivener-for-ios-syncing)
- [The Three Root Folders](https://scrivener.tenderapp.com/help/kb/features-and-usage/the-three-root-folders)

### 18.4 Third-Party Resources

- [Scrivener Classes](https://scrivenerclasses.com/)
- [Scrivener Virgin](https://www.scrivenervirgin.com/)
- [Writers In The Storm - Scrivener Tutorials](https://writersinthestormblog.com/tag/scrivener/)

---

## Appendix A: Complete XML Schema Reference

### A.1 BinderItem Element Schema

```
BinderItem
├── @UUID (string, required in v3)
├── @ID (integer, required in v2)
├── @Type (enum: DraftFolder|ResearchFolder|TrashFolder|Folder|Text|PDF|Image|WebPage|Other)
├── @Created (datetime, optional)
├── @Modified (datetime, optional)
├── Title (string)
├── MetaData
│   ├── LabelID (integer, optional)
│   ├── StatusID (integer, optional)
│   ├── IncludeInCompile (Yes|No)
│   ├── Target
│   │   ├── @Type (Words|Characters)
│   │   └── (integer value)
│   ├── Keywords
│   │   └── KeywordRef* (string UUID)
│   └── CustomMetaData
│       └── MetaDataItem*
│           ├── FieldID (string)
│           └── Value (string)
├── Synopsis (string, optional)
├── TextSettings
│   ├── TextSelection (string "start,length")
│   └── (other editor state)
└── Children
    └── BinderItem* (recursive)
```

### A.2 Color Value Format

Colors are expressed as space-separated RGB float values:

```
Format: "R G B" where R, G, B are floats from 0.0 to 1.0

Examples:
- Red:    "1.0 0.0 0.0"
- Green:  "0.0 1.0 0.0"
- Blue:   "0.0 0.0 1.0"
- White:  "1.0 1.0 1.0"
- Black:  "0.0 0.0 0.0"
- Orange: "1.0 0.5 0.0"
- Purple: "0.5 0.0 1.0"
```

### A.3 DateTime Format

Timestamps use ISO 8601-like format with timezone:

```
Format: "YYYY-MM-DD HH:MM:SS ZZZZ"

Example: "2025-01-15 14:30:00 -0500"

Components:
- YYYY: 4-digit year
- MM: 2-digit month (01-12)
- DD: 2-digit day (01-31)
- HH: 2-digit hour (00-23)
- MM: 2-digit minute (00-59)
- SS: 2-digit second (00-59)
- ZZZZ: Timezone offset (e.g., -0500 for EST)
```

---

## Appendix B: RTF Control Words Reference

### B.1 Formatting Control Words

| Control Word | Effect |
|--------------|--------|
| `\b` | Bold on |
| `\b0` | Bold off |
| `\i` | Italic on |
| `\i0` | Italic off |
| `\ul` | Underline on |
| `\ul0` | Underline off |
| `\strike` | Strikethrough on |
| `\strike0` | Strikethrough off |
| `\super` | Superscript |
| `\sub` | Subscript |
| `\nosupersub` | Normal position |

### B.2 Paragraph Control Words

| Control Word | Effect |
|--------------|--------|
| `\pard` | Reset paragraph defaults |
| `\par` | New paragraph |
| `\line` | Line break |
| `\qc` | Center align |
| `\qr` | Right align |
| `\ql` | Left align |
| `\qj` | Justify |
| `\fi###` | First line indent (twips) |
| `\li###` | Left indent (twips) |

### B.3 Scrivener-Specific Extensions

| Control Word | Purpose |
|--------------|---------|
| `\Scrv_annot` | Inline annotation marker |
| `\Scrv_comment` | Comment marker |
| `\Scrv_link` | Internal document link |
| `\Scrv_footnote` | Inspector footnote |

---

## Appendix C: Conversion Reference

### C.1 Scrivener to Markdown Mapping

| Scrivener Element | Markdown Equivalent |
|-------------------|---------------------|
| Bold | `**text**` |
| Italic | `*text*` |
| Bold+Italic | `***text***` |
| Strikethrough | `~~text~~` |
| Hyperlink | `[text](url)` |
| Heading (paragraph style) | `# Heading` |
| Bullet list | `- item` |
| Numbered list | `1. item` |
| Block quote | `> quote` |
| Footnote | `[^1]` |
| Internal link | `[[Document Title]]` (app-specific) |

### C.2 Binder Type to Folder Mapping

| Scrivener Type | Suggested Folder |
|----------------|------------------|
| DraftFolder | `draft/` or `manuscript/` |
| ResearchFolder | `research/` |
| TrashFolder | `trash/` or exclude |
| Folder | Subfolder |
| Text | `.md` or `.txt` file |
| PDF | Copy to `assets/` |
| Image | Copy to `assets/` or `images/` |

---

*This document was compiled from official Literature & Latte resources, community documentation, and analysis of Scrivener project files. The Scrivener file format is proprietary to Literature & Latte. This documentation is provided for educational and interoperability purposes.*
