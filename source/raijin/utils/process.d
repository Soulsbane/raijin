module raijin.utils.process;

import std.process;
import std.file;
import std.array;
import std.exception;

import raijin.utils.path;

auto launchApplication(const string fileName, const string[] args...)
{
	auto result = std.typecons.Tuple!(int, "status", string, "output")(127, "Executable not found.");
	immutable auto inPath = isInPath(fileName);
	immutable string fileNameAndArgs = fileName ~ ' ' ~ args.join(' ');

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
