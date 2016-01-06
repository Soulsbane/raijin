/**
*	Provides an easy way to work the users configuration directory.
*/
module raijin.configpath;

import std.path : buildNormalizedPath, baseName, stripExtension;
import std.file : exists, mkdirRecurse, thisExePath;

import standardpaths : writablePath, StandardPath;

/**
*	Allows for the creation and deletion of directories in the users configuration directory.
*/
class ConfigPath
{
	/**
	*	Intializes the application name to executables name and setups up config directory.
	*/
	this()
	{
		applicationName_ = thisExePath.baseName.stripExtension;
		configDirPath_ = writablePath(StandardPath.Config);
	}

	/**
	*	Intializes the application name to executables name and setups up config directory using supplied arguments.
	*
	*	Params:
	*		organizationName = Name of your organization.
	*		applicationName = Name of your application.
	*/
	this(const string organizationName, const string applicationName)
	{
		organizationName_ = organizationName;
		applicationName_ = applicationName;
		configDirPath_ = writablePath(StandardPath.Config);
	}

	/**
	*	Retries the path to the users config directory with an optional path appended to the end.
	*
	*	Params:
	*		name = Name of the directory to retrieve.
	*/
	string getConfigDir(const string name = string.init)
	{
		if(name == string.init)
		{
			return buildNormalizedPath(configDirPath_, organizationName_, applicationName_);
		}

		return buildNormalizedPath(configDirPath_, organizationName_, applicationName_, name);
	}

	/**
	*	Creates a directory in the users config directory.
	*
	*	Params:
	*		name = Name of the directory to create.
	*/
	void createConfigDir(const string name = string.init)
	{
		string normalPath = buildNormalizedPath(getConfigDir(name));

		if(!exists(normalPath))
		{
			mkdirRecurse(normalPath);
		}
	}

	/**
	*	Removes a directory from the users config directory.
	*
	*	Params:
	*		name = Name of the directory to remove.
	*/
	void removeConfigDir(const string name)
	{
	}

private:

	string organizationName_;
	string applicationName_;
	string configDirPath_;
}

unittest
{
	auto path = new ConfigPath("DlangUnitOrg", "MyUnitTestApp");

	import std.stdio;
	writeln("Testing ConfigPath class...");
	writeln(path.getConfigDir("tests"));
	writeln();
}
