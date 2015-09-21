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
	bool requiredFlag; // INFO: Will be true when the argument is processed.
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
	void onInvalidArgs(CommandLineArgTypes error, string command) @safe
	{
		writeln("Invalid option, ", command, "! For help use -help");
	}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onValidArgs() @safe
	{
		writeln("VALID_ARGS");
	}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onNoArgs() @safe
	{
		writeln("No arguments were passed!");
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
		auto processed = process(arguments, ignoreFirstArg, allowInvalidArgs);
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

private:
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
	            auto key = keyValuePair[0].stripRight();
	            auto separator = keyValuePair[1];
	            auto value = keyValuePair[2].stripLeft();
				auto modifiedKey = key.removechars("--");

				if(!firstArgProcessed && (element.indexOf("-") == -1))
				{
					firstArgProcessed = true;
				}
				else
				{
					if(separator.length && value.length)
					{
						if(contains(modifiedKey))
						{
							values_[modifiedKey].value = value;
							values_[modifiedKey].requiredFlag = true;
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
						if(separator.length)
						{
							if(allowInvalidArgs == false)
							{
								return ProcessReturnCodes(CommandLineArgTypes.INVALID_ARG_PAIR, element);
							}
						}
						else
						{
							if(contains(modifiedKey))
							{
								values_[modifiedKey].value = "true";
								values_[modifiedKey].requiredFlag = true;
							}
							else
							{
								if(modifiedKey == "help")
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

	bool checkRequiredArgs() @safe
	{
		bool requiredArgsNotProcessed;

		foreach(key, value; values_)
		{
			if(value.required && !value.requiredFlag)
			{
				//writeln("The argument --", key, " must be supplied. Please supply the argument or use -help for more information.");
				writeln("Error: -", key, " is a required argument must be supplied. Please supply ", "-", key, "or use -help for more information.");
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
