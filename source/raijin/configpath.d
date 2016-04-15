/**
	Provides an easy way to work the users configuration directory.

	Authors:
		Paul Crane
*/
module raijin.configpath;

import std.path : buildNormalizedPath;
import std.file : mkdirRecurse, rmdirRecurse, exists;

/**
	Allows for the creation and deletion of directories in the users configuration directory.
*/
struct ConfigPath
{
	@disable this();

	/**
		Intializes the application name to executables name and setups up config directory using supplied arguments.

		Params:
			organizationName = Name of your organization.
			applicationName = Name of your application.
	*/
	this(const string organizationName, const string applicationName) @safe
	{
		import standardpaths : StandardPath, writablePath;

		organizationName_ = organizationName;
		applicationName_ = applicationName;

		configDirPath_ = writablePath(StandardPath.config);
	}

	/**
		Retrieves the path to the users config directory with an optional path appended to the end.

		Params:
			name = Name of the directory to retrieve.
	*/
	string getConfigDir(const string name) pure nothrow @safe const
	{
		return buildNormalizedPath(configDirPath_, organizationName_, applicationName_, name);
	}

	/**
		Retrieves the path to the users config directory.
	*/
	string getBaseConfigDir() pure nothrow @safe const
	{
		return buildNormalizedPath(configDirPath_, organizationName_, applicationName_);
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
	auto path = ConfigPath("DlangUnitOrg", "MyUnitTestApp");

	import std.stdio : writeln;

	writeln("Testing ConfigPath...");
	writeln(path.getConfigDir("tests"));
	writeln(path.getBaseConfigDir);

	writeln();
}
