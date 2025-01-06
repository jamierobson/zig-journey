// Creates an executable

const std = @import("std");
const GenericWriter = std.io.GenericWriter;

pub fn main() !void {
    const stdIn = std.io.getStdIn().reader();
    const stdOut = std.io.getStdOut().writer();
    // const arena =
    try writeLine(stdOut, "Let's play the guessing game. The lower bound will be 1.");
    _ = try getUpperBound(stdIn, stdOut);
}

pub fn getUpperBound(reader: anytype, writer: anytype) !u32 {
    // var inputBuffer: [INPUT_BUFFER_SIZE]u8 = undefined;
    var inputBuffer = [_]u8{0} ** INPUT_BUFFER_SIZE; // todo: Understand how to make this be more dynamic, or how to ensure that we don't exceed the buffer
    var validUserInput = false;
    var upperBound: u32 = undefined;

    while (!validUserInput) {
        try writeLine(writer, "What should the upper bound be? (Default 10). Just press enter to select the default value.");
        try readUserInputIntoBuffer(reader, &inputBuffer); //I'm worried that this will lead to leaks. However, the buffer seems to include the trailing delimiter, but no indication of how long the input was - or rather, I can't see it.
        upperBound = std.fmt.parseInt(u32, &inputBuffer, 10) catch {
            try writeLineWithArgs(writer, "Come on now behave. Enter a number. Greater than 0. You entered '{s}'. Try again.", .{&inputBuffer});
            continue;
        };
        validUserInput = true;
    }

    return upperBound;
}

// I don't love writer being an `anytype` here, since I know it has something to do with a `GenericWriter`, at least that's what I'm getting from the LSP. I'll have to deal with that later
fn writeLine(writer: anytype, comptime format: []const u8) !void {
    try writer.print(NEWLINE ++ format ++ NEWLINE, .{});
}

fn writeLineWithArgs(writer: anytype, comptime format: []const u8, args: anytype) !void {
    try writer.print(NEWLINE ++ format ++ NEWLINE, args);
}

fn readUserInputIntoBuffer(reader: anytype, inputBuffer: *[INPUT_BUFFER_SIZE]u8) !void {
    _ = try reader.readUntilDelimiter(inputBuffer, NEWLINE_DELIMETER); // return type is (NoEofError || error{StreamTooLong})![]u8.
    // todo: Don't include the delimeter in the output
}

const MAX_UTF_CHARACTER_BYTES: comptime_int = 4;
const MAX_SUPPORTED_INPUT_LENGTH: comptime_int = 10;
const INPUT_BUFFER_SIZE: comptime_int = MAX_UTF_CHARACTER_BYTES * MAX_SUPPORTED_INPUT_LENGTH;
const NEWLINE_DELIMETER: comptime_int = '\n';
const NEWLINE: *const [1:0]u8 = "\n";
