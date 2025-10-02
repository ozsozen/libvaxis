#!/bin/bash
# This script shows a visual demo of what the zon_editor looks like
# It's not meant to run, just to visualize the interface

cat << 'EOF'
================================================================================
                         ZON EDITOR DEMO VISUALIZATION
================================================================================

NAVIGATION MODE:
┌────────────────────────────────────────────────────────────────────────────┐
│ ZON Editor - build.zig.zon                                                 │
│ ↑/↓: Navigate | Enter/e: Edit | Ctrl+S: Save | Ctrl+C: Quit               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   name: "vaxis"                                                            │
│   version: "0.5.1"                                                         │
│ > minimum_zig_version: "0.15.1"        [← Selected row (blue highlight)]  │
│     url: "https://github.com/ivanste..."                                   │
│     hash: "zigimg-0.1.0-8_eo2vHnEwC..."                                   │
│     url: "https://codeberg.org/chat..."                                    │
│     hash: "zg-0.15.1-oGqU3M0-tALZCy..."                                   │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘

EDITING MODE (after pressing Enter):
┌────────────────────────────────────────────────────────────────────────────┐
│ ZON Editor - build.zig.zon (modified)                                      │
│ Enter: Save | Esc: Cancel                                                  │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   name: "vaxis"                                                            │
│   version: "0.5.1"                                                         │
│ > minimum_zig_version: "0.15.2"█      [← Editing with cursor █]           │
│     url: "https://github.com/ivanste..."                                   │
│     hash: "zigimg-0.1.0-8_eo2vHnEwC..."                                   │
│     url: "https://codeberg.org/chat..."                                    │
│     hash: "zg-0.15.1-oGqU3M0-tALZCy..."                                   │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘

AFTER SAVING (Press Ctrl+S):
┌────────────────────────────────────────────────────────────────────────────┐
│ ZON Editor - build.zig.zon                                                 │
│ ↑/↓: Navigate | Enter/e: Edit | Ctrl+S: Save | Ctrl+C: Quit               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   name: "vaxis"                                                            │
│   version: "0.5.1"                                                         │
│ > minimum_zig_version: "0.15.2"        [← Value saved to disk]            │
│     url: "https://github.com/ivanste..."                                   │
│     hash: "zigimg-0.1.0-8_eo2vHnEwC..."                                   │
│     url: "https://codeberg.org/chat..."                                    │
│     hash: "zg-0.15.1-oGqU3M0-tALZCy..."                                   │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘

================================================================================
KEY FEATURES:
================================================================================

✓ Simple grid-based display of .zon key-value pairs
✓ Arrow key navigation (↑/↓) through entries
✓ Inline editing with TextInput widget (Enter or 'e' to edit)
✓ Visual indication of modified state
✓ Automatic indentation preservation
✓ Ctrl+S to save changes, Ctrl+C to quit
✓ Works with any .zon file passed as argument

================================================================================
USAGE:
================================================================================

# Build and run with default file
zig build example -Dexample=zon_editor

# Edit a specific .zon file
zig build example -Dexample=zon_editor -- path/to/your.zon

# Try with the sample file
zig build example -Dexample=zon_editor -- examples/sample.zon

================================================================================
TECHNICAL IMPLEMENTATION:
================================================================================

File: examples/zon_editor.zig (362 lines)

Components:
- Simple line-based .zon parser (extracts key=value pairs)
- Grid display with color-coded keys (blue) and values (green)
- TextInput widget for inline editing
- State machine: navigating ↔ editing
- HashMap to track modified values before saving
- Atomic file writing with content reconstruction

IO Usage (Zig 0.15.1+):
- std.fs.cwd().readFileAlloc() for reading
- std.fs.cwd().createFile() for writing
- Proper memory management with allocators

================================================================================
EOF
