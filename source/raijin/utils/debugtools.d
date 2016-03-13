/**
*   Functions for outputing a debug string.
*
*	Authors:
		Paul Crane
*/

module raijin.utils.debugtools;

import std.stdio;
import std.algorithm;
import std.path;
import std.datetime;
import std.string;
import std.array;

/**
*	Wrapper around info, warn and error functions that acts as a namespace.
*/
struct Log
{
	/**
		Outputs a message to stdout marked as type info with function name, line number, time and file name attached.

		Params:
			lineNumber = __LINE__
			fileName = __FILE__
			funcName = __FUNCTION__
			msg = The message to be print to stdout.
	*/
	static void info(const string fileName = __FILE__, const string funcName = __FUNCTION__,
		const int lineNumber = __LINE__, const string msg = "<None>") @trusted
	{
		debug writefln("INFO [%s] - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
	}

	/**
		Outputs a message to stdout marked as type warn with function name, line number, time and file name attached.

		Params:
			lineNumber = __LINE__
			fileName = __FILE__
			funcName = __FUNCTION__
			msg = The message to be print to stdout.
	*/
	static void warn(const string fileName = __FILE__, const string funcName = __FUNCTION__,
		const int lineNumber = __LINE__, const string msg = "<None>") @trusted
	{
		debug writefln("WARN [%s] - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
	}

	/**
		Outputs a message to stdout marked as type error with function name, line number, time and file name attached.

		Params:
			lineNumber = __LINE__
			fileName = __FILE__
			funcName = __FUNCTION__
			msg = The message to be print to stdout.
	*/
	static void error(const string fileName = __FILE__, const string funcName = __FUNCTION__,
		const int lineNumber = __LINE__, const string msg = "<None>") @trusted
	{
		debug writefln("ERROR [%s] - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
	}
}

///
unittest
{
	Log.info("This is a info test");
	Log.warn("This is a warn test");
	Log.error("This is a error test");
}

/**
	A debug function for outputing each argument with a space in between. Useful for printing multiple variables.

	Params:
		args = The arguments(variables) that should be printed.
*/
void printArgs(T...)(T args)
{
	import std.conv;

	write(concatArgs(args));
	writeln;

}

///
unittest
{
	printArgs("hello", "world");
	printArgs(1234, 5678, 9);
	printArgs(1234, true, 9);
}

/**
	A debug function for outputing each argument with a space in between. Useful for printing multiple variables.

	Params:
		args = The arguments(variables) that should be printed.
*/
string concatArgs(T...)(T args)
{
	import std.conv;

	string output;

	foreach(arg; args)
	{
		output ~= to!string(arg) ~ " ";
	}

	return output.stripRight;

}

///
unittest
{
	assert(concatArgs(1, 2, 3, 4) == "1 2 3 4");
	assert(concatArgs(true, "blah", 54) == "true blah 54");
}

/**
	Prints the line number only along with an optional message.

	Params:
		msg = Message to print.
		lineNumber = __LINE__ by default.
*/
void printLineNumber(const string msg = string.init, const int lineNumber = __LINE__)
{
	debug writefln("%s => %d", msg, lineNumber);
}

///
unittest
{
	printLineNumber("Printing line number");
	printLineNumber();
}
