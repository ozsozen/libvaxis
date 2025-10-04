const std = @import("std");
const vaxis = @import("vaxis");
const TextInput = vaxis.widgets.TextInput;

const log = std.log.scoped(.zon_editor);

const Event = union(enum) {
    key_press: vaxis.Key,
    mouse: vaxis.Mouse,
    winsize: vaxis.Winsize,
    focus_in,
    focus_out,
};

const EditorMode = enum {
    normal, // Navigate and view
    edit, // Edit selected field
    command, // Command mode for save/quit
};

const ZonEntry = struct {
    key: []const u8,
    value: []const u8,
    indent_level: usize,
    is_expandable: bool,
    is_expanded: bool,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ZonEntry) void {
        self.allocator.free(self.key);
        self.allocator.free(self.value);
    }
};

const ZonEditor = struct {
    allocator: std.mem.Allocator,
    entries: std.ArrayList(ZonEntry),
    file_path: []const u8,
    selected_row: usize,
    scroll_offset: usize,
    mode: EditorMode,
    text_input: TextInput,
    command_input: TextInput,
    modified: bool,

    pub fn init(allocator: std.mem.Allocator, unicode: *vaxis.Unicode) !ZonEditor {
        return ZonEditor{
            .allocator = allocator,
            .entries = std.ArrayList(ZonEntry).init(allocator),
            .file_path = "",
            .selected_row = 0,
            .scroll_offset = 0,
            .mode = .normal,
            .text_input = TextInput.init(allocator, unicode),
            .command_input = TextInput.init(allocator, unicode),
            .modified = false,
        };
    }

    pub fn deinit(self: *ZonEditor) void {
        for (self.entries.items) |*entry| {
            entry.deinit();
        }
        self.entries.deinit();
        self.text_input.deinit();
        self.command_input.deinit();
        if (self.file_path.len > 0) {
            self.allocator.free(self.file_path);
        }
    }

    pub fn loadFile(self: *ZonEditor, path: []const u8) !void {
        // Store file path
        if (self.file_path.len > 0) {
            self.allocator.free(self.file_path);
        }
        self.file_path = try self.allocator.dupe(u8, path);

        // Clear existing entries
        for (self.entries.items) |*entry| {
            entry.deinit();
        }
        self.entries.clearRetainingCapacity();

        // Read file
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024); // 1MB max
        defer self.allocator.free(content);

        // Parse the .zon file structure
        try self.parseZonContent(content);
        self.modified = false;
    }

    fn parseZonContent(self: *ZonEditor, content: []const u8) !void {
        var lines = std.mem.splitScalar(u8, content, '\n');
        var line_num: usize = 0;

        while (lines.next()) |line| : (line_num += 1) {
            const trimmed = std.mem.trim(u8, line, " \t\r");
            if (trimmed.len == 0) continue;

            // Calculate indent level
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

            // Check if line contains a key-value pair or structure
            var is_expandable = false;
            var key: []const u8 = "";
            var value: []const u8 = "";

            // Look for patterns like ".key = value" or just ".key = .{"
            if (std.mem.indexOf(u8, trimmed, " = ")) |eq_idx| {
                key = std.mem.trim(u8, trimmed[0..eq_idx], " \t.");
                const val_part = std.mem.trim(u8, trimmed[eq_idx + 3 ..], " \t,");

                if (std.mem.startsWith(u8, val_part, ".{") or
                    std.mem.startsWith(u8, val_part, "{"))
                {
                    value = "{...}";
                    is_expandable = true;
                } else {
                    value = val_part;
                }
            } else if (std.mem.startsWith(u8, trimmed, ".{")) {
                key = "(root)";
                value = "{...}";
                is_expandable = true;
            } else {
                // Just store the line as-is
                key = "";
                value = trimmed;
            }

            try self.entries.append(.{
                .key = try self.allocator.dupe(u8, key),
                .value = try self.allocator.dupe(u8, value),
                .indent_level = indent / 4,
                .is_expandable = is_expandable,
                .is_expanded = false,
                .allocator = self.allocator,
            });
        }
    }

    pub fn saveFile(self: *ZonEditor) !void {
        if (self.file_path.len == 0) return error.NoFilePath;

        // Create a backup
        const backup_path = try std.fmt.allocPrint(self.allocator, "{s}.bak", .{self.file_path});
        defer self.allocator.free(backup_path);

        // Copy original to backup
        std.fs.cwd().copyFile(self.file_path, std.fs.cwd(), backup_path, .{}) catch |err| {
            log.warn("Could not create backup: {}", .{err});
        };

        // Write new content
        const file = try std.fs.cwd().createFile(self.file_path, .{});
        defer file.close();

        const writer = file.writer();

        // Reconstruct file from entries
        for (self.entries.items) |entry| {
            // Write indent
            for (0..entry.indent_level * 4) |_| {
                try writer.writeByte(' ');
            }

            // Write content
            if (entry.key.len > 0 and !std.mem.eql(u8, entry.key, "(root)")) {
                try writer.print(".{s} = {s},\n", .{ entry.key, entry.value });
            } else {
                try writer.print("{s}\n", .{entry.value});
            }
        }

        self.modified = false;
    }

    pub fn updateValue(self: *ZonEditor, new_value: []const u8) !void {
        if (self.selected_row >= self.entries.items.len) return;

        const entry = &self.entries.items[self.selected_row];
        self.allocator.free(entry.value);
        entry.value = try self.allocator.dupe(u8, new_value);
        self.modified = true;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            log.err("memory leak", .{});
        }
    }
    const alloc = gpa.allocator();

    // Get file path from args or use default
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.next(); // skip program name
    const file_path = args.next() orelse "build.zig.zon";

    // Initialize TTY
    var buffer: [1024]u8 = undefined;
    var tty = try vaxis.Tty.init(&buffer);
    defer tty.deinit();

    const writer = tty.writer();

    // Initialize Vaxis
    var vx = try vaxis.init(alloc, .{
        .kitty_keyboard_flags = .{ .report_events = true },
    });
    defer vx.deinit(alloc, tty.writer());

    var loop: vaxis.Loop(Event) = .{
        .vaxis = &vx,
        .tty = &tty,
    };
    try loop.init();

    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(writer);

    try vx.queryTerminal(tty.writer(), 1 * std.time.ns_per_s);

    // Initialize editor
    var editor = try ZonEditor.init(alloc, &vx.unicode);
    defer editor.deinit();

    // Load file
    editor.loadFile(file_path) catch |err| {
        log.err("Failed to load file: {}", .{err});
        return err;
    };

    var status_message: []const u8 = "Press 'e' to edit, 's' to save, 'q' to quit";

    // Main event loop
    while (true) {
        const event = loop.nextEvent();

        switch (event) {
            .key_press => |key| {

                switch (editor.mode) {
                    .normal => {
                        if (key.matches('q', .{})) {
                            if (editor.modified) {
                                status_message = "File modified! Use 'Q' to force quit or 's' to save first";
                            } else {
                                break;
                            }
                        } else if (key.matches('Q', .{ .shift = true })) {
                            break;
                        } else if (key.matches('c', .{ .ctrl = true })) {
                            break;
                        } else if (key.matches('s', .{})) {
                            editor.saveFile() catch |err| {
                                status_message = "Error saving file!";
                                log.err("Error saving: {}", .{err});
                            };
                            if (editor.modified == false) {
                                status_message = "File saved!";
                            }
                        } else if (key.matches('e', .{})) {
                            if (editor.entries.items.len > 0) {
                                editor.mode = .edit;
                                editor.text_input.clearAndFree();
                                // Note: The text input will be empty, ready for new value
                                status_message = "Edit mode: type value and press Enter to save, Esc to cancel";
                            }
                        } else if (key.matches('j', .{}) or key.matches(vaxis.Key.down, .{})) {
                            if (editor.selected_row < editor.entries.items.len - 1) {
                                editor.selected_row += 1;
                            }
                        } else if (key.matches('k', .{}) or key.matches(vaxis.Key.up, .{})) {
                            if (editor.selected_row > 0) {
                                editor.selected_row -= 1;
                            }
                        } else if (key.matches('g', .{})) {
                            editor.selected_row = 0;
                        } else if (key.matches('G', .{ .shift = true })) {
                            if (editor.entries.items.len > 0) {
                                editor.selected_row = editor.entries.items.len - 1;
                            }
                        } else if (key.matches('l', .{ .ctrl = true })) {
                            vx.queueRefresh();
                        }
                    },
                    .edit => {
                        if (key.matches(vaxis.Key.escape, .{})) {
                            editor.mode = .normal;
                            editor.text_input.clearAndFree();
                        } else if (key.matches(vaxis.Key.enter, .{})) {
                            const new_value = editor.text_input.buf.items;
                            try editor.updateValue(new_value);
                            editor.mode = .normal;
                            editor.text_input.clearAndFree();
                            status_message = "Value updated";
                        } else {
                            try editor.text_input.update(.{ .key_press = key });
                        }
                    },
                    .command => {
                        // For future extension
                        if (key.matches(vaxis.Key.escape, .{})) {
                            editor.mode = .normal;
                        }
                    },
                }
            },
            .winsize => |ws| try vx.resize(alloc, tty.writer(), ws),
            else => {},
        }

        // Rendering
        const win = vx.window();
        win.clear();

        // Draw header
        const header_win = win.child(.{
            .x_off = 0,
            .y_off = 0,
            .width = win.width,
            .height = 3,
            .border = .{
                .where = .all,
                .style = .{ .fg = .{ .index = 4 } },
            },
        });

        const title = try std.fmt.allocPrint(alloc, "ZON Editor: {s} {s}", .{
            editor.file_path,
            if (editor.modified) "[Modified]" else "",
        });
        defer alloc.free(title);

        _ = try header_win.printSegment(.{
            .text = title,
            .style = .{ .bold = true },
        }, .{ .row_offset = 1, .col_offset = 2 });

        // Draw content area
        const content_height = if (win.height > 7) win.height - 7 else 1;
        const content_win = win.child(.{
            .x_off = 0,
            .y_off = 3,
            .width = win.width,
            .height = content_height,
        });

        // Adjust scroll offset
        if (editor.selected_row < editor.scroll_offset) {
            editor.scroll_offset = editor.selected_row;
        } else if (editor.selected_row >= editor.scroll_offset + content_height) {
            editor.scroll_offset = editor.selected_row - content_height + 1;
        }

        // Draw entries
        var row: usize = 0;
        const start_idx = editor.scroll_offset;
        const end_idx = @min(start_idx + content_height, editor.entries.items.len);

        for (start_idx..end_idx) |i| {
            const entry = &editor.entries.items[i];
            const is_selected = (i == editor.selected_row);

            const style: vaxis.Style = if (is_selected) .{
                .bg = .{ .index = 4 },
                .fg = .{ .index = 0 },
                .bold = true,
            } else .{};

            // Build display line
            var display_buf: [512]u8 = undefined;
            const indent_str = "  " ** 8; // Up to 8 levels
            const indent = indent_str[0 .. entry.indent_level * 2];

            const display_line = if (entry.key.len > 0)
                try std.fmt.bufPrint(&display_buf, "{s}{s} = {s}", .{ indent, entry.key, entry.value })
            else
                try std.fmt.bufPrint(&display_buf, "{s}{s}", .{ indent, entry.value });

            _ = try content_win.printSegment(.{
                .text = display_line,
                .style = style,
            }, .{ .row_offset = row });

            row += 1;
        }

        // Draw status bar
        const status_win = win.child(.{
            .x_off = 0,
            .y_off = win.height - 4,
            .width = win.width,
            .height = 1,
        });

        const mode_str = switch (editor.mode) {
            .normal => "NORMAL",
            .edit => "EDIT",
            .command => "COMMAND",
        };

        const status_line = try std.fmt.allocPrint(alloc, " {s} | Row {d}/{d} | {s}", .{
            mode_str,
            editor.selected_row + 1,
            editor.entries.items.len,
            status_message,
        });
        defer alloc.free(status_line);

        _ = try status_win.printSegment(.{
            .text = status_line,
            .style = .{ .reverse = true },
        }, .{});

        // Draw edit input if in edit mode
        if (editor.mode == .edit) {
            // Show which field is being edited
            if (editor.selected_row < editor.entries.items.len) {
                const entry = &editor.entries.items[editor.selected_row];
                const edit_label_win = win.child(.{
                    .x_off = 2,
                    .y_off = win.height - 3,
                    .width = win.width - 4,
                    .height = 1,
                });
                const label = if (entry.key.len > 0)
                    try std.fmt.allocPrint(alloc, "Editing '{s}' (current: {s})", .{ entry.key, entry.value })
                else
                    try std.fmt.allocPrint(alloc, "Editing line (current: {s})", .{entry.value});
                defer alloc.free(label);
                _ = try edit_label_win.printSegment(.{
                    .text = label,
                    .style = .{ .fg = .{ .index = 3 } },
                }, .{});
            }

            const edit_win = win.child(.{
                .x_off = 2,
                .y_off = win.height - 2,
                .width = win.width - 4,
                .height = 1,
                .border = .{
                    .where = .all,
                    .style = .{ .fg = .{ .index = 2 } },
                },
            });
            editor.text_input.draw(edit_win);
        }

        // Render
        try vx.render(writer);
        try writer.flush();
    }
}
