const std = @import("std");
const vaxis = @import("vaxis");
const TextInput = vaxis.widgets.TextInput;

const log = std.log.scoped(.zon_editor);

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
};

/// Represents a key-value entry in the .zon file
const ZonEntry = struct {
    key: []const u8,
    value: []const u8,
    line_num: usize,
    indent: usize,
};

/// State machine for the editor
const EditorState = enum {
    navigating,
    editing,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            log.err("memory leak detected", .{});
        }
    }
    const alloc = gpa.allocator();

    // Get command-line arguments
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const filepath = if (args.len > 1) args[1] else "build.zig.zon";

    // Read the .zon file
    const file_content = std.fs.cwd().readFileAlloc(alloc, filepath, 1024 * 1024) catch |err| {
        log.err("Failed to read file '{s}': {}", .{ filepath, err });
        return err;
    };
    defer alloc.free(file_content);

    // Parse the file into entries
    var entries = std.ArrayList(ZonEntry).init(alloc);
    defer {
        for (entries.items) |entry| {
            alloc.free(entry.key);
            alloc.free(entry.value);
        }
        entries.deinit();
    }
    try parseZonFile(alloc, file_content, &entries);

    // Initialize TUI
    var buffer: [1024]u8 = undefined;
    var tty = try vaxis.Tty.init(&buffer);
    defer tty.deinit();

    var vx = try vaxis.init(alloc, .{});
    defer vx.deinit(alloc, tty.anyWriter());

    var loop: vaxis.Loop(Event) = .{
        .vaxis = &vx,
        .tty = &tty,
    };
    try loop.init();
    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(tty.anyWriter());
    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    // Editor state
    var state: EditorState = .navigating;
    var selected_row: usize = 0;
    var scroll_offset: usize = 0;
    var text_input = TextInput.init(alloc, &vx.unicode);
    defer text_input.deinit();

    // Store modified values
    var modified_values = std.StringHashMap([]const u8).init(alloc);
    defer {
        var it = modified_values.iterator();
        while (it.next()) |entry| {
            alloc.free(entry.value_ptr.*);
        }
        modified_values.deinit();
    }

    var needs_save = false;

    // Main loop
    while (true) {
        const event = loop.nextEvent();
        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                } else if (key.matches('s', .{ .ctrl = true })) {
                    // Save file
                    if (needs_save) {
                        try saveZonFile(alloc, filepath, file_content, &entries, &modified_values);
                        needs_save = false;
                    }
                } else if (state == .navigating) {
                    if (key.matches(vaxis.Key.up, .{})) {
                        if (selected_row > 0) selected_row -= 1;
                        if (selected_row < scroll_offset) scroll_offset = selected_row;
                    } else if (key.matches(vaxis.Key.down, .{})) {
                        if (selected_row + 1 < entries.items.len) selected_row += 1;
                    } else if (key.matches(vaxis.Key.enter, .{}) or key.matches('e', .{})) {
                        // Start editing
                        state = .editing;
                        text_input.clearAndFree();
                        const current_value = if (modified_values.get(entries.items[selected_row].key)) |v|
                            v
                        else
                            entries.items[selected_row].value;
                        try text_input.insertSliceAtCursor(current_value);
                    }
                } else if (state == .editing) {
                    if (key.matches(vaxis.Key.escape, .{})) {
                        // Cancel editing
                        state = .navigating;
                        text_input.clearAndFree();
                    } else if (key.matches(vaxis.Key.enter, .{})) {
                        // Save the edit
                        var buf: [1024]u8 = undefined;
                        const input_slice = text_input.sliceToCursor(&buf);
                        const new_value = try alloc.dupe(u8, input_slice);
                        const entry_key = entries.items[selected_row].key;
                        
                        // Free old value if exists
                        if (modified_values.get(entry_key)) |old_value| {
                            alloc.free(old_value);
                        }
                        try modified_values.put(entry_key, new_value);
                        needs_save = true;
                        
                        state = .navigating;
                        text_input.clearAndFree();
                    } else {
                        try text_input.update(.{ .key_press = key });
                    }
                }
            },
            .winsize => |ws| try vx.resize(alloc, tty.anyWriter(), ws),
        }

        // Render
        const win = vx.window();
        win.clear();

        // Title
        const title = try std.fmt.allocPrint(alloc, "ZON Editor - {s} {s}", .{
            filepath,
            if (needs_save) "(modified)" else "",
        });
        defer alloc.free(title);

        _ = try win.printSegment(.{ .text = title }, .{});

        // Instructions
        const instructions = if (state == .navigating)
            "↑/↓: Navigate | Enter/e: Edit | Ctrl+S: Save | Ctrl+C: Quit"
        else
            "Enter: Save | Esc: Cancel";

        const instr_win = win.child(.{
            .y_off = 1,
            .height = 1,
        });
        _ = try instr_win.printSegment(.{
            .text = instructions,
            .style = .{ .fg = .{ .rgb = .{ 128, 128, 128 } } },
        }, .{});

        // Calculate visible area
        const header_height: u16 = 3;
        const visible_height = if (win.height > header_height) win.height - header_height else 0;
        
        // Adjust scroll offset
        if (selected_row >= scroll_offset + visible_height) {
            scroll_offset = selected_row - visible_height + 1;
        }

        // Grid header
        const grid_win = win.child(.{
            .y_off = header_height,
            .height = visible_height,
        });

        var row: u16 = 0;

        // Render entries
        for (entries.items, 0..) |entry, i| {
            if (i < scroll_offset) continue;
            if (row >= visible_height) break;

            const is_selected = i == selected_row;
            const is_editing = is_selected and state == .editing;

            const display_value = if (modified_values.get(entry.key)) |v| v else entry.value;

            const row_win = grid_win.child(.{
                .y_off = row,
                .height = 1,
            });

            if (is_selected and !is_editing) {
                row_win.fill(.{ .style = .{ .bg = .{ .rgb = .{ 0, 64, 128 } } } });
            }

            // Key column
            const key_text = try std.fmt.allocPrint(alloc, "{s}{s}: ", .{
                " " ** 20,
                entry.key,
            });
            defer alloc.free(key_text);
            const key_start = if (entry.indent * 2 < key_text.len) key_text.len - entry.indent * 2 else 0;

            _ = try row_win.printSegment(.{
                .text = key_text[key_start..],
                .style = .{ .fg = .{ .rgb = .{ 100, 200, 255 } } },
            }, .{});

            // Value column or editor
            const value_win = row_win.child(.{
                .x_off = @min(entry.indent * 2 + entry.key.len + 2, row_win.width -| 1),
            });

            if (is_editing) {
                text_input.draw(value_win);
            } else {
                _ = try value_win.printSegment(.{
                    .text = display_value,
                    .style = .{ .fg = .{ .rgb = .{ 200, 255, 200 } } },
                }, .{});
            }

            row += 1;
        }

        try vx.render(tty.anyWriter());
    }
}

