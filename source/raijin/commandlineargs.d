module raijin.commandlineargs;

import std.conv;
import std.string : split, removechars;
import std.traits : isNumeric, isBoolean;
import std.stdio : writeln;

public enum ProcessReturnValues { NOTPROCESSED, PROCESSED, INVALIDOPTION, NOARGS, HELP }

struct ArgValues
{
	string value;
	string description;
}

class CommandLineArgs
{
	final T get(T = string)(immutable string key) @safe
	{
		ArgValues defaultValues;

		if(isBoolean!T)
		{
			defaultValues.value = "false";
		}

		if(isNumeric!T)
		{
			defaultValues.value = "0";
		}

		auto values = values_.get(key, defaultValues);

		return to!T(values.value);
	}

	final T get(T = string)(immutable string key, string defaultValue) @safe
	{
		ArgValues defaultValues;
		defaultValues.value = defaultValue;
		auto values = values_.get(key, defaultValues);

		return to!T(values.value);
	}

	final string opIndex(immutable string key) @safe
	{
		return get(key);
	}

	final void opIndexAssign(string value, immutable string key) @safe
	{
		ArgValues values;
		values.value = value;

		values_[key] = values;
	}

	final bool contains(immutable string key) @safe
	{
		return cast(bool)(key in values_);
	}

	void printHelp() @trusted
	{
		writeln("The following options are available:");

		foreach(key, value; values_)
		{
			writeln("  --", key, ": ", value.description);
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
						ArgValues values;
						values.value = keyValue[1];

						values_[key] = values;
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
	static ArgValues[string] values_;
}
