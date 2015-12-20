/*
*	Various functions for dealing with files.
*/

module raijin.fileutils;

import std.file;
import std.path;
import std.stdio;
import std.string;
import std.typecons;

alias AppendMode = Flag!"appendMode";

File ensureFileExists(const string fileName, AppendMode mode = AppendMode.no)
{
	if(fileName.exists)
	{
		if(mode)
		{
			return File(fileName, "a+");
		}

		return File(fileName, "r+");
	}
	else
	{
		if(mode)
		{
			return File(fileName, "a+");
		}

		return File(fileName, "w+");
	}
}

bool removeFileIfExists(const string fileName)
{
	if(fileName.exists)
	{
		fileName.remove;
	}

	return !fileName.exists;
}

bool isFileHidden(const string fileName)
{
	if (fileName.baseName.startsWith("."))
	{
		return true;
	}

	version(Windows)
	{
		import win32.winnt;
		if (getAttributes(fileName) & FILE_ATTRIBUTE_HIDDEN)
		{
			return true;
		}
	}
	return false;
}

unittest
{
	immutable string fileName = "unittest-ensure-test.txt";

	assert(fileName.ensureFileExists.isOpen);
	assert(fileName.removeFileIfExists);
}
