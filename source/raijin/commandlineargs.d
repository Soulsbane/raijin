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
import std.typecons;
import std.path : baseName;
import std.variant;

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
	Variant defaultValue; /// Initial value a command line argument has if it isn't supplied.
	Variant value; /// The Value set via the command line.
	string description; /// The description of the command line argument.
	bool required; /// true if the command line argument is required false otherwise.
	bool isFlag; /// true if command line arg should be a flag eg. --myflag
	TypeInfo storedType; // Stores the default type passed to addCommand or addFlag.
}

/// NOTE: This mixin inserts a condition for checking whether or not to allowInvalidArgs in process()
private string breakOnInvalidArg(const string type)
{
	return "
		if(allowInvalidArgs == false)
		{
			onInvalidArg(\"" ~ type ~ "\", element);
			return false;
		}";
}

private string argTypesToString(const string type)
{
	string[string] typeTable =
	[
		"INVALID_ARG":"Invalid argument was passed",
		"INVALID_ARG_PAIR":"Argument requires a value",
		"INVALID_FLAG_VALUE":"Argument must not contain a value"
	];

	return typeTable[type];
}

// TODO: Possibly handle more types
private Variant getValueFromType(const string commandLineValue, const TypeInfo storedType) @trusted
{
	Variant value;

	if(commandLineValue.isInteger)
	{
		if(storedType == typeid(int))
		{
			value = to!int(commandLineValue);
		}
		else
		{
			value = to!long(commandLineValue);
		}
	}
	else if(commandLineValue.isDecimal)
	{
		if(storedType == typeid(float))
		{
			value = to!float(commandLineValue);
		}
		else if(storedType == typeid(real))
		{
			value = to!real(commandLineValue);
		}
		else
		{
			value = to!double(commandLineValue);
		}
	}
	else if(isBoolean(commandLineValue, AllowNumericBooleanValues.no))
	{
		value = to!bool(commandLineValue);
	}
	else
	{
		value = to!string(commandLineValue);
	}

	return value;
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
		values.storedType = typeid(T);

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
	final void addFlag(const string key, const string description, RequiredArg required = RequiredArg.no) @trusted
	{
		ArgValues values;

		values.defaultValue = false;
		values.value = false;
		values.description = description;
		values.required = required;
		values.isFlag = true;
		values.storedType = typeid(bool);

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
	*		The value of value of the command line argument to get. If the key isn't found it will
	*		return an unitialized Variant. Method hasValue can be used to test if the returned value is valid.
	*
	*/
	// NOTE: that since we can't know the type before hand this will throw an exception if you are expecting anything but a string. You should use contains first.
	final Variant opIndex(const string key) @trusted
	{
		if(contains(key))
		{
			return values_[key].value;
		}
		else
		{
			Variant value;
			return value;
		}
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
	void onInvalidArg(const string error, const string command) @trusted
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
	*	Handles the registration of command line arguments passed to the program. This is the internal command line
	*	argument processing method. The method processArgs should be used as it simplifies handling of command line
	*	arguments.
	*
	*	Params:
	*		arguments = The arguments that are sent from main()
	*		ignoreNonArgs = Ignore the first argument passed and continue processing the remaining arguments
	*		allowInvalidArgs = Any invalid arguments will be ignored and won't be called.
	*	Note:
	*		Setting allowInvalidArgs.yes will also cause onInvalidArgs to not be fired. Resulting in invalid data in a command.
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

				if(element.indexOf("-") == -1) // Argument has no leading '-' character. Should handle ignoreNonArgs here.
				{
					continue;
				}
				else
				{
					if(elementParts.separator.length && elementParts.commandLineValue.length) // key=value argument
					{
						if(contains(elementParts.key))
						{
							Variant value = getValueFromType(elementParts.commandLineValue, values_[elementParts.key].storedType);

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
	auto arguments = ["testapp", "-flag", "-value=this is a test", "-aFloat=4.44"];
	auto args = new CommandLineArgs;

	args.addFlag("flag", "A test flag");
	args.addCommand!float("aFloat", 3.14, "A float value");
	args.addCommand!int("integer", 100, "Sets value");
	args.addCommand!string("value", "hello world", "Just a silly value.");
	args.process(arguments);

	assert(args.getBool("flag") == true);
	assert(args["flag"] == true);
	assert(args.coerce!bool("flag") == true);

	import std.math;

	float aFloat = args.getFloat("aFloat");

	assert(feqrel(args.getFloat("aFloat"), 4.44));
	assert(feqrel(aFloat, 4.44));

	assert(feqrel(args.getDouble("aFloat"), 4.44));
	assert(feqrel(args.coerce!double("aFloat"), 4.44));

	assert(args.contains("integer") == true);
	assert(args.contains("valuez") == false);
	assert(args["integer"] == 100);
}
