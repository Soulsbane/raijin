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

/**
*	Creates fileName if it dosn't exist or opens if it does exist.
*
*	Params:
*		fileName = Name of the file to create or open.
*		mode = Set to AppendMode.yes if the file should be opened in append mode.
*
*	Returns:
*		The File handle to the open file.
*/
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

/**
*	Removes fileName if it exists.
*
* 	Params:
* 		fileName = Name of the file to remove.
*
*	Returns:
*		true if the fileName was removed false otherwise.
*/
bool removeFileIfExists(const string fileName)
{
	if(fileName.exists)
	{
		fileName.remove;
	}

	return !fileName.exists;
}

/**
* 	Determines if fileName is hidden.
*
* 	Params:
*		fileName = Name of the file to check for hidden status.
*
*	Returns:
*		true if the fileName is hidden false otherwise.
*/
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
