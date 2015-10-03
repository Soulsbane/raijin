module raijin.configpath;

import std.path : buildNormalizedPath, baseName, stripExtension;
import std.file : exists, mkdirRecurse, thisExePath;

import standardpaths : writablePath, StandardPath;

class ConfigPath
{
    this()
    {
        applicationName_ = thisExePath.baseName.stripExtension;
    }

    this(immutable string organizationName, immutable string applicationName)
    {
        organizationName_ = organizationName;
        applicationName_ = applicationName;
    }

    string getConfigDir(immutable string name = string.init)
    {
        if(name == string.init)
        {
            return buildNormalizedPath(writablePath(StandardPath.Config), organizationName_, applicationName_);
        }
        return buildNormalizedPath(writablePath(StandardPath.Config), organizationName_, applicationName_, name);
    }

    void createConfigDir(immutable string name = string.init)
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
