module raijin.commandlineargs;

import std.conv : to;
import std.string : removechars, stripLeft, stripRight;
import std.traits : isNumeric, isBoolean;
import std.algorithm : findSplit;
import std.stdio : writeln;

public enum CommandLineArgTypes { VALID_ARG, INVALID_ARG, INVALID_ARG_PAIR, FLAG_ARG, NO_ARGS, HELP_ARG }

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

	void onPrintHelp() @trusted
	{
		writeln("The following options are available:\n");

		foreach(key, value; values_)
		{
			writeln("  -", key, ": ", value.description);
		}

		writeln("  -help");
		writeln();
	}

	void onInvalidArgs(CommandLineArgTypes error) @safe
	{
		writeln("Invalid option! For help use -help. Error Code: ", error);
	}

	void onValidArgs() @safe
	{
		writeln("VALID_ARG");
	}

	final CommandLineArgTypes process(string[] arguments) @safe
	{
		auto elements = arguments[1 .. $]; // INFO: Remove program name.
		rawArguments_ = elements;

		if(elements.length > 0)
		{
			if(elements[0].removechars("-") == "help")
			{
				return CommandLineArgTypes.HELP_ARG;
			}

			foreach(element; elements)
			{
				auto keyValuePair = element.findSplit("=");
	            auto key = keyValuePair[0].stripRight();
	            auto separator = keyValuePair[1];
	            auto value = keyValuePair[2].stripLeft();
				auto modifiedKey = key.removechars("--");

				if(separator.length && value.length)
				{
					if(contains(modifiedKey))
					{
						ArgValues values;
						values.value = value;

						values_[modifiedKey] = values;
					}
					else
					{
						return CommandLineArgTypes.INVALID_ARG;
					}
				}
				else
				{
					if(separator.length)
					{
						return CommandLineArgTypes.INVALID_ARG_PAIR;
					}
					else
					{
						if(contains(modifiedKey))
						{
							ArgValues values;

							values.value = "true";
							values_[modifiedKey] = values;

							return CommandLineArgTypes.FLAG_ARG;
						}
						else
						{
							return CommandLineArgTypes.INVALID_ARG;
						}
					}
				}
			}

			return CommandLineArgTypes.VALID_ARG;
		}
		else
		{
			return CommandLineArgTypes.NO_ARGS;
		}
	}

	final void processArgs(string[] arguments) @safe
	{
		auto processed = process(arguments);

		switch(processed) with (CommandLineArgTypes)
		{
			case VALID_ARG, FLAG_ARG:
				onValidArgs();
				break;
			case HELP_ARG:
				onPrintHelp();
				break;
			default:
				onInvalidArgs(processed);
				break;
		}
	}

private:
	static ArgValues[string] values_;
	static string[] rawArguments_;
}
