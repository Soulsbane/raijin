/**
	Various functions for dealing with files.

	Authors:
		Paul Crane
*/

module raijin.utils.file;

import std.stdio;
import std.file : exists, write, remove;
import std.string : startsWith;
import std.path;
import std.file: exists, mkdirRecurse;
import std.algorithm;
import std.array;
import std.typetuple;
import std.typecons;

import raijin.utils;
alias OverwriteExtractedFiles = Flag!"OverwriteExtractedFiles";

/**
	Creates fileName if it doesn't exist.

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
	Removes the filename and recreates it.

	Params:
		fileName = Name of the file to recreate.
		defaultData = Data that should be writen after the file is created.

	Returns:
		True if the file was created false otherwise
*/
bool recreateFile(const string fileName, const string defaultData = string.init)
{
	removeFileIfExists(fileName);
	return ensureFileExists(fileName, defaultData);
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
	version(linux)
	{
		import std.path : baseName;
		if(fileName.baseName.startsWith("."))
		{
			return true;
		}
	}

	version(Windows)
	{
		import win32.winnt : getAttributes, FILE_ATTRIBUTE_HIDDEN;

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

	assert(fileName.ensureFileExists("data to write"));
	assert(fileName.removeFileIfExists);

	immutable string hiddenFile = ".ahiddenfile";

	assert(hiddenFile.ensureFileExists);
	assert(hiddenFile.isFileHidden);
	assert(hiddenFile.removeFileIfExists);

	immutable string nonHiddenFile = "aNonHiddenfile";

	assert(nonHiddenFile.ensureFileExists);
	assert(!nonHiddenFile.isFileHidden);
	assert(nonHiddenFile.removeFileIfExists);
}

private string getFilesList(T)(T list)
{
	return "TypeTuple!(" ~ list.map!(a => `"` ~ a ~ `"`).join(",") ~ ")";
}

private template GeneratorFileNames(string[] list)
{
	mixin("private alias GeneratorFileNames = " ~ getFilesList(list)~ ";");
}

/**
	Uses a list of files that will be imported using D's string import functionality. The string import for each files
	will then be written according to the path parameter and the name of the file in the file list.

	Note that you will need to set the string import path useing the -J switch if using DMD or the stringImportPaths
	configuration variable if using DUB.

	Params:
		list = Must be an enum string list of filenames that will be imported and written later using the same name.
		path = The path where the files should be exported to.

	Examples:
		enum filesList =
		[
			"resty/template.lua",
			"helpers.lua"
		];

		// Each file will be will be created in this format: ./myawesomeapp/resty/template.lua
		extractImportFiles!filesList("myawesomeapp");
*/
void extractImportFiles(alias list, T = string)(const string path, OverwriteExtractedFiles overwite = OverwriteExtractedFiles.yes)
{
	foreach(name; GeneratorFileNames!(list))
	{
		immutable string filePath = dirName(buildNormalizedPath(path, name));
		immutable string pathWithFileName = buildNormalizedPath(path, name);
		T content;

		static if(is(T : string))
		{
			content = import(name);
		}
		else
		{
			content = cast(T)import(name);
		}

		if(overwite)
		{
			removeFileIfExists(pathWithFileName);
		}

		ensurePathExists(filePath);
		ensureFileExists(pathWithFileName, content);
	}
}
