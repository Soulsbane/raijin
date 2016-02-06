/**
	Various functions for dealing with path based manipulation and retrieval.

	Author: Paul Crane
*/

module raijin.pathutils;

import std.process : environment;
import std.path;
import std.stdio;
import std.file;
import std.algorithm : splitter;
import std.string;

/**
	Determines if executableName is in the user's path.

	Params:
		executableName = Name of the executable to look for.

	Returns:
		The path to the executable if found otherwise null.
*/
string isInPath(const string executableName) @safe
{
	version(windows)
	{
		enum separator = ";";
	}
	else
	{
		enum separator = ":";
	}

	foreach(dir; splitter(environment["PATH"], separator))
	{
		auto path = dir.buildNormalizedPath(executableName);

		if(path.exists)
		{
			return path;
		}
	}

	return null;
}

/**
	Ensures a directory path exists by creating it if it does not already exist.

	Params:
		path = string containing the path to create.

	Returns:
		true if path was created false otherwise.
*/
bool ensurePathExists(const string path) @trusted
{
	if(!path.exists)
	{
		path.mkdirRecurse;
	}

	return path.exists;
}

/**
	Ensures a directory path exists by creating it if it does not already exist.

	Params:
		args = Variable number of argument strings containing the path to create.

	Returns:
		true if path was created false otherwise.
*/
bool ensurePathExists(T...)(T args) @trusted
{
	immutable string path = buildNormalizedPath(args);

	if(!path.exists)
	{
		path.mkdirRecurse;
	}

	return path.exists;
}

/**
	Remove the path if it exists.

	Params:
		path = path to create.
*/
bool removePathIfExists(const string path) @trusted
{
	if(path.exists)
	{
		path.rmdirRecurse;
	}

	return !path.exists;
}

/**
	Remove the path if it exists.

	Params:
		args = Variable number of strings that compose the path.
*/
bool removePathIfExists(T...)(T args) pure nothrow @safe
{
	immutable string path = buildNormalizedPath(args);

	if(path.exists)
	{
		path.rmdirRecurse;
	}

	return !path.exists;
}

/**
	Retrieves the complete path where the application resides.
*/
string getAppPath() @safe
{
	return dirName(thisExePath());
}

/**
	Retrieves the complete path where the application resides with the provided path appended.

	Params:
		path = The path to append to the application path.
*/
string getAppPath(string[] path...) @safe
{
	return buildNormalizedPath(dirName(thisExePath()) ~ path);
}

///
unittest
{
	immutable string notFound =  isInPath("fakeprogram");
	immutable string found =  isInPath("ls");

	assert(found.length);
	assert(notFound == null);
	assert(ensurePathExists("my", "test", "dir"));
	assert(removePathIfExists("my"));
	assert(ensurePathExists("my/test/dir"));
	assert(removePathIfExists("my"));
}
