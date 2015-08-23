module raijin.commandlineargs;

import std.conv;
import std.string : split, removechars;
import std.traits : isNumeric, isBoolean;
import std.stdio : writeln;

public enum ProcessReturnValues { NOTPROCESSED, PROCESSED, INVALIDOPTION, NOARGS, HELP }

class CommandLineArgs
{
public:
	final T get(T = string)(immutable string key) @safe
	{
		string defaultValue;

		if(isBoolean!T)
		{
			defaultValue = "false";
		}

		if(isNumeric!T)
		{
			defaultValue = "0";
		}

		return to!T(values_.get(key, defaultValue));
	}

	final T get(T = string)(immutable string key, string defaultValue) @safe
	{
		return to!T(values_.get(key, defaultValue));
	}

	final string opIndex(immutable string key) @safe
	{
		return get(key);
	}

	final void opIndexAssign(string value, immutable string key) @safe
	{
		values_[key] = value;
	}

	final bool contains(immutable string key) @safe
	{
		if(key in values_)
		{
			return true;
		}
		return false;
	}

	void printHelp() @trusted // NOTE: This should really be overriden since the default is very minimal.
	{
		writeln("The following options are available:");

		foreach(key; values_.byKey)
		{
			writeln("  --", key);
		}

		writeln("  --help");
		writeln();
	}

	final ProcessReturnValues process(string[] arguments) @safe
	{
		auto elements = arguments[1 .. $]; // INFO: Remove program name.

		if(elements.length > 0)
		{
			if(elements[0] == "--help")
			{
				// Call inherited help function
				printHelp();
				return ProcessReturnValues.HELP;
			}

			foreach(element; elements)
			{
				auto keyValue = element.split("=");

				if(keyValue.length > 1)
				{
					auto key = keyValue[0].removechars("--");

					if(contains(key))
					{
						values_[key] = keyValue[1];
					}
					else
					{
						return ProcessReturnValues.INVALIDOPTION;
					}
				}
				else
				{
					return ProcessReturnValues.INVALIDOPTION;
				}
			}

			return ProcessReturnValues.PROCESSED;
		}
		else
		{
			return ProcessReturnValues.NOARGS;
		}
	}

private:
	static string[string] values_;
}