/// Parse a .zon file into key-value entries
fn parseZonFile(alloc: std.mem.Allocator, content: []const u8, entries: *std.ArrayList(ZonEntry)) !void {
    var lines = std.mem.splitScalar(u8, content, '\n');
    var line_num: usize = 0;

    while (lines.next()) |line| {
        line_num += 1;

        // Skip empty lines and comments
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0 or trimmed[0] == '/' or trimmed[0] == '}' or trimmed[0] == '.') {
            continue;
        }

        // Count indentation
        var indent: usize = 0;
        for (line) |c| {
            if (c == ' ') {
                indent += 1;
            } else if (c == '\t') {
                indent += 4;
            } else {
                break;
            }
        }
        indent /= 4; // Convert to logical indent level

        // Look for key = value patterns
        if (std.mem.indexOf(u8, trimmed, "=")) |eq_pos| {
            const key_part = std.mem.trim(u8, trimmed[0..eq_pos], " \t.");
            var value_part = std.mem.trim(u8, trimmed[eq_pos + 1..], " \t,");

            // Remove trailing comma
            if (value_part.len > 0 and value_part[value_part.len - 1] == ',') {
                value_part = value_part[0 .. value_part.len - 1];
            }

            // Skip if it's not a simple value
            if (std.mem.indexOf(u8, value_part, "{") != null or
                std.mem.indexOf(u8, value_part, "[") != null)
            {
                continue;
            }

            try entries.append(.{
                .key = try alloc.dupe(u8, key_part),
                .value = try alloc.dupe(u8, value_part),
                .line_num = line_num,
                .indent = indent,
            });
        }
    }
}

/// Save the modified .zon file
fn saveZonFile(
    alloc: std.mem.Allocator,
    filepath: []const u8,
    original_content: []const u8,
    entries: *std.ArrayList(ZonEntry),
    modified_values: *std.StringHashMap([]const u8),
) !void {
    // Create a map of line numbers to new values
    var line_replacements = std.AutoHashMap(usize, []const u8).init(alloc);
    defer line_replacements.deinit();

    for (entries.items) |entry| {
        if (modified_values.get(entry.key)) |new_value| {
            try line_replacements.put(entry.line_num, new_value);
        }
    }

    // Build new content
    var new_content = std.ArrayList(u8).init(alloc);
    defer new_content.deinit();

    var lines = std.mem.splitScalar(u8, original_content, '\n');
    var line_num: usize = 0;

    while (lines.next()) |line| {
        line_num += 1;

        if (line_replacements.get(line_num)) |new_value| {
            // Find the = sign and replace everything after it
            if (std.mem.indexOf(u8, line, "=")) |eq_pos| {
                try new_content.appendSlice(line[0 .. eq_pos + 1]);
                try new_content.append(' ');
                try new_content.appendSlice(new_value);
                
                // Add comma if the original had one
                const trimmed = std.mem.trimRight(u8, line, " \t\r");
                if (trimmed.len > 0 and trimmed[trimmed.len - 1] == ',') {
                    try new_content.append(',');
                }
            } else {
                try new_content.appendSlice(line);
            }
        } else {
            try new_content.appendSlice(line);
        }

        try new_content.append('\n');
    }

    // Write to file
    const file = try std.fs.cwd().createFile(filepath, .{});
    defer file.close();
    try file.writeAll(new_content.items);

    log.info("File saved: {s}", .{filepath});
}
