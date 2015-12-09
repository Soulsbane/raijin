/*
*   This module combines the functionality of keyvalueconfig and configpath into one class.
*/

module raijin.appconfig;

import raijin.keyvalueconfig;
import raijin.configpath;

class AppConfig
{
private:

    void loadConfigFile(const string defaultConfigFileData = string.init)
    {
        import std.file : exists;

        string text;
        immutable string configFilePath = buildNormalizedPath(configPath_.getConfigDir("config"), "app.config");

        if(exists(configFilePath))
        {
            text = readText(configFilePath);
        }
        else
        {
            auto f = File(configFilePath , "w+"); // Create an empty config file and insert default data.
            f.writeln(defaultConfigFileData);
        }

        immutable bool loaded = configFile_.loadFile(configFilePath);

        if(!loaded)
        {
            debug
            {
                writeln("FAILED to load configuration file!");
            }
        }
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

    KeyValueConfig file() @property
    {
        return configFile_;
    }

private:
    KeyValueConfig configFile_;
    ConfigPath configPath_;
}
