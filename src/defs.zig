const std = @import("std");
pub const tipe = enum(u8) { start, accept, invalid, ignore, string, content, identifier, number, @"(", @")", @"[", @"]", @">", @"+", @"#", @".", @"=", @"*", a, abbr, address, area, article, aside, audio, b, base, bdi, bdo, blockquote, body, br, button, canvas, caption, cite, code, col, colgroup, data, datalist, dd, del, details, dfn, dialog, div, dl, dt, em, embed, fieldset, figcaption, figure, footer, form, h1, h2, h3, h4, h5, h6, head, header, hgroup, hr, html, i, iframe, img, input, ins, kbd, label, legend, li, link, main, map, mark, meta, meter, nav, noscript, object, ol, optgroup, option, output, p, param, picture, pre, progress, q, rp, rt, ruby, s, samp, script, section, select, slot, small, source, span, strong, style, sub, summary, sup, table, tbody, td, template, textarea, tfoot, th, thead, time, title, tr, track, u, ul, @"var", v, ideo, wbr, eof };

//important! must be longest to shortest
pub const keywords = [_]tipe{ .fieldset, .figcaption, .blockquote, .colgroup, .datalist, .noscript, .optgroup, .progress, .template, .textarea, .address, .article, .caption, .details, .picture, .section, .summary, .figure, .button, .canvas, .dialog, .footer, .header, .hgroup, .iframe, .legend, .object, .option, .output, .script, .select, .source, .strong, .aside, .audio, .embed, .input, .label, .meter, .param, .small, .style, .table, .tbody, .tfoot, .thead, .title, .track, .abbr, .area, .base, .body, .cite, .code, .data, .form, .head, .html, .link, .main, .mark, .meta, .ruby, .samp, .slot, .span, .time, .ideo, .bdi, .bdo, .col, .del, .dfn, .div, .img, .ins, .kbd, .map, .nav, .pre, .sub, .sup, .@"var", .wbr, .br, .dd, .dl, .dt, .em, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .li, .ol, .rp, .rt, .td, .th, .tr, .ul, .@"(", .@")", .@"[", .@"]", .@">", .@"+", .@"#", .@".", .@"=", .@"*", .a, .b, .i, .p, .q, .s, .u, .v };

pub const offset_size = u32;
pub const value = [2]offset_size;

pub const tabs_needed = 373;
pub const biggest_char = 256;
pub const state_type = u16;
pub const trie_node: type = [biggest_char]state_type;

// Define special state IDs
pub const error_state: state_type = 0;
pub const start_state: state_type = 1;
pub const accept_state: state_type = 2;
pub const ignore_state: state_type = 3;

pub const identifier_table: [biggest_char]bool = def: {
    var table: [biggest_char]bool = [1]bool{false} ** biggest_char;
    for ('a'..'z' + 1) |index| {
        table[index] = true;
    }
    for ('A'..'Z' + 1) |index| {
        table[index] = true;
    }
    for ('0'..'9' + 1) |index| {
        table[index] = true;
    }
    table['-'] = true;
    table['$'] = true;
    break :def table;
};

pub const string_table: [biggest_char]bool = def: {
    var table: [biggest_char]bool = [1]bool{false} ** biggest_char;
    for (0x20..0x7E + 1) |index| {
        if (index != '"') {
            table[index] = true;
        }
    }
    break :def table;
};

pub const content_table: [biggest_char]bool = def: {
    var table: [biggest_char]bool = [1]bool{false} ** biggest_char;
    for (0x20..0x7E + 1) |index| {
        if (index != '}') {
            table[index] = true;
        }
    }
    break :def table;
};

pub const number_table: [biggest_char]bool = def: {
    var table: [biggest_char]bool = [1]bool{false} ** biggest_char;
    for ('0'..'9' + 1) |index| {
        table[index] = true;
    }
    break :def table;
};

pub const legal_table: [biggest_char]bool = def: {
    var table: [biggest_char]bool = [1]bool{false} ** biggest_char;

    // Mark identifier characters as legal (true = legal)
    for ('a'..'z' + 1) |index| {
        table[index] = true;
    }
    for ('A'..'Z' + 1) |index| {
        table[index] = true;
    }
    for ('0'..'9' + 1) |index| {
        table[index] = true;
    }
    table['_'] = true;
    table['-'] = true;
    table['$'] = true;

    // Mark operators and punctuation as legal
    table['('] = true;
    table[')'] = true;
    table['['] = true;
    table[']'] = true;
    table['>'] = true;
    table['+'] = true;
    table['#'] = true;
    table['.'] = true;
    table['='] = true;
    table['*'] = true;
    table['/'] = true;
    table['"'] = true;
    table['{'] = true;
    table['}'] = true;
    table['\\'] = true;

    // Mark whitespace as legal
    table[' '] = true;
    table['\n'] = true;
    table['\t'] = true;

    break :def table;
};
