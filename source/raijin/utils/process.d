/**
	Small wrapper functions for std.process functions.

	Authors:
		Paul Crane
*/
module raijin.utils.process;

import std.exception : ifThrown;
import std.typecons : Tuple;

import raijin.utils.path : isInPath;

// BUG: DMD can't infer a return type for both launchApplication functions without this.
alias LaunchApplicationReturnType = Tuple!(int, "status", string, "output");

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
	import std.array : join;
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
	import std.file : exists;
	import std.process : executeShell;

	auto result = Tuple!(int, "status", string, "output")(127, "Executable not found.");
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
	version(linux)
	{
		auto result = launchApplication("ls", "-l -h");
		assert(result.status == 0);

		auto result2 = launchApplication("ls", "-l", "-h");
		assert(result2.status == 0);

		auto errorResult = launchApplication("ls2lss", "-l -h");
		assert(errorResult.status == 127);

		auto errorResult2 = launchApplication("ls2lss", "-l", "-h");
		assert(errorResult2.status == 127);

		import raijin.utils.file: ensureFileExists, removeFileIfExists;

		ensureFileExists("myprocessapp");
		auto fileNameResult = launchApplication("./myprocessapp", "-l", "-h");
		assert(fileNameResult.status == 126);
		removeFileIfExists("myprocessapp");
	}
}
