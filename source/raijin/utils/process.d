/**
	Small wrapper functions for std.process functions.

	Authors:
		Paul Crane
*/
module raijin.utils.process;

import std.process;
import std.file;
import std.array;
import std.exception;

import raijin.utils.path;

// BUG: DMD can't infer a return type for both launchApplication functions without this.
alias LaunchApplicationReturnType = std.typecons.Tuple!(int, "status", string, "output");

/**
	Small wrapper function that launches an application using std.process.executeShell.

	Params:
		fileName = Name of the application to launch.
		args = The arguments to the program.

	Returns:
		Returns the same tuple as $(LINK2 http://dlang.org/phobos/std_process.html#executeShell, std.process.executeShell)
*/
LaunchApplicationReturnType  launchApplication(const string fileName, const string[] args...) @safe
{
	return launchApplication(fileName, args.join(' '));
}

/**
	Small wrapper function that launches an application using std.process.executeShell.

	Params:
		fileName = Name of the application to launch.
		args = The arguments to the program.

	Returns:
		Returns the same tuple as $(LINK2 http://dlang.org/phobos/std_process.html#executeShell, std.process.executeShell)
*/
LaunchApplicationReturnType launchApplication(const string fileName, const string args) @safe
{
	auto result = std.typecons.Tuple!(int, "status", string, "output")(127, "Executable not found.");
	immutable auto inPath = isInPath(fileName);
	immutable string fileNameAndArgs = fileName ~ ' ' ~ args;

	if(fileName.exists)
	{
		return executeShell(fileNameAndArgs).ifThrown!Exception(result);
	}
	else if(inPath.length)
	{
		return executeShell(fileNameAndArgs).ifThrown!Exception(result);
	}
	else
	{
		return result;
	}
}

///
unittest
{
	version(Linux)
	{
		auto result = launchApplication("ls", "-l");
		assert(result.status == 0);

		auto result2 = launchApplication("ls", "-l", "-h");
		assert(result2.status == 0);
	}
}
