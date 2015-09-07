module raijin.commandlineargs;

import std.conv;
import std.string : removechars, stripLeft, stripRight;
import std.traits : isNumeric, isBoolean;
import std.algorithm : findSplit;
import std.stdio : writeln;

public enum ProcessReturnValues { PROCESSED, INVALIDOPTION, INVALIDPAIR, NOARGS, HELP }

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

	final void addCommand(immutable string key, immutable string defaultValue, immutable string description) @safe
	{
		ArgValues values;
		values.value = defaultValue;
		values.description = description;

		values_[key] = values;
	}

	final void addCommand(immutable string key, immutable ArgValues values) @safe
	{
		values_[key] = values;
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

	final void opIndexAssign(ArgValues values, immutable string key) @safe
	{
		values_[key] = values;
	}

	final bool contains(immutable string key) @safe
	{
		return cast(bool)(key in values_);
	}

	void printHelp() @trusted
	{
		writeln("The following options are available:\n");

		foreach(key, value; values_)
		{
			writeln("  -", key, ": ", value.description);
		}

		writeln("  -help");
		writeln();
	}

	final ProcessReturnValues process(string[] arguments) @safe
	{
		auto elements = arguments[1 .. $]; // INFO: Remove program name.

		if(elements.length > 0)
		{
			if(elements[0].removechars("-") == "help")
			{
				printHelp();
				return ProcessReturnValues.HELP;
			}

			foreach(element; elements)
			{
				auto keyValuePair = element.findSplit("=");
	            auto key = keyValuePair[0].stripRight();
	            auto separator = keyValuePair[1];
	            auto value = keyValuePair[2].stripLeft();

				if(separator.length && value.length)
				{
					auto modifiedKey = key.removechars("--");

					if(contains(modifiedKey))
					{
						ArgValues values;
						values.value = value;

						values_[modifiedKey] = values;
					}
					else
					{
						return ProcessReturnValues.INVALIDOPTION;
					}
				}
				else
				{
					return ProcessReturnValues.INVALIDPAIR;
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
