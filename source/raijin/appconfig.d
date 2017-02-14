/**
	This module combines the functionality of KeyValueConfig and ConfigPath into one class.

	Authors: Paul Crane
*/

module raijin.appconfig;

import raijin.types.dynamic;
import raijin.keyvalueconfig;
import raijin.configpath : ConfigPath;
import std.path : buildNormalizedPath;
import std.file : exists;

/**
	This class combines the functionality of KeyValueConfig and ConfigPath into one class.
*/
struct AppConfig
{
private:

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
		Loads app.config file and populates it with defaultConfigFileData if app.config isn't found.

		Params:
			defaultConfigFileData = The data app.config should be populated with if app.config isn't found.

		Returns:
			true of the config file was successfully loaded false otherwise.
	*/
	bool loadConfigFile(const string defaultConfigFileData = string.init)
	{
		immutable string configFilePath = buildNormalizedPath(configPath_.getConfigDir("config"), "app.config");


		ensureFileExists(configFilePath, defaultConfigFileData);
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
		const string defaultConfigFileData = string.init)
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
		const string defaultConfigFileData = string.init)
	{
		configPath_.create(organizationName, applicationName);

		configPath_.createConfigDir("config");
		configPath_.createConfigDir("assets");

		loadConfigFile(defaultConfigFileData);
	}

	//INFO: Because ConfigPath and KeyValueConfig have different member names we can enable a little syntactic super for
	// calling their methods without using their properties.
	auto opDispatch(string functionName, T...)(T args)
	{
		static if(__traits(hasMember, ConfigPath, functionName))
		{
			return mixin("configPath_." ~ functionName ~ "(args)");
		}
		else
		{
			return mixin("configFile_." ~ functionName ~ "(args)");
		}
	}

	DynamicType opIndex(const string key)
	{
		return configFile_.get(key);
	}

	void opIndexAssign(T)(T value, const string key)
	{
		configFile_.set(key, value);
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

///
unittest
{
	import std.stdio : writeln;

	writeln;
	writeln("<=====================Beginning test for appconfig module=====================>");

	string data =
	q{
		key=value
	};

	AppConfig config;

	config.create("DlangUnitOrg", "AppConfigUnitTest", data);
	writeln(config.path.getAppConfigDir());
	assert(config.asString("key") == "value");

	config.path.removeAllConfigDirs();

	AppConfig config2 = AppConfig("DlangUnitOrg", "AppConfigUnitTest", data);

	writeln(config2.path.getAppConfigDir());
	writeln(config2.getAppConfigDir()); // Sugar! Uses opDispatch.

	assert(config2.config["key"] == "value");
	assert(config2.asString("key") == "value"); // Sugar! Uses opDispatch.

	config2.path.removeAllConfigDirs();
}
