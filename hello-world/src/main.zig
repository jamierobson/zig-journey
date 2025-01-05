// Creates an executable

const std = @import("std");
const GenericWriter = std.io.GenericWriter;

pub fn main() !void {
    const stdIn = std.io.getStdIn().reader();
    const stdOut = std.io.getStdOut().writer();

    try writeLine(stdOut, "Let's play the guessing game. The lower bound will be 1.");
    _ = try getUpperBound(stdIn, stdOut);
}

pub fn getUpperBound(reader: anytype, writer: anytype) !u8 {
    var inputBuffer: [INPUT_BUFFER_SIZE]u8 = undefined; // todo: Understand how to make this be more dynamic, or how to ensure that we don't exceed the buffer

    try writeLine(writer, "What should the upper bound be? (Default 10). Just press enter to select the default value.");

    try readUserInputIntoBuffer(reader, &inputBuffer);

    // if too long, write a message like "too long"
    // if cant parse as an int, then try writeSassyMessage(writer);
    // otherwise we can return the user input

    try writeLineWithArgs(writer, "you entered: {s}", .{inputBuffer});

    return 42;
}

// I don't love writer being an `anytype` here, since I know it has something to do with a `GenericWriter`, at least that's what I'm getting from the LSP. I'll have to deal with that later
fn writeLine(writer: anytype, comptime format: []const u8) !void {
    try writer.print("\n" ++ format ++ "\n", .{});
}

fn writeLineWithArgs(writer: anytype, comptime format: []const u8, args: anytype) !void {
    try writer.print("\n" ++ format ++ "\n", args);
}

fn readUserInputIntoBuffer(reader: anytype, inputBuffer: *[INPUT_BUFFER_SIZE]u8) !void {
    _ = try reader.readUntilDelimiter(inputBuffer, '\n'); // return type is (NoEofError || error{StreamTooLong})![]u8.

    // todo: readUntilDelimiterAlloc is the one we want I think. It's return type is (Error || Allocator.Error || error{StreamTooLong})!?[]u8

}

fn writeSassyMessage(writer: anytype) !void {
    try writeLine(writer, "come on now, behave yourself. Let's try again");
}

const MAX_UTF_CHARACTER_BYTES: comptime_int = 4;
const MAX_SUPPORTED_INPUT_LENGTH: comptime_int = 10;
const INPUT_BUFFER_SIZE: comptime_int = MAX_UTF_CHARACTER_BYTES * MAX_SUPPORTED_INPUT_LENGTH;
