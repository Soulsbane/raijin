/**
	Various functions for dealing with files.

	Authors:
		Paul Crane
*/

module raijin.utils.file;

import std.file : exists, write, remove;
import std.string : startsWith;

/**
	Creates fileName if it dosn't exist.

	Params:
		fileName = Name of the file to create or open.
		defaultData = Data that should be writen after the file is created.

	Returns:
		True if the file was created false otherwise
*/
bool ensureFileExists(const string fileName, const string defaultData = string.init)
{
	if(!fileName.exists)
	{
		import std.stdio : File;
		auto f = File(fileName, "w+");

		if(defaultData != string.init)
		{
			f.write(defaultData);
		}
	}

	return fileName.exists;
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
	version(Linux)
	{
		import std.path : baseName;
		if(fileName.baseName.startsWith("."))
		{
			return true;
		}
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

	assert(fileName.ensureFileExists);
	assert(fileName.removeFileIfExists);
}
