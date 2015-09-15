/**
*	This module contains a simple class that processes command line arguments.
*
*	Author: Paul Crane
*/
module raijin.commandlineargs;

import std.conv : to;
import std.string : removechars, stripLeft, stripRight, indexOf;
import std.traits : isNumeric, isBoolean;
import std.algorithm : findSplit;
import std.stdio : writeln;
import std.typecons : Flag;

alias IgnoreFirstArg = Flag!"ignoreFirstArg";
alias RequiredArg = Flag!"requiredArg";

public enum CommandLineArgTypes { VALID_ARG, INVALID_ARG, INVALID_ARG_PAIR, FLAG_ARG, NO_ARGS, HELP_ARG }

struct ArgValues
{
	string defaultValue;
	string value;
	string description;
	bool required;
}

/**
*	Handles the processing of command line arguments.
*/
class CommandLineArgs
{
	/**
	*	Retrieves the value of key where key is the name of the command line argument and converts it to T.
	*	T is the the type that returned value should be converted to.
	*
	*	Params:
	*		key = Name of the command line argument to get.
	*
	*	Returns:
	*		The value of value of the command line argument to getcommand line argument to get
	*
	*/
	final T get(T = string)(immutable string key) @safe
	{
		ArgValues defaultValues;

		if(isBoolean!T)
		{
			defaultValues.defaultValue = "false";
			defaultValues.value = "false";
		}

		if(isNumeric!T)
		{
			defaultValues.value = "0";
		}

		auto values = values_.get(key, defaultValues);

		return to!T(values.value);
	}

	/**
	*	Retrieves the value of key where key is the name of the command line argument and converts it to T.
	*	T is the the type that returned value should be converted to.
	*
	*	Params:
	*		key = Name of the command line argument to get.
	*		defaultValue = Allow the assignment of a default value if key does not exist.
	*
	*	Returns:
	*		The value of value of the command line argument to getcommand line argument to get
	*
	*/
	final T get(T = string)(immutable string key, string defaultValue) @safe
	{
		ArgValues defaultValues;

		defaultValues.defaultValue = defaultValue;
		defaultValues.value = defaultValue;
		auto values = values_.get(key, defaultValues);

		return to!T(values.value);
	}

	/**
	*	Registers a command line argument
	*
	*	Params:
	*		key = Name of the command line argument to register.
	*		defaultValue = The default value to use if no value is supplied.
	*		description = The description of what the command line argument does.
	*/
	final void addCommand(immutable string key, immutable string defaultValue, immutable string description, RequiredArg required = RequiredArg.no) @safe
	{
		ArgValues values;

		values.defaultValue = defaultValue;
		values.value = defaultValue;
		values.description = description;
		values.required = required;

		values_[key] = values;
	}

	/**
	*	Registers a command line argument
	*
	*	Params:
	*		key = Name of the command line argument to register.
	*		values = ArgValues struct.
	*/
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

	/**
	*	Determines if the key(command line argument) exists.
	*
	*	Params:
	*		key = Name of the key to get the value from.
	*
	*	Returns:
	*		true if the command line argument exists, false otherwise.
	*/
	final bool contains(immutable string key) @safe
	{
		return cast(bool)(key in values_);
	}

	/**
	*	Default print method for printing registered command line options.
	*/
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

	/**
	*	Called when an invalid argument is passed on the command line.
	*/
	void onInvalidArgs(CommandLineArgTypes error, string[] arguments) @safe
	{
		writeln("Invalid option! For help use -help. Error Code: ", error);
	}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onValidArgs() @safe
	{
		writeln("VALID_ARG");
	}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onNoArgs() @safe
	{
		writeln("No arguments were passed!");
	}

	/**
	*	Handles the registration of command line arguments passed to the program. Ideally processArgs method should be
	*	used as it simplifies handling of command line arguments. But if you need a more fine grain approach use this method.
	*
	*	Params:
	*		arguments = The arguments that are sent from main()
	*/
	final CommandLineArgTypes process(string[] arguments, IgnoreFirstArg ignoreFirstArg = IgnoreFirstArg.no) @safe
	{
		auto elements = arguments[1 .. $]; // INFO: Remove program name.
		rawArguments_ = elements;

		if(elements.length > 0)
		{
			if(elements[0].removechars("-") == "help")
			{
				return CommandLineArgTypes.HELP_ARG;
			}

			bool isNotFirst = false;

			foreach(element; elements)
			{
				auto keyValuePair = element.findSplit("=");
	            auto key = keyValuePair[0].stripRight();
	            auto separator = keyValuePair[1];
	            auto value = keyValuePair[2].stripLeft();
				auto modifiedKey = key.removechars("--");

				if(ignoreFirstArg && (element.indexOf("-") == -1))
				{
					isNotFirst = true;
				}
				else
				{
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
						}
						else
						{
							return CommandLineArgTypes.INVALID_ARG;
						}
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

	/**
	*	Handles the registration of command line arguments passed to the program.
	*
	*	Params:
	*		arguments = The arguments that are sent from main()
	*/
	final void processArgs(string[] arguments, IgnoreFirstArg ignoreFirstArg = IgnoreFirstArg.no) @safe
	{
		auto processed = process(arguments, ignoreFirstArg);

		switch(processed) with (CommandLineArgTypes)
		{
			case VALID_ARG, FLAG_ARG:
				onValidArgs();
				break;
			case HELP_ARG:
				onPrintHelp();
				break;
			case NO_ARGS:
				onNoArgs();
				break;
			default:
				onInvalidArgs(processed, arguments);
				break;
		}
	}

private:
	static ArgValues[string] values_;
	static string[] rawArguments_;
}
