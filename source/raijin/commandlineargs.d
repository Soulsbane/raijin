/**
*	This module contains a simple class that processes command line arguments and stores
*	them in a hashtable. The hash table is static so this class object can be created multiple
*	times without having to reinitialize it when the arguments from main.
*
*	Author: Paul Crane
*/
module raijin.commandlineargs;

import std.conv : to;
import std.string : removechars, stripLeft, stripRight, indexOf;
import std.algorithm : findSplit;
import std.stdio : writeln;
import std.typecons : Flag, Tuple;
import std.path : baseName;
import std.variant;

import raijin.stringutils : removeLeadingChars;
import raijin.typeutils;
import raijin.debugutils;


alias IgnoreFirstArg = Flag!"ignoreFirstArg";
alias RequiredArg = Flag!"requiredArg";
alias AllowInvalidArgs = Flag!"allowInvalidArgs";

enum CommandLineArgTypes { INVALID_ARG, INVALID_ARG_PAIR, INVALID_FLAG_VALUE, VALID_ARGS, NO_ARGS, HELP_ARG, VERSION_ARG }
alias ProcessReturnCodes = Tuple!(CommandLineArgTypes, "type", string, "command");

/**
	The type in which each command line argument is stored in.
*/
struct ArgValues
{
	Variant defaultValue; /// Initial value a command line argument has if it isn't supplied.
	Variant value; /// The Value set via the command line.
	string description; /// The description of the command line argument.
	bool required; /// true if the command line argument is required false otherwise.
	bool isFlag; /// true if command line arg should be a flag eg. --myflag
}

/// NOTE: This mixin inserts a condition for checking whether or not to allowInvalidArgs in process()
private string breakOnInvalidArg(const string type)
{
	return "
		if(allowInvalidArgs == false)
		{
			return ProcessReturnCodes(CommandLineArgTypes." ~ type ~ ", element);
		}";
}

private string argTypesToString(CommandLineArgTypes type)
{
	string[CommandLineArgTypes] typeTable =
	[
		CommandLineArgTypes.INVALID_ARG:"Invalid argument was passed",
		CommandLineArgTypes.INVALID_ARG_PAIR:"Argument requires a value",
		CommandLineArgTypes.INVALID_FLAG_VALUE:"Argument must not contain a value",
		CommandLineArgTypes.VALID_ARGS:"",
		CommandLineArgTypes.NO_ARGS:"",
		CommandLineArgTypes.HELP_ARG:"",
		CommandLineArgTypes.VERSION_ARG:""
	];

	return typeTable[type];
}

