/**
	Various functions for dealing with files.

	Author: Paul Crane
*/

module raijin.fileutils;

import std.file;
import std.path;
import std.stdio;
import std.string;
import std.typecons;

alias AppendMode = Flag!"appendMode";

/**
	Creates fileName if it dosn't exist or opens if it does exist.

	Params:
		fileName = Name of the file to create or open.
		mode = The mode to open the file in. Same as std.stdio.File. Opened in w+ by default.

	Returns:
		The File handle to the open file.
*/
File ensureFileExists(const string fileName, const string mode = "w+")
{
	if(!fileName.exists)
	{
		File(fileName, "w+");
	}

	return File(fileName, mode);
}

/**
	Removes fileName if it exists.

 	Params:
 		fileName = Name of the file to remove.

	Returns:
		true if the fileName was removed false otherwise.
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
 	Determines if fileName is hidden.

 	Params:
		fileName = Name of the file to check for hidden status.

	Returns:
		true if the fileName is hidden false otherwise.
*/
bool isFileHidden(const string fileName)
{
	if(fileName.baseName.startsWith("."))
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

///
unittest
{
	immutable string fileName = "unittest-ensure-test.txt";

	assert(fileName.ensureFileExists.isOpen);
	assert(fileName.removeFileIfExists);
}
