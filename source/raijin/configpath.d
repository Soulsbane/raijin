/**
	Provides an easy way to work the users configuration directory.

	Author: Paul Crane
*/
module raijin.configpath;

import std.path;
import std.file;

import standardpaths;

/**
	Allows for the creation and deletion of directories in the users configuration directory.
*/
class ConfigPath
{
	/**
		Intializes the application name to executables name and setups up config directory.
	*/
	this() @safe
	{
		applicationName_ = thisExePath.baseName.stripExtension;
		configDirPath_ = writablePath(StandardPath.Config);
	}

	/**
		Intializes the application name to executables name and setups up config directory using supplied arguments.

		Params:
			organizationName = Name of your organization.
			applicationName = Name of your application.
	*/
	this(const string organizationName, const string applicationName) @safe
	{
		organizationName_ = organizationName;
		applicationName_ = applicationName;
		configDirPath_ = writablePath(StandardPath.Config);
	}

	/**
		Retries the path to the users config directory with an optional path appended to the end.

		Params:
			name = Name of the directory to retrieve.
	*/
	string getConfigDir(const string name = string.init) pure nothrow @safe const
	{
		if(name == string.init)
		{
			return buildNormalizedPath(configDirPath_, organizationName_, applicationName_);
		}

		return buildNormalizedPath(configDirPath_, organizationName_, applicationName_, name);
	}

	/**
		Creates a directory in the users config directory.

		Params:
			name = Name of the directory to create.
	*/
	void createConfigDir(const string name = string.init) @trusted
	{
		immutable string normalPath = buildNormalizedPath(getConfigDir(name));

		if(!exists(normalPath))
		{
			mkdirRecurse(normalPath);
		}
	}

	/**
		Removes a directory from the users config directory.

		Params:
			name = Name of the directory to remove.
	*/
	void removeConfigDir(const string name) @trusted
	{
		immutable string normalPath = buildNormalizedPath(getConfigDir(name));

		if(exists(normalPath))
		{
			rmdirRecurse(normalPath);
		}
	}

private:

	string organizationName_;
	string applicationName_;
	string configDirPath_;
}

///
unittest
{
	auto path = new ConfigPath("DlangUnitOrg", "MyUnitTestApp");
	auto pathNoOrganization = new ConfigPath;

	import std.stdio;
	writeln("Testing ConfigPath class...");
	writeln(path.getConfigDir("tests"));
	writeln(pathNoOrganization.getConfigDir("tests"));

	writeln();
}
