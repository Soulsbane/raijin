/**
*   At present only a function for outputing a debug string.
*/

module raijin.debugutils;

import std.stdio;
import std.algorithm;
import std.path;
import std.datetime;

/**
*   Outputs a message to stdout with function name, line number and file name.
*
*   Params:
*       msg = The message to be print to stdout.
*		lineNumber = __LINE__
*		fileName = __FILE__
*		funcName = __FUNCTION__
*/
void debugLog(const string msg, const int lineNumber = __LINE__, const string fileName = __FILE__,
	const string funcName = __FUNCTION__) @trusted
{
	debug writefln("%s - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
}

struct Log
{
	static void info(const string msg, const int lineNumber = __LINE__, const string fileName = __FILE__,
		const string funcName = __FUNCTION__) @trusted
	{
		debug writefln("[INFO] %s - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
	}
	static void warn(const string msg, const int lineNumber = __LINE__, const string fileName = __FILE__,
		const string funcName = __FUNCTION__) @trusted
	{
		debug writefln("[WARN] %s - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
	}
	static void error(const string msg, const int lineNumber = __LINE__, const string fileName = __FILE__,
		const string funcName = __FUNCTION__) @trusted
	{
		debug writefln("[ERROR] %s - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
	}
}
