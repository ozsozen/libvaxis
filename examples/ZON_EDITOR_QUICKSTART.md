# ZON Editor - Quick Start Guide

## What is it?

A terminal-based editor for .zon (Zig Object Notation) files that provides:
- Grid view of key-value pairs
- Simple keyboard navigation
- Inline editing
- File saving

## Installation

This example is part of the libvaxis library. Build it with:

```bash
zig build example -Dexample=zon_editor
```

## Quick Start

### 1. Launch the editor

```bash
# Edit build.zig.zon in current directory
zig build example -Dexample=zon_editor

# Edit a specific file
zig build example -Dexample=zon_editor -- examples/sample.zon
```

### 2. Navigate

Use `↑` and `↓` arrow keys to move through the entries.

```
  name: "vaxis"
  version: "0.5.1"
> minimum_zig_version: "0.15.1"    [← selected (highlighted in blue)]
  url: "https://..."
```

### 3. Edit a value

Press `Enter` or `e` to start editing:

```
> minimum_zig_version: "0.15.2"█   [← cursor appears]
```

Type your changes, then:
- Press `Enter` to save the edit
- Press `Esc` to cancel

### 4. Save to disk

Press `Ctrl+S` to write changes to the file.

Title bar shows `(modified)` when there are unsaved changes:
```
ZON Editor - build.zig.zon (modified)
```

### 5. Exit

Press `Ctrl+C` to quit.

## Keyboard Reference

### Navigation Mode
| Key | Action |
|-----|--------|
| `↑` | Move selection up |
| `↓` | Move selection down |
| `Enter` or `e` | Start editing selected value |
| `Ctrl+S` | Save changes to file |
| `Ctrl+C` | Exit editor |

### Editing Mode
| Key | Action |
|-----|--------|
| `Enter` | Save edit and return to navigation |
| `Esc` | Cancel edit and discard changes |
| `Ctrl+A` or `Home` | Move cursor to start |
| `Ctrl+E` or `End` | Move cursor to end |
| `Backspace` | Delete character before cursor |
| `Delete` or `Ctrl+D` | Delete character after cursor |
| `←` / `→` | Move cursor left/right |

## Example Workflow

Let's update the minimum Zig version:

```bash
# 1. Start the editor
zig build example -Dexample=zon_editor

# 2. You see:
┌─────────────────────────────────────────┐
│ ZON Editor - build.zig.zon              │
│ ↑/↓: Navigate | Enter/e: Edit | Ctrl+S… │
├─────────────────────────────────────────┤
│   name: "vaxis"                         │
│ > minimum_zig_version: "0.15.1"         │
│   url: "https://..."                    │
└─────────────────────────────────────────┘

# 3. Press Enter to edit
# 4. Change "0.15.1" to "0.15.2"
# 5. Press Enter to confirm
# 6. Title shows "(modified)"
# 7. Press Ctrl+S to save
# 8. Press Ctrl+C to exit
```

## What Gets Displayed?

The editor shows simple key-value pairs from your .zon file:

- **Keys** in blue (left side)
- **Values** in green (right side)  
- **Indentation** preserved to show nesting
- **Selection** highlighted in blue background

## Limitations

The editor focuses on simple values:
- ✅ Strings: `"value"`
- ✅ Numbers: `123`, `0.5`
- ✅ Booleans: `true`, `false`
- ❌ Nested objects: `{ .key = .{ ... } }`
- ❌ Arrays: `[1, 2, 3]`

This keeps the interface simple and focused on common editing tasks.

## Files

- `examples/zon_editor.zig` - Main implementation
- `examples/sample.zon` - Example file to try
- `examples/ZON_EDITOR.md` - Full documentation
- `examples/demo_zon_editor.sh` - Visual demo

## Troubleshooting

### File not found
```bash
# Make sure the file path is correct
zig build example -Dexample=zon_editor -- ./path/to/file.zon
```

### Can't edit a value
- Only simple values can be edited
- Nested objects and arrays are skipped
- Check if the value has `{` or `[` characters

### Changes not saved
- Make sure to press `Ctrl+S` after editing
- Check file permissions for write access

## More Information

See `examples/ZON_EDITOR.md` for:
- Complete feature list
- Implementation details
- Technical architecture
- Code examples

See `examples/ZON_EDITOR_SUMMARY.md` for:
- Technical implementation details
- Memory management approach
- IO abstraction usage
- Future enhancement ideas

## Try It Now!

```bash
# Clone libvaxis
git clone https://github.com/ozsozen/libvaxis
cd libvaxis

# Try the sample file
zig build example -Dexample=zon_editor -- examples/sample.zon

# Or view the demo
./examples/demo_zon_editor.sh
```

## Requirements

- Zig 0.15.1 or later (including master branch)
- Terminal with basic ANSI color support
- libvaxis library

## License

Same as libvaxis (MIT)
