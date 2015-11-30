/*
    Various functions for dealing with path based manipulation and retrieval.
*/

module raijin.pathutils;

import std.process : environment;
import std.path : pathSeparator, buildPath;
import std.file : exists;
import std.algorithm : splitter;

/**
*   Determines if executableName is in the user's path.
*
*   Params:
*       executableName = Name of the executable to look for.
*
*   Returns:
*       The path to the executable if found otherwise null.
*/
string isInPath(const string executableName)
{
    version(windows)
    {
        enum separator = ";";
    }
    else
    {
        enum separator = ":";
    }

    foreach(dir; splitter(environment["PATH"], separator))
    {
        auto path = buildPath(dir, executableName);

        if(exists(path))
        {
            return path;
        }
    }

    return null;
}
