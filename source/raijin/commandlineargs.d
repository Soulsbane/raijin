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
import std.typecons : Flag, Tuple;

alias IgnoreFirstArg = Flag!"ignoreFirstArg";
alias RequiredArg = Flag!"requiredArg";
alias AllowInvalidArgs = Flag!"allowInvalidArgs";

enum CommandLineArgTypes { VALID_ARGS, INVALID_ARG, INVALID_ARG_PAIR, NO_ARGS, HELP_ARG }
alias ProcessReturnCodes = Tuple!(CommandLineArgTypes, "type", string, "command");

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

	bool isFlag(immutable string key) @safe
	{
		if(contains(key))
		{
			immutable string value = values_[key];

			if(value == "true" || value == "false")
			{
				return true;
			}

			return false;
		}

		return false;
	}
	/**
	*	Retrieves the raw value passed via the command line in a safe way.
	*
	*	Params:
	*		index = The integer value denoting the number of the argument passed.
	*		defaultValue = Default value to use if the index is out of range.
	*
	*	Returns:
	*		The value of the command line argument at index or defaultValue otherwise.
	*/
	final T safeGet(T = string)(size_t index, string defaultValue = string.init)
	{
		string value;

		if(defaultValue == string.init)
		{
			if(isBoolean!T)
			{
				value = "false";
			}

			else if(isNumeric!T)
			{
				value = "0";
			}
			else
			{
				value = defaultValue;
			}
		}

		if(rawArguments_.length >= index)
		{
			value = rawArguments_[index - 1];
		}

		return to!T(value);
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
	void onInvalidArgs(CommandLineArgTypes error, string command) @safe
	{
		writeln("Invalid option, ", command, "! For help use -help");
	}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onValidArgs() @safe
	{
		debug
		{
			writeln("VALID_ARGS");
		}
	}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onNoArgs() @safe
	{
		debug
		{
			writeln("No arguments were passed!");
		}
	}

	/**
	*	Handles the registration of command line arguments passed to the program.
	*
	*	Params:
	*		arguments = The arguments that are sent from main()
	*		ignoreFirstArg = Ignore the first argument passed and continue processing the remaining arguments
	*		allowInvalidArgs = Any invalid arguments will be ignored and onInvalidArgs won't be called.
	*/
	final bool processArgs(string[] arguments, IgnoreFirstArg ignoreFirstArg = IgnoreFirstArg.no,
		AllowInvalidArgs allowInvalidArgs = AllowInvalidArgs.no) @safe
	{
		immutable auto processed = process(arguments, ignoreFirstArg, allowInvalidArgs);
		bool requiredArgsNotProcessed;

		if(processed.type == CommandLineArgTypes.HELP_ARG)
		{
			requiredArgsNotProcessed = false;
		}
		else
		{
			requiredArgsNotProcessed = checkRequiredArgs();
		}

		if(!requiredArgsNotProcessed)
		{
			switch(processed.type) with (CommandLineArgTypes)
			{
				case VALID_ARGS:
					onValidArgs();
					return true;
				case HELP_ARG:
					onPrintHelp();
					return true;
				case NO_ARGS:
					onNoArgs();
					return true;
				default:
					onInvalidArgs(processed.type, processed.command);
					return false;
			}
		}
		else
		{
			return false;
		}
	}

	/**
	*	Handles the registration of command line arguments passed to the program. This is the internal command line
	*	argument processing method. The method processArgs should be used as it simplifies handling of command line
	*	arguments.
	*
	*	Params:
	*		arguments = The arguments that are sent from main()
	*		ignoreFirstArg = Ignore the first argument passed and continue processing the remaining arguments
	*		allowInvalidArgs = Any invalid arguments will be ignored and onInvalidArgs won't be called.
	*/
	final auto process(string[] arguments, IgnoreFirstArg ignoreFirstArg = IgnoreFirstArg.no,
		AllowInvalidArgs allowInvalidArgs = AllowInvalidArgs.no) @safe
	{
		auto elements = arguments[1 .. $]; // INFO: Remove program name.
		rawArguments_ = elements;

		if(elements.length > 0)
		{
			bool firstArgProcessed;

			if(!ignoreFirstArg)
			{
				firstArgProcessed = true;
			}

			foreach(element; elements)
			{
				auto keyValuePair = element.findSplit("=");
	            string key = keyValuePair[0].stripRight;
	            immutable string separator = keyValuePair[1];
	            immutable string value = keyValuePair[2].stripLeft();

				if(key[0] == '-') // Remove the leading dash character.
				{
					key = key[1 .. $];
				}

				if(!firstArgProcessed && (element.indexOf("-") == -1))
				{
					firstArgProcessed = true;
				}
				else
				{
					if(separator.length && value.length)
					{
						if(contains(key)) // Key value argument -key=value
						{
							values_[key].value = value;
							values_[key].required = false;
						}
						else
						{
							if(allowInvalidArgs == false)
							{
								return ProcessReturnCodes(CommandLineArgTypes.INVALID_ARG, element);
							}
						}
					}
					else
					{
						if(separator.length) // Broken argument in form of -key=
						{
							if(allowInvalidArgs == false)
							{
								return ProcessReturnCodes(CommandLineArgTypes.INVALID_ARG_PAIR, element);
							}
						}
						else
						{
							if(contains(key)) // Flag argument -key
							{
								values_[key].value = "true";
								values_[key].required = false;
							}
							else
							{
								if(key == "help")
								{
									return ProcessReturnCodes(CommandLineArgTypes.HELP_ARG, "-help");
								}

								if(allowInvalidArgs == false)
								{
									return ProcessReturnCodes(CommandLineArgTypes.INVALID_ARG, element);
								}
							}
						}
					}
				}
			}

			return ProcessReturnCodes(CommandLineArgTypes.VALID_ARGS, "");
		}
		else
		{
			return ProcessReturnCodes(CommandLineArgTypes.NO_ARGS, "");
		}
	}

private:
	bool checkRequiredArgs() @safe
	{
		bool requiredArgsNotProcessed;

		foreach(key, value; values_)
		{
			if(value.required)
			{
				writeln("Error: -", key, " is a required argument and must be supplied. Please supply ", "-", key, "or use -help for more information.");
				requiredArgsNotProcessed = true;
				break; // If there is one required argument missing the others don't matter so bail out.
			}
		}

		return requiredArgsNotProcessed;
	}

private:
	static ArgValues[string] values_;
	static string[] rawArguments_;
}
