const std = @import("std");
//todo: remove std

const biggest_char = std.math.maxInt(u8) + 1;
pub const offset_size = u32;
pub const value = [2]offset_size;
pub const lex_error_state = 0;
pub const lex_start_state = 1;
pub const lex_accept_state = 2;
pub const lex_ignore_state = 3;
pub const lex_identifier_state = 4;
pub const parse_error_state = 5;
pub const parse_start_state = 6;
pub const parse_accept_state = 7;
const sm_initial_allocatable_state = 8;
//this is a little bit wrong. biggest char is based on u8 instead on tipe. tip needs to be u8 tbh
pub fn state_machine(
    tabs_needed: comptime_int,
    state_type: type,
    tipe: type,
    keywords: []const tipe,
    legal_table: [biggest_char]bool,
    identifier_table: [biggest_char]bool,
) type {
    const trie_node: type = [biggest_char]state_type;
    return struct {
        tabs: [tabs_needed]trie_node,
        t: [tabs_needed]tipe,
        tabs_alloc: state_type,

        pub fn init() @This() {
            var sm: @This() = undefined;
            for (0..tabs_needed) |index| {
                sm.tabs[index] = [1]state_type{lex_error_state} ** biggest_char;
                sm.t[index] = .invalid;
            }
            sm.t[lex_error_state] = .invalid;
            sm.t[lex_start_state] = .start;
            sm.t[lex_accept_state] = .accept;
            sm.t[lex_ignore_state] = .ignore;
            sm.tabs_alloc = lex_ignore_state + 1; // Start after the predefined states

            // Set up basic transitions
            setStateLoopAll(&sm, lex_error_state); // Error state loops back to itself
            setStateTransitionAll(&sm, lex_accept_state, lex_start_state); // Accept -> Start
            setStateTransitionAll(&sm, lex_ignore_state, lex_start_state); // Ignore -> Start

            return sm;
        }

        // Add a transition from one state to another for a specific character
        pub fn addTransition(sm: *@This(), from: state_type, to: state_type, ch: state_type) void {
            sm.tabs[from][ch] = to;
        }

        // Set all transitions from a state to go to another state
        pub fn setStateTransitionAll(sm: *@This(), from: state_type, to: state_type) void {
            for (0..biggest_char) |ch| {
                sm.tabs[from][@intCast(ch)] = to;
            }
        }

        // Make a state loop back to itself for all characters
        pub fn setStateLoopAll(sm: *@This(), state: state_type) void {
            for (0..biggest_char) |ch| {
                sm.tabs[state][@intCast(ch)] = state;
            }
        }

        pub fn addKeywords(sm: *@This(), identifier_state: state_type) void {
            for (keywords) |keyword| {
                const tag_name = @tagName(keyword);
                var one = lex_start_state;
                var could_be_ident = true;
                for (tag_name[0 .. tag_name.len - 1]) |ch| {
                    could_be_ident = could_be_ident and identifier_table[ch];
                    const two = sm.tabs[one][ch];
                    const rejects = two == lex_error_state;
                    const accepts = two == lex_accept_state;
                    const loops = two == lex_start_state;
                    const ident = two == identifier_state;
                    if (rejects or accepts or loops or ident) {
                        const three = if (could_be_ident)
                            sm.allocTipeDefaultTable(identifier_state, .identifier, identifier_table)
                        else
                            sm.allocTipeDefaultTable(lex_error_state, .invalid, identifier_table);
                        _ = sm.addTransition(one, three, ch);
                        one = three;
                    } else {
                        one = two;
                    }
                }
                const ch = tag_name[tag_name.len - 1];
                could_be_ident = could_be_ident and identifier_table[ch];
                const two = sm.tabs[one][ch];
                const rejects = two == lex_error_state;
                const accepts = two == lex_accept_state;
                const loops = two == lex_start_state;
                const ident = two == identifier_state;
                if (rejects or accepts or loops or ident) {
                    const three = if (could_be_ident)
                        sm.allocTipeDefaultTable(identifier_state, keyword, identifier_table)
                    else
                        sm.allocTipeDefaultTable(lex_accept_state, keyword, legal_table);
                    _ = sm.addTransition(one, three, ch);
                    one = three;
                } else {
                    one = two;
                }
                sm.t[one] = keyword;
            }
        }

        pub fn allocTipeDefaultTable(sm: *@This(), identifier_state: state_type, t: tipe, tab: [biggest_char]bool) state_type {
            const state = sm.tabs_alloc;
            sm.tabs_alloc += 1;
            sm.t[state] = t;

            for (0..biggest_char) |index| {
                if (!legal_table[index]) {
                    sm.addTransition(state, lex_error_state, index);
                } else if (tab[index]) {
                    sm.addTransition(state, identifier_state, index);
                } else {
                    sm.addTransition(state, lex_accept_state, index);
                }
            }
            return state;
        }

        pub fn newLoopDefaultTablesInOut(
            sm: *@This(),
            source_state: state_type,
            source_table: [biggest_char]bool,
            dest_table: [biggest_char]bool,
            t: tipe,
        ) state_type {
            const state = sm.tabs_alloc;
            sm.tabs_alloc += 1;
            sm.t[state] = t;
            for (0..biggest_char) |index| {
                if (source_table[index]) {
                    sm.addTransition(source_state, state, index);
                }
            }
            for (0..biggest_char) |index| {
                if (dest_table[index]) {
                    sm.addTransition(state, state, index);
                } else if (!legal_table[index]) {
                    sm.addTransition(state, lex_error_state, index);
                } else {
                    sm.addTransition(state, lex_accept_state, index);
                }
            }
            return state;
        }

        pub fn newStateDefaultTablesOut(
            sm: *@This(),
            source_state: state_type,
            source_char: state_type,
            dest_state: state_type,
            dest_table: [biggest_char]bool,
            t: tipe,
        ) state_type {
            const state = sm.tabs_alloc;
            sm.tabs_alloc += 1;
            sm.t[state] = t;
            sm.addTransition(source_state, state, source_char);
            for (0..biggest_char) |index| {
                if (dest_table[index]) {
                    sm.addTransition(state, dest_state, index);
                } else if (!legal_table[index]) {
                    sm.addTransition(state, lex_error_state, index);
                } else {
                    sm.addTransition(state, lex_accept_state, index);
                }
            }
            return state;
        }

        pub fn newLoopDefaultTablesOut(
            sm: *@This(),
            source_state: state_type,
            source_char: state_type,
            dest_table: [biggest_char]bool,
            t: tipe,
        ) state_type {
            const state = sm.tabs_alloc;
            sm.tabs_alloc += 1;
            sm.t[state] = t;
            sm.addTransition(source_state, state, source_char);
            for (0..biggest_char) |index| {
                if (dest_table[index]) {
                    sm.addTransition(state, state, index);
                } else if (!legal_table[index]) {
                    sm.addTransition(state, lex_error_state, index);
                } else {
                    sm.addTransition(state, lex_accept_state, index);
                }
            }
            return state;
        }

        pub fn addIdentifierHandling(sm: *@This()) state_type {
            return sm.newLoopDefaultTablesInOut(
                lex_start_state,
                identifier_table,
                identifier_table,
                .identifier,
            );
        }

        fn err(n: offset_size, i: offset_size, j: offset_size) noreturn {
            var outw: std.fs.File.Writer = undefined;
            _ = outw.print("last n: {d}, i: {d}, j: {d}\n", .{ n, i, j }) catch unreachable;
            _ = outw.write("Compilation failed\n") catch unreachable;
            std.process.exit(1);
        }

        pub fn run(sm: *const @This(), string: []u8, values: []value, types: []tipe) offset_size {
            var n: offset_size = 0;
            var i: offset_size = 0;
            var j: offset_size = 0;
            var state: @TypeOf(sm.tabs_alloc) = lex_start_state;
            l: switch (sm.tabs[state][string[j]]) {
                lex_error_state => {
                    @branchHint(.cold);
                    if (j != string.len - 1) err(n, i, j);
                    if (j != i) {
                        const final_state = sm.t[state];
                        if (final_state == .invalid) err(n, i, j);
                        values[n] = .{ i, j };
                        types[n] = final_state;
                        n = n + 1;
                        i = j;
                    }
                    values[n] = .{ i, j };
                    types[n] = .eof;
                    n = n + 1;
                },
                lex_accept_state => {
                    values[n] = .{ i, j };
                    types[n] = sm.t[state];
                    n = n + 1;
                    i = j;
                    continue :l sm.tabs[lex_start_state][string[j]];
                },
                lex_ignore_state => {
                    i = j + 1;
                    j = j + 1;
                    continue :l sm.tabs[lex_start_state][string[j]];
                },
                else => |last_state| {
                    @branchHint(.likely);
                    state = last_state;
                    j = j + 1;
                    continue :l sm.tabs[last_state][string[j]];
                },
            }
            return n;
        }
    };
}
