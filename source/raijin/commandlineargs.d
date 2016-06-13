/**
	This module contains a simple class that processes command line arguments and stores
	them in a hashtable. The hash table is static so this class object can be created multiple
	times without having to reinitialize it when the arguments from main.

	Authors:
		Paul Crane
*/
module raijin.commandlineargs;

import std.conv;
import std.string;
import std.algorithm;
import std.stdio;
import std.typecons;
import std.path;
import std.format;
import std.container;

import raijin.utils.string;
import raijin.types.dynamic;

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

/**
	Returns a string that contains a what the user will see for each error type.

	type = The type of error to retrieve.
*/
private string argTypesToString(const string type)
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
	Ensures that the defaultValue will have a value if it's of a floating point type.

	Params:
		defaultValue = The value to initialize.

	Returns:
		The converted value.
*/
T initDefaultValue(T = string)(T defaultValue = T.init)
{
	import std.traits : isFloatingPoint;
	import std.conv : to;
	import std.math : isNaN;

	T value = defaultValue;

	static if(isFloatingPoint!T)
	{
		if(isNaN(defaultValue))
		{
			value = 0.0;
		}
	}

	return value;
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
		Should not be called directly. Default print method for printing registered command line options.
	*/
	void onPrintHelp()
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
		Should not be called directly. Prints the program version string when -version argument is passed.
	*/
	void onPrintVersion()
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
		Should not be called directly. Called when an invalid argument is passed on the command line.

		Params:
			error = Contains the reason the argument was invalid.
			command = The argument that was passed.
	*/
	void onInvalidArg(const string error, const string command)
	{
		writeln("Invalid option ", command, "! ", argTypesToString(error), ". Use -help for a list of available commands.");
	}

	/**
		Should not be called directly. Called after all arguments have been processed and no invalid arguments were found.
	*/
	void onValidArgs() {}

	/**
		Should not be called directly. Called each time a valid argument is passed.

		Params:
			argument = The argument that was passed.
			value = The value associated with the argument.
	*/
	void onValidArg(const string argument, const DynamicType value) {}

	/**
		Should not be called directly. Called when no arguments were passed on the command line.
	*/
	void onNoArgs() {}

	/**
		Should not be called directly. Called when when an argument does not contain a leading '-' and ignoreNonArgs is enabled.

		Params:
			argument = The argument that was passed.
	*/
	void onNonArg(const string argument) {}

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

		if(elements.length > 0)
		{
			foreach(element; elements)
			{
				auto elementParts = Tuple!(string, "key", string, "separator", string, "commandLineValue")(element.findSplit("="));

				elementParts.key.removeLeadingCharsInPlace('-');

				if(element.indexOf("-") == -1 && ignoreNonArgs == true) // Argument has no leading '-' character. Should handle ignoreNonArgs here.
				{
					onNonArg(elementParts.key);
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

							onValidArg(elementParts.key, value);
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

								onValidArg(elementParts.key, DynamicType(true));
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

	alias hasFlag = asBoolean; /// This just makes the function calls intent clearer when you are querying whether the flag was passed.

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

	assert(args.hasFlag("flag"));
	assert(args["flag"] == true);

	import std.math : feqrel;

	immutable float aFloat = args.asDecimal("aFloat");

	assert(feqrel(args.asDecimal("aFloat"), 4.44));
	assert(feqrel(aFloat, 4.44));

	assert(feqrel(args.asInteger("aFloat"), 4.44));

	assert(args.contains("integer") == true);
	assert(args.contains("valuez") == false);
	assert(args["integer"] == 100);
}

/// Provides a safer way of getting command line arguments by index.
struct SafeIndexArgs
{
	this(string[] args)
	{
		args_ = make!Array(args[1..$]); // Initialize and remove program name from arguments.
	}

	/**
		Retrieves the raw value passed via the command line in a safe way.

		Params:
			index = The integer value denoting the number of the argument passed.
			defaultValue = Default value to use if the index is out of range.

		Returns:
			The value of the command line argument at index or defaultValue otherwise.
	*/
	T get(T = string)(const size_t index, T defaultValue = T.init) @safe
	{
		T value = defaultValue.initDefaultValue();

		if(args_.length >= index)
		{
			// We have to subtract index by one here since the array is 0 based but length is only the number of values passed.
			value = to!T(args_[index - 1]);
			currentIndex_ = index;
		}

		return value;
	}

	/**
		Retrieves next value after a previous call to get! in a safe way.

		Params:
			defaultValue = Default value to use if the next index after a get! call is out of range.

		Returns:
			The value of the command line argument at index or defaultValue otherwise.
			The next index after a get! call or defaultValue otherwise.
	*/
	T peek(T = string)(T defaultValue = T.init) @safe
	{
		size_t index = currentIndex_ + 1;
		T value = defaultValue.initDefaultValue();

		if(args_.length >= index)
		{
			// We have to subtract index by one here since the array is 0 based but length is only the number of values passed.
			value = to!T(args_[index - 1]);
		}

		return value;
	}

	Array!string args_;
	private size_t currentIndex_;

	alias args_ this; // Allows usage of Array members outside of SafeIndexArgs.

	/// Gets the value and converts it to a bool.
	alias asBool = get!bool;

	/// Gets the value and converts it to a int.
	alias asInt = get!int;

	/// Gets the value and converts it to a float.
	alias asFloat = get!float;

	/// Gets the value and converts it to a real.
	alias asReal = get!real;

	/// Gets the value and converts it to a long.
	alias asLong = get!long;

	/// Gets the value and converts it to a byte.
	alias asByte = get!byte;

	/// Gets the value and converts it to a short.
	alias asShort = get!short;

	/// Gets the value and converts it to a double.
	alias asDouble = get!double;

	/// Gets the value and converts it to a string.
	alias asString = get!string;
}

///
unittest
{
	auto arguments = ["testapp", "-flag", "true", "4.44"];
	SafeIndexArgs args = SafeIndexArgs(arguments);

	assert(args.get(1) == "-flag");
	assert(args.get(8, "defaultValue") == "defaultValue");
	assert(args.get(8) == "");
	assert(args.get(8, true) == true);
	assert(args.get!int(8) == 0);
	assert(args.get!int(8, 50) == 50);
	assert(args.get!bool(8) == false);
	assert(args.get!bool(8, true) == true);
	assert(args.get!bool(2, false) == true);
	assert(args.get!string(1) == "-flag");
	assert(args.peek!bool(false) == true);
	assert(args.peek(false) == true); // Make sure peek doesn't modify currentIndex_;

	import std.math : approxEqual;

	assert(approxEqual(args.get!double(3, 3.5), 4.44));
	assert(approxEqual(args.get!double(4, 3.5), 3.5));
	assert(approxEqual(args.get!double(4), 0.0));
	assert(approxEqual(args.asDouble(3, 3.5), 4.44)); //Syntatic sugar
}