/**
*	Handles the processing of command line arguments.
*/
class CommandLineArgs
{
private:
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
	final Variant get(T)(const string key) @trusted
	{
		import std.traits;

		ArgValues defaultValues;
		ArgValues values;

		static if(isNumeric!T)
		{
			defaultValues.value = Variant(0);
		}
		else static if(isBoolean!T)
		{

			defaultValues.value = Variant(false);
		}
		else
		{
			defaultValues.value = Variant("");
		}

		values = values_.get(key, defaultValues);

		return values.value;
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
	*		The value of value of the command line argument to get
	*
	*/
	final Variant get(const string key, Variant defaultValue) @trusted
	{
		ArgValues defaultValues;
		ArgValues values;

		defaultValues.defaultValue = defaultValue;
		defaultValues.value = defaultValue;
		values = values_.get(key, defaultValues);

		return values.value;
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
	*		The value of value of the command line argument to get
	*
	*/
	final Variant get(T)(const string key, T defaultValue = T.init) @trusted
	{
		ArgValues defaultValues;
		ArgValues values;

		defaultValues.defaultValue = defaultValue;
		defaultValues.value = defaultValue;
		values = values_.get(key, defaultValues);

		return values.value;
	}

public:
	/**
	*	Registers a command line argument used in year=1942
	*
	*	Params:
	*		key = Name of the command line argument to register.
	*		defaultValue = The default value to use if no value is supplied.
	*		description = The description of what the command line argument does.
	*		required = Whether the argument is required.
	*/
	final void addCommand(T)(const string key, T defaultValue, const string description,
		RequiredArg required = RequiredArg.no) @trusted
	{
		ArgValues values;

		values.defaultValue = defaultValue;
		values.value = defaultValue;
		values.description = description;
		values.required = required;
		values.isFlag = false;

		values_[key] = values;
	}

	/**
	*	Registers a command line argument
	*
	*	Params:
	*		key = Name of the command line argument to register.
	*		values = ArgValues struct.
	*/
	final void addCommand(const string key, const ArgValues values) @trusted
	{
		values_[key] = values;
	}

	/**
	*	Registers a flag argument eg. --flag
	*
	*	Params:
	*		key = Name of the command line argument to register.
	*		defaultValue = The default value to use if no value is supplied.
	*		description = The description of what the command line argument does.
	*		required = Whether the argument is required.
	*/
	final void addFlag(T)(const string key, T defaultValue, const string description,
		RequiredArg required = RequiredArg.no) @trusted
	{
		ArgValues values;

		values.defaultValue = defaultValue;
		values.value = defaultValue;
		values.description = description;
		values.required = required;
		values.isFlag = true;

		values_[key] = values;
	}
	/**
	*	Retrieves the value of key where key is the name of the command line argument.
	*	T is the the type that returned value should be converted to.
	*
	*	Params:
	*		key = Name of the command line argument to get.
	*
	*	Returns:
	*		The value of value of the command line argument to get
	*
	*/
	// Note that since we can't know the type before hand this will throw an exception if you are expecting anything but a string. You should use contains first.
	final Variant opIndex(const string key) @trusted
	{
		ArgValues defaultValues;
		defaultValues.value = Variant("");

		auto values = values_.get(key, defaultValues);
		return values.value;
	}

	/**
	*	Assigns a value to a commandline argument stored internally.
	*/
	final void opIndexAssign(T)(T value, const string key) @trusted
	{
		ArgValues values;
		values.value = value;

		values_[key] = values;
	}

	/**
	*	Assigns a value to a commandline argument stored internally but uses ArgValues as the value.
	*/
	final void opIndexAssign(ArgValues values, const string key) @trusted
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
	final bool contains(const string key) @safe
	{
		return cast(bool)(key in values_);
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
	*	Returns the name of the program.
	*
	*	Returns:
	*		The name of the program.
	*/
	string getProgramName() @safe nothrow
	{
		return programName_;
	}

	/**
	*	Sets the programs version string to be used with -version argument.
	*
	*	Params:
	*		programVersion = Text used when -version argument is called.
	*/
	void setProgramVersion(const string programVersion) @safe nothrow
	{
		programVersion_ = programVersion;
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
	*	Prints the program version string when -version argument is passed.
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
	*	Called when an invalid argument is passed on the command line.
	*/
	void onInvalidArgs(CommandLineArgTypes error, string command) @trusted
	{
		writeln("Invalid option ", command, "! ", argTypesToString(error), ". Use -help for a list of available commands.");
	}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onValidArgs() @trusted {}

	/**
	*	Called each time a valid argument is passed.
	*/
	void onValidArg(const string argument) @trusted {}

	/**
	*	Called when an valid argument is passed on the command line.
	*/
	void onNoArgs() @trusted {}

	/**
	*	Handles the registration of command line arguments passed to the program.
	*
	*	Params:
	*		arguments = The arguments that are sent from main()
	*		ignoreFirstArg = Ignore the first argument passed and continue processing the remaining arguments
	*		allowInvalidArgs = Any invalid arguments will be ignored and onInvalidArgs won't be called.
	*	Note:
	*		Setting allowInvalidArgs.yes will also cause onInvalidArgs to not be fired. Resulting in invalid data in a command.
	*/
	final bool processArgs(string[] arguments, IgnoreFirstArg ignoreFirstArg = IgnoreFirstArg.no,
		AllowInvalidArgs allowInvalidArgs = AllowInvalidArgs.no) @trusted
	{
		immutable auto processed = process(arguments, ignoreFirstArg, allowInvalidArgs);
		bool requiredArgsNotProcessed = checkRequiredArgs();

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

				case VERSION_ARG:
					onPrintVersion();
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
	*	Note:
	*		Setting allowInvalidArgs.yes will also cause onInvalidArgs to not be fired. Resulting in invalid data in a command.
	*/
	final auto process(string[] arguments, IgnoreFirstArg ignoreFirstArg = IgnoreFirstArg.no,
		AllowInvalidArgs allowInvalidArgs = AllowInvalidArgs.no) @trusted
	{
		auto elements = arguments[1 .. $]; // INFO: Remove program name.

		programName_ = arguments[0];
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
				immutable string key = keyValuePair[0].stripRight.removeLeadingChars('-');
				immutable string separator = keyValuePair[1];
				string initialValue = keyValuePair[2].stripLeft();

				Variant value;// = values_[key].value;

				if(initialValue.isInteger)
				{
					value = to!long(initialValue); // TODO: Maybe store type from addCommand and use it here somehow.
				}
				else if(initialValue.isDecimal)
				{
					value = to!double(initialValue); // TODO: Maybe store type from addCommand and use it here somehow.
				}
				else if(isBoolean(initialValue, AllowNumericBooleanValues.no))
				{
					value = to!bool(initialValue);
				}
				else
				{
					value = to!string(initialValue);
				}

				if(!firstArgProcessed && (element.indexOf("-") == -1))
				{
					firstArgProcessed = true;
				}
				else
				{
					if(separator.length && initialValue.length)
					{
						if(contains(key)) // Key value argument -key=value
						{
							if(values_[key].isFlag)
							{
								immutable Variant currentValue = values_[key].value;

								if(currentValue.isBoolean(AllowNumericBooleanValues.no) &&
									initialValue.isBoolean(AllowNumericBooleanValues.no))
								{
									values_[key].required = false;
									values_[key].value = value;

									onValidArg(key);
								}
								else
								{
									mixin(breakOnInvalidArg("INVALID_FLAG_VALUE"));
								}
							}
							else
							{
								values_[key].value = value;
								values_[key].required = false;

								onValidArg(key);
							}
						}
						else
						{
							mixin(breakOnInvalidArg("INVALID_ARG"));
						}
					}
					else
					{
						if(separator.length) // Broken argument in form of -key=
						{
							mixin(breakOnInvalidArg("INVALID_ARG_PAIR"));
						}
						else
						{
							if(contains(key)) // Flag argument -key
							{
								values_[key].value = true;
								values_[key].required = false;

								onValidArg(key);
							}
							else
							{
								if(key == "help")
								{
									return ProcessReturnCodes(CommandLineArgTypes.HELP_ARG, "-help");
								}

								if(key == "version")
								{
									return ProcessReturnCodes(CommandLineArgTypes.VERSION_ARG, "-version");
								}

								mixin(breakOnInvalidArg("INVALID_ARG"));
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

	/**
	*	Converts the value of key to type of T. Works the same as std.variant's coerce.
	*
	*	Params:
	*		key = Name of the key to retrieve.
	*
	*	Returns:
	*		T = The converted value.
	*/
	T coerce(T)(const string key, T defaultValue = T.init) @trusted
	{
		Variant value = get!T(key, defaultValue);
		return value.coerce!T;
	}

	/// Gets the value and converts it to a bool.
	alias getBool = coerce!bool;

	/// Gets the value and converts it to a int.
	alias getInt = coerce!int;

	/// Gets the value and converts it to a float.
	alias getFloat = coerce!float;

	/// Gets the value and converts it to a real.
	alias getReal = coerce!real;

	/// Gets the value and converts it to a long.
	alias getLong = coerce!long;

	/// Gets the value and converts it to a byte.
	alias getByte = coerce!byte;

	/// Gets the value and converts it to a short.
	alias getShort = coerce!short;

	/// Gets the value and converts it to a double.
	alias getDouble = coerce!double;

	/// Gets the value and converts it to a string.
	alias getString = coerce!string;

private:
	bool checkRequiredArgs() @trusted
	{
		bool requiredArgsNotProcessed;

		foreach(key, value; values_)
		{
			if(value.required)
			{
				writeln("Error: -", key, " is a required argument and must be supplied. Please supply ",
					"-", key, "or use -help for more information.");
				requiredArgsNotProcessed = true;
				break; // If there is one required argument missing the others don't matter so bail out.
			}
		}

		return requiredArgsNotProcessed;
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
	auto arguments = ["--flag", "value=this is a test", "aFloat=4.44"];
	auto args = new CommandLineArgs;

	args.addCommand("flag", true, "A test flag");
	args.addCommand("aFloat", 3.14, "A float value");
	args.addCommand("value", "the default value", "Sets value");
	args.processArgs(arguments);

	assert(args.getBool("flag") == true);
	assert(args["flag"] == true);
	assert(args.coerce!bool("flag") == true);

	import std.math;
	float aFloat = args.getFloat("aFloat");

	assert(args["aFloat"] == 4.44);
	assert(approxEqual(args.getFloat("aFloat"), 4.44));
	assert(approxEqual(aFloat, 4.44));

	assert(args.getDouble("aFloat") == 4.44);
	assert(args["aFloat"] == 4.44);
	assert(args.coerce!double("aFloat") == 4.44);

	assert(args.contains("value") == true);
	assert(args.contains("valuez") == false);
	assert(args.get("value") == "this is a test");
}
