# ZON Editor Example

A minimalist terminal-based editor for viewing and editing Zig Object Notation (.zon) files.

## Features

- **Display Grid**: View .zon files in a structured grid format with key-value pairs
- **Tree View**: Shows the object tree structure with proper indentation
- **Navigation**: Use vi-like keys (j/k) or arrow keys to move through entries
- **Editing**: Edit values of individual fields
- **File Saving**: Save changes back to the file with automatic backup creation

## Usage

Run with default file (build.zig.zon):
```bash
zig build example -Dexample=zon_editor
```

Run with a specific file:
```bash
zig build example -Dexample=zon_editor -- path/to/file.zon
```

Or run the sample file:
```bash
zig build example -Dexample=zon_editor -- examples/sample.zon
```

## Keybindings

### Normal Mode
- `j` or `Down` - Move down
- `k` or `Up` - Move up
- `g` - Go to top
- `G` (Shift+g) - Go to bottom
- `e` - Edit the selected value
- `s` - Save file
- `q` - Quit (warns if modified)
- `Q` (Shift+q) - Force quit without saving
- `Ctrl+c` - Force quit
- `Ctrl+l` - Refresh screen

### Edit Mode
- `Enter` - Confirm changes
- `Escape` - Cancel editing
- Any text input - Edit the value

## Implementation Details

- The editor parses .zon files line by line
- Each entry stores its key, value, and indentation level
- Files are saved with automatic backup creation (.bak extension)
- The display shows nested structures with appropriate indentation
- Modified files are indicated in the header
