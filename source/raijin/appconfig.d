/**
	This module combines the functionality of KeyValueConfig and ConfigPath into one class.

	Authors: Paul Crane
*/

module raijin.appconfig;

import raijin.keyvalueconfig : KeyValueConfig;
import raijin.configpath : ConfigPath;

/**
	This class combines the functionality of KeyValueConfig and ConfigPath into one class.
*/
struct AppConfig
{
private:

	/**
		Loads app.config file and populates it with defaultConfigFileData if app.config isn't found.

		Params:
			defaultConfigFileData = The data app.config should be populated with if app.config isn't found.

		Returns:
			true of the config file was successfully loaded false otherwise.
	*/
	bool loadConfigFile(const string defaultConfigFileData = string.init) @safe
	{
		import std.path : buildNormalizedPath;
		import std.file : exists;
		import std.stdio : writeln, File;

		immutable string configFilePath = buildNormalizedPath(configPath_.getConfigDir("config"), "app.config");

		if(!configFilePath.exists)
		{
			auto f = File(configFilePath , "w+"); // Create an empty config file and insert default data.
			f.writeln(defaultConfigFileData);
		}

		return configFile_.loadFile(configFilePath);
	}

public:


	/**
		Sets up config directory and files.

		Params:
			organizationName = Name of the organization/company.
			applicationName = Name of the application.
			defaultConfigFileData = The data app.config should be populated with if app.config isn't found.
	*/
	this(const string organizationName, const string applicationName,
		const string defaultConfigFileData = string.init) @safe
	{
		create(organizationName, applicationName, defaultConfigFileData);
	}

	/**
		Sets up config directory and files.

		Params:
			organizationName = Name of the organization/company.
			applicationName = Name of the application.
			defaultConfigFileData = The data app.config should be populated with if app.config isn't found.
	*/
	void create(const string organizationName, const string applicationName,
		const string defaultConfigFileData = string.init) @safe
	{
		configPath_.create(organizationName, applicationName);

		configPath_.createConfigDir("config");
		configPath_.createConfigDir("assets");

		loadConfigFile(defaultConfigFileData);
	}
	/**
		Helper property for accessing ConfigPath methods.

		Returns:
			A ConfigPath object.
	*/
	ConfigPath path() @property
	{
		return configPath_;
	}

	/**
		Helper property for accessing KeyValueConfig methods.

		Returns:
			A KeyValueConfig object.
	*/
	KeyValueConfig config() @property
	{
		return configFile_;
	}

private:
	KeyValueConfig configFile_;
	ConfigPath configPath_;
}

unittest
{
	
}
