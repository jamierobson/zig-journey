// Creates an executable

const std = @import("std");
const GenericWriter = std.io.GenericWriter;
// const Tuple: std.meta.Tuple(comptime types: []const type)

pub fn main() !void {
    const stdIn = std.io.getStdIn().reader();
    const stdOut = std.io.getStdOut().writer();
    var inputBuffer: [INPUT_BUFFER_SIZE]u8 = undefined;
    try writeLine(stdOut, "Let's play the guessing game. The lower bound will be 1.");
    const upperBound = try getUpperBound(&inputBuffer, stdIn, stdOut);

    try writeLineWithArgs(stdOut, "Ok, let's play! Guess a number between 1 and {}", .{upperBound});

    // const targetNumber: u32 = std.rand.DefaultPrng.init().random().int(u32);

    try writeLine(stdOut, "Try guessing at my number now!");
}

pub fn getNumericUserInput(inputBuffer: *[INPUT_BUFFER_SIZE]u8, reader: anytype) NumericUserInputError!u32 {
    readUserInputIntoBuffer(reader, inputBuffer) catch {
        return error.BufferError;
    };
    const consumedBufferSlice = extractUserInputSlice(inputBuffer) catch {
        return error.BufferError;
    };

    if (consumedBufferSlice.len == 0) {
        return error.NoInput;
    }

    const parsedInput = std.fmt.parseInt(u32, consumedBufferSlice, 10) catch |err| {
        switch (err) {
            error.InvalidCharacter => return error.InvalidCharacter,
            error.Overflow => return error.OutOfRange,
            else => unreachable,
        }
    };

    return parsedInput;
}

pub fn getUpperBound(inputBuffer: *[INPUT_BUFFER_SIZE]u8, reader: anytype, writer: anytype) !u32 {
    while (true) {
        try writeLineWithArgs(writer, "What should the upper bound be? (Default {}). Just press enter to select the default value.", .{DEFAULT_UPPER_COUNT});

        const upperBound = getNumericUserInput(inputBuffer, reader) catch |err| {
            switch (err) {
                error.InvalidCharacter => try writeLineWithArgs(writer, "Come on now behave. Enter a number. Greater than 1, less than, or equal to, {}. You entered '{c}'. Try again.", .{ std.math.maxInt(u32), inputBuffer }),
                error.OutOfRange => try writeLineWithArgs(writer, "You entered a number too big. Choose a number between 1 and {}. You entered '{c}'. Try again.", .{ std.math.maxInt(u32), inputBuffer }),
                error.Overflow => try writeLine(writer, "You wrote too much, I couldn't handle it and had to give up. Try again"),
                error.NoInput => return DEFAULT_UPPER_COUNT,
            }

            continue;
        };

        if (upperBound <= 1) {
            try writeLineWithArgs(writer, "Seriously? {}? Try again. Greater than 1, this time.", .{upperBound});
            continue;
        }

        return upperBound;
    }
}

fn extractUserInputSlice(buffer: []u8) ![]u8 {
    var firstUndefinedIndex = buffer.len - 1;
    for (buffer, 0..) |element, index| {
        if (element == UNDEFINED_CHARACTER) {
            firstUndefinedIndex = index;
            break;
        }
    }
    return buffer[0..firstUndefinedIndex];
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

    for (
        0..inputBuffer.len,
    ) |index| {
        if (index == inputBuffer.len) {
            break;
        }

        if (inputBuffer[index] == RETURN_DELIMETER and inputBuffer[index + 1] == NEWLINE_DELIMETER) {
            inputBuffer[index] = undefined;
            inputBuffer[index + 1] = undefined;
            break;
        }
    }
}

const MAX_UTF_CHARACTER_BYTES: comptime_int = 4;
const MAX_SUPPORTED_INPUT_LENGTH: comptime_int = 10;
const INPUT_BUFFER_SIZE: comptime_int = MAX_UTF_CHARACTER_BYTES * MAX_SUPPORTED_INPUT_LENGTH;
const NEWLINE_DELIMETER: comptime_int = '\n';
const RETURN_DELIMETER: comptime_int = '\r';
const NEWLINE: *const [1:0]u8 = "\n";
const UNDEFINED_CHARACTER: comptime_int = 0xAA;
const DEFAULT_UPPER_COUNT: comptime_int = 10;

const NumericUserInputError = error{ OutOfRange, BufferError, InvalidCharacter, NoInput };
