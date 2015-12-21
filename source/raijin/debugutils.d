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
*/
void debugLog(const string msg, const int lineNumber = __LINE__, const string fileName = __FILE__,
	const string funcName = __FUNCTION__) @trusted
{
	debug writefln("%s - %s[%s](%d): %s", Clock.currTime, fileName.baseName, funcName.findSplitAfter(".")[1], lineNumber, msg);
}
