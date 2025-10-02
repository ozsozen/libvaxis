# ZON Editor Example

A minimalist terminal-based editor for .zon (Zig Object Notation) files.

## Features

- **Grid-based display**: Shows key-value pairs from .zon files in an easy-to-read format
- **Navigation**: Use arrow keys to navigate through entries
- **Inline editing**: Press Enter or 'e' to edit values
- **Save changes**: Press Ctrl+S to save modifications
- **Tree structure visualization**: Displays nested structure with indentation

## Usage

```bash
# Build and run with default file (build.zig.zon)
zig build example -Dexample=zon_editor

# Or specify a custom .zon file
zig build example -Dexample=zon_editor -- path/to/file.zon

# Try the sample file
zig build example -Dexample=zon_editor -- examples/sample.zon
```

## Keyboard Controls

### Navigation Mode
- `↑/↓` - Navigate through entries
- `Enter` or `e` - Start editing the selected value
- `Ctrl+S` - Save changes to file
- `Ctrl+C` - Exit the editor

### Editing Mode
- `Enter` - Save the current edit
- `Esc` - Cancel editing and discard changes
- Normal text input for editing values

## Implementation Details

### IO Abstraction Compatibility

This example is designed to work with Zig 0.15.1 and above, using the modern `io` abstraction:

- Uses `std.fs.cwd().readFileAlloc()` for reading files
- Uses `std.fs.cwd().createFile()` for writing files
- Compatible with Zig master branch

### Parsing Approach

The editor uses a simple line-based parser that:
1. Identifies key-value pairs by looking for `=` signs
2. Tracks indentation levels to show structure
3. Preserves the original file format when saving
4. Only modifies lines with edited values

### Limitations

- Currently handles simple key-value pairs (strings, numbers)
- Does not support editing of nested objects or arrays
- Preserves but doesn't parse complex expressions

## Architecture

The editor is built using:
- **vaxis** for TUI rendering and input handling
- **TextInput widget** for inline value editing
- **Custom parser** for .zon file structure extraction
- **HashMap** for tracking modifications before save

## Example Output

```
ZON Editor - build.zig.zon
↑/↓: Navigate | Enter/e: Edit | Ctrl+S: Save | Ctrl+C: Quit

  name: "vaxis"
  version: "0.5.1"
  minimum_zig_version: "0.15.1"
    url: "https://github.com/..."
    hash: "zigimg-0.1.0-8_eo2v..."
```

The selected row is highlighted, and pressing Enter allows you to edit the value inline.
