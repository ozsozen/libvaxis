# Quick Start Guide - ZON Editor

## What is this?

A terminal-based editor for `.zon` files (Zig Object Notation) that lets you:
- View .zon files in a structured grid format
- Navigate through key-value pairs
- Edit values
- Save changes with automatic backups

## Installation

The zon_editor is part of the libvaxis examples. To use it:

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/ozsozen/libvaxis
cd libvaxis

# Build and run
zig build example -Dexample=zon_editor
```

## Basic Usage

### Opening a File

```bash
# Edit the default file (build.zig.zon)
zig build example -Dexample=zon_editor

# Edit a specific file
zig build example -Dexample=zon_editor -- path/to/your/file.zon

# Try the sample file
zig build example -Dexample=zon_editor -- examples/sample.zon
```

### Navigating

Once the editor is open:

| Key | Action |
|-----|--------|
| `j` or `↓` | Move down one line |
| `k` or `↑` | Move up one line |
| `g` | Jump to the top |
| `G` (Shift+g) | Jump to the bottom |

### Editing

1. Navigate to the line you want to edit
2. Press `e` to enter edit mode
3. Type the new value
4. Press `Enter` to save or `Escape` to cancel

### Saving

| Key | Action |
|-----|--------|
| `s` | Save the file (creates a .bak backup) |
| `q` | Quit (warns if you have unsaved changes) |
| `Q` (Shift+q) | Force quit without saving |
| `Ctrl+c` | Force quit without saving |

## Example Session

```
1. Open the editor:
   $ zig build example -Dexample=zon_editor -- examples/sample.zon

2. Navigate to a value you want to change:
   Use j/k or arrow keys to move around

3. Edit the value:
   Press 'e', type new value, press Enter

4. Save your changes:
   Press 's'

5. Exit:
   Press 'q'
```

## Tips

- **Automatic Backups**: Every time you save, a `.bak` file is created
- **Status Bar**: Watch the bottom of the screen for helpful messages
- **Mode Indicator**: Shows whether you're in NORMAL or EDIT mode
- **Row Counter**: Shows your current position (e.g., "Row 5/17")
- **Modified Indicator**: "[Modified]" appears in the header when you have unsaved changes

## Troubleshooting

**Q: The editor doesn't start**
- Make sure you have Zig 0.15.1 or later installed
- Check that the file path is correct

**Q: Changes aren't saved**
- Make sure you pressed 's' to save
- Check file permissions in the directory

**Q: Can't exit**
- If the file is modified, press 'Q' (Shift+q) to force quit
- Or save with 's' first, then press 'q'

## More Information

For detailed documentation, see:
- [ZON_EDITOR_README.md](./ZON_EDITOR_README.md) - Full user guide
- [ZON_EDITOR_IMPLEMENTATION.md](./ZON_EDITOR_IMPLEMENTATION.md) - Technical details
- [ZON_EDITOR_VISUAL.md](./ZON_EDITOR_VISUAL.md) - Visual layout examples

## Feedback

If you encounter issues or have suggestions, please open an issue on the GitHub repository.
