/**
	This module contains a simple class that processes command line arguments and stores
	them in a hashtable. The hash table is static so this class object can be created multiple
	times without having to reinitialize it when the arguments from main.

	Author: Paul Crane
*/
module raijin.commandlineargs;

import std.conv : to;
import std.string : removechars, stripLeft, stripRight, indexOf;
import std.algorithm : findSplit;
import std.stdio : writeln;
import std.typecons;
import std.path : baseName;
import std.format;

import raijin.stringutils;
import raijin.typeutils;

alias IgnoreNonArgs = Flag!"IgnoreNonArgs";
alias AllowInvalidArgs = Flag!"allowInvalidArgs";
alias RequiredArg = Flag!"requiredArg";

/**
	The type in which each command line argument is stored in.
*/
private struct ArgValues
{
	DynamicType defaultValue; /// Initial value a command line argument has if it isn't supplied.
	DynamicType value; /// The Value set via the command line.
	string description; /// The description of the command line argument.
	bool required; /// true if the command line argument is required false otherwise.
	bool isFlag; /// true if command line arg should be a flag eg. --myflag
}

/// NOTE: This mixin inserts a condition for checking whether or not to allowInvalidArgs in process()
private string breakOnInvalidArg(const string type)
{
	return format(q{
		if(allowInvalidArgs == false)
		{
			onInvalidArg("%s", element);
			return false;
		}
	}, type);
}

private string generateAddCommand(T)()
{
	return format(q{
		void addCommand(const string key, %s defaultValue, const string description, RequiredArg required = RequiredArg.no) @trusted
		{
			ArgValues values;

			values.defaultValue = defaultValue;
			values.value = defaultValue;
			values.description = description;
			values.required = required;
			values.isFlag = false;

			values_[key] = values;
		}
	}, T.stringof);
}

string generateAsMethodFor(T)(const string functionName) @safe
{
	return format(q{
		%s %s(const string key, %s defaultValue = %s.init)
		{
			if(contains(key))
			{
				ArgValues values;

				values = values_[key];
				return values.value.%s;
			}
			return defaultValue;
		}
	}, T.stringof, functionName, T.stringof, T.stringof, functionName);
}

string argTypesToString(const string type)
{
	string[string] typeTable =
	[
		"INVALID_ARG":"Invalid argument was passed",
		"INVALID_ARG_PAIR":"Argument requires a value",
		"INVALID_FLAG_VALUE":"Argument must not contain a value",
		"NON_ARG":"Non argument passed"
	];

	return typeTable[type];
}

/**
	Handles the processing of command line arguments.
*/
class CommandLineArgs
{
public:
	/**
		Registers a command line argument used in year=1942

		Params:
			key = Name of the command line argument to register.
			defaultValue = The default value to use if no value is supplied.
			description = The description of what the command line argument does.
			required = Whether the argument is required.
	*/
	mixin(generateAddCommand!long);
	mixin(generateAddCommand!bool);
	mixin(generateAddCommand!string);
	mixin(generateAddCommand!double);

	/**
		Registers a flag argument eg. --flag

		Params:
			key = Name of the command line argument to register.
			description = The description of what the command line argument does.
			required = Whether the argument is required.
	*/
	final void addFlag(const string key, const string description, RequiredArg required = RequiredArg.no) @trusted
	{
		ArgValues values;

		values.defaultValue = false;
		values.value = false;
		values.description = description;
		values.required = required;
		values.isFlag = true;

		values_[key] = values;
	}


	mixin(generateAsMethodFor!long("asInteger"));
	mixin(generateAsMethodFor!bool("asBoolean"));
	mixin(generateAsMethodFor!double("asDecimal"));
	mixin(generateAsMethodFor!string("asString"));

	/**
		Retrieves the value of key where key is the name of the command line argument.
		T is the the type that returned value should be converted to.

		Params:
			key = Name of the command line argument to get.

		Returns:
			The value of value of the command line argument to get. If the key isn't found it will
			return an raijin.typeutils.DynamicType.
	*/
	final DynamicType opIndex(const string key) @trusted
	{
		if(contains(key))
		{
			return values_[key].value;
		}
		else
		{
			DynamicType value;
			return value;
		}
	}

	/**
		Assigns a value to a commandline argument stored internally.
	*/
	final void opIndexAssign(T)(T value, const string key) @trusted
	{
		ArgValues values;
		values.value = value;

		values_[key] = values;
	}

	/**
		Assigns a value to a commandline argument stored internally but uses ArgValues as the value.
	*/
	final void opIndexAssign(ArgValues values, const string key) @trusted
	{
		values_[key] = values;
	}

	/**
		Determines if the key(command line argument) exists.

		Params:
			key = Name of the key to get the value from.

		Returns:
			true if the command line argument exists, false otherwise.
	*/
	final bool contains(const string key) @safe
	{
		return cast(bool)(key in values_);
	}

	/**
		Retrieves the raw value passed via the command line in a safe way.

		Params:
			index = The integer value denoting the number of the argument passed.
			defaultValue = Default value to use if the index is out of range.

		Returns:
			The value of the command line argument at index or defaultValue otherwise.
	*/
	final T safeGet(T = string)(const size_t index, string defaultValue = string.init) @safe
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
		Returns the name of the program.

