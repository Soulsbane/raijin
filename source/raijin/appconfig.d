/*
*   This module combines the functionality of keyvalueconfig and configpath into one class.
*/

module raijin.appconfig;

import raijin.keyvalueconfig;
import raijin.configpath;

/**
*	This class combines the functionality of keyvalueconfig and configpath into one class.
*/
class AppConfig
{
private:
	bool loadConfigFile(const string defaultConfigFileData = string.init)
	{
		import std.file : exists;

		immutable string configFilePath = buildNormalizedPath(configPath_.getConfigDir("config"), "app.config");

		if(!configFilePath.exists)
		{
			auto f = File(configFilePath , "w+"); // Create an empty config file and insert default data.
			f.writeln(defaultConfigFileData);
		}

		return configFile_.loadFile(configFilePath);
	}

public:
	this()
	{
		configPath_ = new ConfigPath;

		configPath_.createConfigDir("config");
		loadConfigFile();
	}

	this(const string organizationName, const string applicationName, const string defaultConfigFileData = string.init)
	{
		configPath_ = new ConfigPath(organizationName, applicationName);

		configPath_.createConfigDir("config");
		loadConfigFile(defaultConfigFileData);
	}

	ConfigPath path() @property
	{
		return configPath_;
	}

	KeyValueConfig config() @property
	{
		return configFile_;
	}

private:
	KeyValueConfig configFile_;
	ConfigPath configPath_;
}
