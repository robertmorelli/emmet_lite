const lex = @import("lexer.zig");
const defs = @import("defs.zig");
const std = @import("std");

const keywords = defs.keywords;
const tabs_needed = defs.tabs_needed;
const biggest_char = defs.biggest_char;
const trie_node = defs.trie_node;
const error_state = defs.error_state;
const accept_state = defs.accept_state;
const start_state = defs.start_state;
const ignore_state = defs.ignore_state;
const tipe = defs.tipe;
const state_type = defs.state_type;
const string_table = defs.string_table;
const content_table = defs.content_table;
const number_table = defs.number_table;
const identifier_table = defs.identifier_table;
const legal_table = defs.legal_table;

const StateMachine = struct {
    tabs: [tabs_needed]trie_node,
    t: [tabs_needed]tipe,
    tabs_alloc: state_type,

    fn init() StateMachine {
        var sm: StateMachine = undefined;
        for (0..tabs_needed) |index| {
            sm.tabs[index] = [1]state_type{error_state} ** biggest_char;
            sm.t[index] = .invalid;
        }
        sm.t[error_state] = .invalid;
        sm.t[start_state] = .start;
        sm.t[accept_state] = .accept;
        sm.t[ignore_state] = .ignore;
        sm.tabs_alloc = ignore_state + 1; // Start after the predefined states

        // Set up basic transitions
        setStateLoopAll(&sm, error_state); // Error state loops back to itself
        setStateTransitionAll(&sm, accept_state, start_state); // Accept -> Start
        setStateTransitionAll(&sm, ignore_state, start_state); // Ignore -> Start

        return sm;
    }

    // Add a transition from one state to another for a specific character
    fn addTransition(sm: *StateMachine, from: state_type, to: state_type, ch: state_type) void {
        sm.tabs[from][ch] = to;
    }

    // Set all transitions from a state to go to another state
    fn setStateTransitionAll(sm: *StateMachine, from: state_type, to: state_type) void {
        for (0..biggest_char) |ch| {
            sm.tabs[from][@intCast(ch)] = to;
        }
    }

    // Make a state loop back to itself for all characters
    fn setStateLoopAll(sm: *StateMachine, state: state_type) void {
        for (0..biggest_char) |ch| {
            sm.tabs[state][@intCast(ch)] = state;
        }
    }

    fn addKeywords(sm: *StateMachine, identifier_state: state_type) void {
        for (keywords) |keyword| {
            const tag_name = @tagName(keyword);
            var one = start_state;
            var could_be_ident = true;
            for (tag_name[0 .. tag_name.len - 1]) |ch| {
                could_be_ident = could_be_ident and identifier_table[ch];
                const two = sm.tabs[one][ch];
                const rejects = two == error_state;
                const accepts = two == accept_state;
                const loops = two == start_state;
                const ident = two == identifier_state;
                if (rejects or accepts or loops or ident) {
                    const three = if (could_be_ident)
                        sm.allocTipeDefaultTable(identifier_state, .identifier, identifier_table)
                    else
                        sm.allocTipeDefaultTable(error_state, .invalid, identifier_table);
                    _ = sm.addTransition(one, three, ch);
                    one = three;
                } else {
                    one = two;
                }
            }
            const ch = tag_name[tag_name.len - 1];
            could_be_ident = could_be_ident and identifier_table[ch];
            const two = sm.tabs[one][ch];
            const rejects = two == error_state;
            const accepts = two == accept_state;
            const loops = two == start_state;
            const ident = two == identifier_state;
            if (rejects or accepts or loops or ident) {
                const three = if (could_be_ident)
                    sm.allocTipeDefaultTable(identifier_state, keyword, identifier_table)
                else
                    sm.allocTipeDefaultTable(accept_state, keyword, legal_table);
                _ = sm.addTransition(one, three, ch);
                one = three;
            } else {
                one = two;
            }
            sm.t[one] = keyword;
        }
    }

    fn allocTipeDefaultTable(sm: *StateMachine, identifier_state: state_type, t: tipe, tab: [biggest_char]bool) state_type {
        const state = sm.tabs_alloc;
        sm.tabs_alloc += 1;
        sm.t[state] = t;

        for (0..biggest_char) |index| {
            if (!legal_table[index]) {
                sm.addTransition(state, error_state, index);
            } else if (tab[index]) {
                sm.addTransition(state, identifier_state, index);
            } else {
                sm.addTransition(state, accept_state, index);
            }
        }
        return state;
    }

    fn newLoopDefaultTablesInOut(
        sm: *StateMachine,
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
                sm.addTransition(state, error_state, index);
            } else {
                sm.addTransition(state, accept_state, index);
            }
        }
        return state;
    }

    fn newStateDefaultTablesOut(
        sm: *StateMachine,
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
                sm.addTransition(state, error_state, index);
            } else {
                sm.addTransition(state, accept_state, index);
            }
        }
        return state;
    }

    fn newLoopDefaultTablesOut(
        sm: *StateMachine,
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
                sm.addTransition(state, error_state, index);
            } else {
                sm.addTransition(state, accept_state, index);
            }
        }
        return state;
    }

    fn addIdentifierHandling(sm: *StateMachine) state_type {
        return sm.newLoopDefaultTablesInOut(
            start_state,
            identifier_table,
            identifier_table,
            .identifier,
        );
    }

    fn addNumberHandling(sm: *StateMachine) state_type {
        return sm.newLoopDefaultTablesInOut(
            start_state,
            number_table,
            number_table,
            .number,
        );
    }

    fn addStringHandling(sm: *StateMachine) state_type {
        const string_body = sm.newLoopDefaultTablesOut(
            start_state,
            '"',
            string_table,
            .invalid,
        );
        return sm.newStateDefaultTablesOut(
            string_body,
            '"',
            accept_state,
            legal_table,
            .string,
        );
    }

    fn addContentHandling(sm: *StateMachine) state_type {
        const string_body = sm.newLoopDefaultTablesOut(
            start_state,
            '{',
            content_table,
            .invalid,
        );
        return sm.newStateDefaultTablesOut(
            string_body,
            '}',
            accept_state,
            legal_table,
            .content,
        );
    }
};

// Create the state machine
pub const state_machine: StateMachine = def: {
    @setEvalBranchQuota(1000000);
    var sm = StateMachine.init();
    const identifier_state = sm.addIdentifierHandling();
    _ = sm.addKeywords(identifier_state);
    _ = sm.addNumberHandling();
    _ = sm.addStringHandling();
    _ = sm.addContentHandling();
    break :def sm;
};
