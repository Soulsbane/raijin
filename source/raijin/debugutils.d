/**
*   Functions for outputing a debug string.
*
*	Author: Paul Crane
*/

module raijin.debugutils;

import std.stdio;
import std.algorithm;
import std.path;
import std.datetime;

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
void print(T)(T[] args...)
{
	import std.conv;

	args.each!(a => write(to!string(a), " "));
	writeln;
}

unittest
{
	print("hello", "world");
	print(1234, 5678, 9);
}
