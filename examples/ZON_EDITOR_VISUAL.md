# ZON Editor Visual Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  ZON Editor: build.zig.zon                                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
│                                                                      │
│  (root) = {...}                                                     │
│    name = .vaxis                                                    │
│    version = "0.5.1"                                                │
│    minimum_zig_version = "0.15.1"                                   │
│ ▶  dependencies = {...}                                             │  <- Selected row
│      zigimg = {...}                                                 │
│        url = "https://github.com/.../zigimg/archive/..."           │
│        hash = "zigimg-0.1.0-8_eo2vHn..."                           │
│      zg = {...}                                                     │
│        url = "https://codeberg.org/..."                            │
│        hash = "zg-0.15.1-oGqU3M0..."                               │
│    paths = {...}                                                    │
│      "LICENSE"                                                      │
│      "build.zig"                                                    │
│      "build.zig.zon"                                                │
│      "src"                                                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
 NORMAL | Row 5/17 | Press 'e' to edit, 's' to save, 'q' to quit     


## When Editing (Press 'e'):

┌─────────────────────────────────────────────────────────────────────┐
│  ZON Editor: build.zig.zon [Modified]                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
│                                                                      │
│  (root) = {...}                                                     │
│    name = .vaxis                                                    │
│    version = "0.5.1"                                                │
│    minimum_zig_version = "0.15.1"                                   │
│ ▶  dependencies = {...}                                             │
│      zigimg = {...}                                                 │
│        url = "https://github.com/.../zigimg/archive/..."           │
│        hash = "zigimg-0.1.0-8_eo2vHn..."                           │
│      zg = {...}                                                     │
│        url = "https://codeberg.org/..."                            │
│        hash = "zg-0.15.1-oGqU3M0..."                               │
│    paths = {...}                                                    │
│      "LICENSE"                                                      │
│      "build.zig"                                                    │
│                                                                      │
│ Editing 'dependencies' (current: {...})                             │
│ ┌─────────────────────────────────────────────────────────────────┐│
│ │{...}█                                                            ││ <- Text input cursor
│ └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
 EDIT | Row 5/17 | Edit mode: type value and press Enter...          


## Key Features Shown:

1. **Header Area**
   - Shows file path
   - Indicates [Modified] status when changes are made

2. **Content Area**
   - Displays parsed .zon structure
   - Shows indentation levels (2 spaces per level)
   - Selected row highlighted with ▶ symbol
   - Scrolls automatically to keep selection visible

3. **Status Bar** (Bottom line)
   - Current mode (NORMAL/EDIT/COMMAND)
   - Row counter (current/total)
   - Helpful status messages

4. **Edit Mode UI**
   - Label showing what's being edited
   - Current value displayed
   - Bordered input box for new value
   - Clear instructions

## Color Scheme:
- Header border: Blue (index 4)
- Selected row: Blue background
- Edit input border: Green (index 2)
- Edit label: Yellow (index 3)
- Status bar: Reverse video (white on black)
```

## Example Workflow

### 1. Opening a file
```bash
$ zig build example -Dexample=zon_editor -- examples/sample.zon
```

### 2. Navigation
- Use `j`/`k` or arrow keys to move through entries
- Press `g` to jump to top
- Press `G` to jump to bottom

### 3. Editing a value
- Navigate to the entry you want to edit
- Press `e` to enter edit mode
- Type the new value
- Press `Enter` to confirm or `Escape` to cancel

### 4. Saving changes
- Press `s` to save
- A backup file (filename.zon.bak) is automatically created
- Status message confirms save

### 5. Quitting
- Press `q` to quit (warns if modified)
- Press `Q` (Shift+q) to force quit without saving
- Or `Ctrl+c` to force quit

## Technical Implementation Details

### File Structure Parsing
```
Input:  .{
          .name = .vaxis,
          .version = "0.5.1",
        }

Parsed: Entry 0: key="(root)", value="{...}", indent=0
        Entry 1: key="name", value=".vaxis", indent=1
        Entry 2: key="version", value="0.5.1", indent=1
```

### Indentation Tracking
- Each entry tracks its indentation level
- 4 spaces = 1 indent level
- Used for visual display (2 spaces per level in UI)

### Scrolling Logic
- Viewport size = window height - header - status bar
- If selected_row < scroll_offset: scroll up
- If selected_row >= scroll_offset + viewport: scroll down
- Always keeps selected row visible
