module raijin.configpath;

import std.path : buildNormalizedPath, baseName, stripExtension;
import std.file : exists, mkdirRecurse, thisExePath;

import standardpaths : writablePath, StandardPath;

class ConfigPath
{
    this()
    {
        applicationName_ = thisExePath.baseName.stripExtension;
        configDirPath_ = writablePath(StandardPath.Config);
    }

    this(const string organizationName, const string applicationName)
    {
        organizationName_ = organizationName;
        applicationName_ = applicationName;
        configDirPath_ = writablePath(StandardPath.Config);
    }

    string getConfigDir(string name = string.init)
    {
        if(name == string.init)
        {
            return buildNormalizedPath(configDirPath_, organizationName_, applicationName_);
        }
        return buildNormalizedPath(configDirPath_, organizationName_, applicationName_, name);
    }

    void createConfigDir(const string name = string.init)
    {
        string normalPath = buildNormalizedPath(getConfigDir(name));

        if(!exists(normalPath))
        {
            mkdirRecurse(normalPath);
        }
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