		Returns:
			The name of the program.
	*/
	string getProgramName() @safe nothrow
	{
		return programName_;
	}

	/**
		Sets the programs version string to be used with -version argument.

		Params:
			programVersion = Text used when -version argument is called.
	*/
	void setProgramVersion(const string programVersion) @safe nothrow
	{
		programVersion_ = programVersion;
	}

	/**
		Default print method for printing registered command line options.
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
		Prints the program version string when -version argument is passed.
	*/
	void onPrintVersion() @trusted
	{
		if(programVersion_ == programVersion_.init)
		{
			writeln(programName_.baseName, " ", "1.0.0");
		}
		else
		{
			writeln(programVersion_);
		}
	}

	/**
		Called when an invalid argument is passed on the command line.
	*/
	void onInvalidArg(const string error, const string command) @trusted
	{
		writeln("Invalid option ", command, "! ", argTypesToString(error), ". Use -help for a list of available commands.");
	}

	/**
		Called after all arguments have been processed and no invalid arguments were found.
	*/
	void onValidArgs() @trusted {}

	/**
		Called each time a valid argument is passed.
	*/
	void onValidArg(const string argument) @trusted {}

	/**
		Called when no arguments were passed on the command line.
	*/
	void onNoArgs() @trusted {}

	/**
		Handles the registration of command line arguments passed to the program.

		Params:
			arguments = The arguments that are sent from main()
			ignoreNonArgs = Ignore the first argument passed and continue processing the remaining arguments
			allowInvalidArgs = Any invalid arguments will be ignored and won't be called.
		Note:
			Setting allowInvalidArgs.yes will also cause onInvalidArgs to not be fired. Resulting in invalid data in a command.
	*/
	bool process(string[] arguments, IgnoreNonArgs ignoreNonArgs = IgnoreNonArgs.no,
		AllowInvalidArgs allowInvalidArgs = AllowInvalidArgs.no)
	{
		auto elements = arguments[1 .. $]; // INFO: Remove program name.

		programName_ = arguments[0];
		rawArguments_ = elements;

		if(elements.length > 0)
		{
			foreach(element; elements)
			{
				auto elementParts = Tuple!(string, "key", string, "separator", string, "commandLineValue")(element.findSplit("="));

				elementParts.key.removeLeadingCharsInPlace('-');

				if(element.indexOf("-") == -1 && ignoreNonArgs == false) // Argument has no leading '-' character. Should handle ignoreNonArgs here.
				{
					mixin(breakOnInvalidArg("NON_ARG"));
				}
				else
				{
					if(elementParts.separator.length && elementParts.commandLineValue.length) // key=value argument
					{
						if(contains(elementParts.key))
						{
							DynamicType value = getDynamicTypeFromString(elementParts.commandLineValue);

							values_[elementParts.key].value = value;
							values_[elementParts.key].required = false;

							onValidArg(elementParts.key);
						}
						else
						{
								mixin(breakOnInvalidArg("INVALID_ARG"));
						}
					}
					else // flag argument -key or -key=
					{
						if(elementParts.separator.length) // Broken argument -key=
						{
							mixin(breakOnInvalidArg("INVALID_ARG_PAIR"));
						}
						else //Valid -key flag argument
						{
							if(contains(elementParts.key))
							{
								values_[elementParts.key].value = true;
								values_[elementParts.key].required = false;

								onValidArg(elementParts.key);
							}
							else
							{
								if(elementParts.key == "help")
								{
									onPrintHelp();
									return true;
								}

								if(elementParts.key == "version")
								{
									onPrintVersion();
									return true;
								}

								mixin(breakOnInvalidArg("INVALID_ARG"));
							}
						}
					}
				}
			}

			onValidArgs();
		}
		else
		{
			// No arguments passed
			onNoArgs();
		}

		immutable bool requiredArgsNotProcessed = checkRequiredArgs();

		if(requiredArgsNotProcessed)
		{
			return false;
		}

		return true;
	}

private:
	bool checkRequiredArgs() @trusted
	{
		foreach(key, value; values_)
		{
			if(value.required)
			{
				writeln("Error: -", key, " is a required argument and must be supplied. Please supply ",
					"-", key, "or use -help for more information.");

				return true;
			}
		}

		return false;
	}

private:
	static ArgValues[string] values_;
	static string[] rawArguments_;
	static string programName_;
	static string programVersion_;
}

///
unittest
{
	auto arguments = ["testapp", "-flag", "-value=this is a test", "-aFloat=4.44"];
	auto args = new CommandLineArgs;

	args.addFlag("flag", "A test flag");
	args.addCommand("aFloat", 3.14, "A float value");
	args.addCommand("integer", 100, "Sets value");
	args.addCommand("value", "hello world", "Just a silly value.");
	args.process(arguments);

	assert(args.asBoolean("flag") == true);
	assert(args["flag"] == true);

	import std.math;

	float aFloat = args.asDecimal("aFloat");

	assert(feqrel(args.asDecimal("aFloat"), 4.44));
	assert(feqrel(aFloat, 4.44));

	assert(feqrel(args.asInteger("aFloat"), 4.44));

	assert(args.contains("integer") == true);
	assert(args.contains("valuez") == false);
	assert(args["integer"] == 100);
}
