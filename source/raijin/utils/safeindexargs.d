
/**
	Provides a safer way of getting command line arguments by index.
*/
module raijin.utils.safeindexargs;

import std.container;
import std.traits : isFloatingPoint;
import std.math : isNaN;

import raijin.utils.debugtools;
import raijin.types.functions;

/**
	Ensures that the defaultValue will have a value if it's of a floating point type.

	Params:
		defaultValue = The value to initialize.

	Returns:
		The converted value.
*/
T initDefaultValue(T = string)(const T defaultValue = T.init) @safe
{

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
	Provides a safer way of getting command line arguments by index.
*/
struct SafeIndexArgs
{
	this(string[] args)
	{
		if(args.length > 0)
		{
			if(args.length == 1)
			{
				args_ = make!Array(args[0..1]); // Initialize and remove program name from arguments.
			}
			else
			{
				args_ = make!Array(args[1..$]); // Initialize and remove program name from arguments.
			}
		}
	}

	/**
		Retrieves the raw value passed via the command line in a safe way.

		Params:
			index = The integer value denoting the number of the argument passed.
			defaultValue = Default value to use if the index is out of range.

		Returns:
			The value of the command line argument at index or defaultValue otherwise.
	*/
	T get(T = string)(const size_t index, const T defaultValue = T.init) @safe
	{
		T value = defaultValue.initDefaultValue();

		switch(args_.length)
		{
			case 0:
				return value;

			case 1:
				if(index == 0)
				{
					currentIndex_ = 0;
					return convertTo!T(args_[0], value);
				}

				return value;

			default:
				if(args_.length >= index)
				{
					currentIndex_ = index;
					return convertTo!T(args_[index - 1], value);
				}

				return value;
		}

	}

	/**
		Retrieves next value after a previous call to get! in a safe way.

		Params:
			defaultValue = Default value to use if the next index after a get! call is out of range.

		Returns:
			The value of the command line argument at index or defaultValue otherwise.
			The next index after a get! call or defaultValue otherwise.
	*/
	T next(T = string)(const T defaultValue = T.init) @safe
	{
		size_t index = currentIndex_ + 1;
		T value = defaultValue.initDefaultValue();

		return get!T(index, defaultValue);
	}

	Array!string args_;
	private size_t currentIndex_;

	alias args_ this; // Allows usage of Array members outside of SafeIndexArgs.
	alias as = get;

	/// Gets the value and converts it to a bool.
	alias asBoolean = get!bool;

	/// Gets the value and converts it to a long.
	alias asInteger = get!long;

	/// Gets the value and converts it to a double.
	alias asDecimal = get!double;

	/// Gets the value and converts it to a string.
	alias asString = get!string;

	alias peek = next;
}

///
unittest
{
	import std.stdio : writeln, write;
	writeln("<=====================Beginning safeindexargs module=====================>");
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
	assert(args.next!bool(false) == true);
	assert(args.next(false) == false);

	import std.math : approxEqual;

	assert(approxEqual(args.get!double(3, 3.5), 4.44));
	assert(approxEqual(args.get!double(4, 3.5), 3.5));
	assert(approxEqual(args.get!double(4), 0.0));
	assert(approxEqual(args.asDecimal(3, 3.5), 4.44)); //Syntatic sugar
	assert(approxEqual(args.as!float(3, 3.5), 4.44)); // Or just use as! for the exact type.

	string[] zeroArgs;
	SafeIndexArgs safeZeroArgs = SafeIndexArgs(zeroArgs);

	assert(safeZeroArgs.get(1) == string.init);
	assert(safeZeroArgs.get(0) == string.init);

	assert(safeZeroArgs.next() == string.init);
	assert(safeZeroArgs.get(1) == string.init);
	assert(safeZeroArgs.next() == string.init);

	string[] oneArg = ["cat"];
	SafeIndexArgs safeOneArg = SafeIndexArgs(oneArg);

	assert(safeOneArg.get(1) == string.init);
	assert(safeOneArg.get(0) == "cat");
}
