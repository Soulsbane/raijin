/**
*   Various functions to determine types at runtime.
*/

module raijin.typeutils;

import std.typecons;
import std.traits;

alias AllowNumericBooleanValues = Flag!"allowNumericBooleanValues";
/**
*   Determines if value is a true value
*
*   Params:
*       value = The value to check for a true value
*
*   Returns:
*       true if the value is true false otherwise.
*/
bool isTrue(T)(const T value, const AllowNumericBooleanValues allowInteger = AllowNumericBooleanValues.yes)
{
	static if(isIntegral!T)
	{
		return(value == 1);
	}
	else
	{
		if(allowInteger)
		{
			return(value == "1" || value == "true");
		}

		return (value == "true");
	}
}

/**
*   Determines if value is a false value
*
*   Params:
*       value = The value to check for a false value
*
*   Returns:
*       true if the value is false false otherwise.
*/
bool isFalse(T)(const T value, const AllowNumericBooleanValues allowInteger = AllowNumericBooleanValues.yes)
{
	static if(isIntegral!T)
	{
		return(value == 0);
	}
	else
	{
		if(allowInteger)
		{
			return(value == "0" || value == "false");
		}

		return (value == "false");
	}
}

/**
*   Determines if a value is of type boolean using 0, 1, true and false as qualifiers.
*
*   Params:
*       value = number or boolean string to use. Valid values of 0, 1, "0", "1", "true", "false"
*
*   Returns:
*       true if the value is a boolean false otherwise.
*/
bool isBoolean(T)(const T value, const AllowNumericBooleanValues allowInteger = AllowNumericBooleanValues.yes)
{
	return(isTrue(value, allowInteger) || isFalse(value, allowInteger));
}

/**
*   Determines if a string is a decimal value
*
*   Params:
*       value = string to use.
*
*   Returns:
*       true if the value is a decimal false otherwise.
*/
bool isDecimal(const string value)
{
	import std.string : isNumeric, countchars;
	return (isNumeric(value) && value.countchars(".") == 1) ? true : false;
}

/**
*   Determines if a string is an integer value.
*
*   Params:
*       value = string to use.
*
*   Returns:
*       true if the value is a integer false otherwise.
*/
bool isInteger(const string value)
{
	import std.string : isNumeric, countchars;
	return (isNumeric(value) && value.countchars(".") == 0) ? true : false;
}

/**
* Same as TypeTuple, but meant to be used with values.
*
*	Example:
*		foreach (char channel; ValueTuple!('r', 'g', 'b'))
*		{
*			the loop is unrolled at compile-time
*			"channel" is a compile-time value, and can be used in string mixins
*		}
*/

// NOTE: The following functions can be found in CyberShadows ae lib https://github.com/CyberShadow/ae/
template ValueTuple(T...)
{
	alias ValueTuple = T;
}

template RangeTupleImpl(size_t N, R...)
{
	static if (N==R.length)
		alias RangeTupleImpl = R;
	else
		alias RangeTupleImpl = RangeTupleImpl!(N, ValueTuple!(R, R.length));
}

/// Generate a tuple containing integers from 0 to N-1.
/// Useful for static loop unrolling. (staticIota)
template RangeTuple(size_t N)
{
	alias RangeTuple = RangeTupleImpl!(N, ValueTuple!());
}

/// Equivalent of PHP's `list` language construct:
/// http://php.net/manual/en/function.list.php
/// Works with arrays and tuples.
/// Specify `null` as an argument to ignore that index
/// (equivalent of `list(x, , y)` in PHP).
auto list(Args...)(auto ref Args args)
{
	import std.format : format;

	struct List
	{
		auto dummy() { return args[0]; }

		void opAssign(T)(auto ref T t)
		{
			assert(t.length == args.length,
				"Assigning %d elements to list with %d elements"
				.format(t.length, args.length));

				foreach (i; RangeTuple!(Args.length))
					static if (!is(Args[i] == typeof(null)))
						args[i] = t[i];
		}
	}

	return List();
}

unittest
{
	import std.stdio : writeln;

	assert("0".isBoolean == true);
	assert("1".isBoolean == true);
	assert("2".isBoolean == false);

	assert("true".isBoolean == true);
	assert("false".isBoolean == true);
	assert("trues".isBoolean == false);

	assert("0".isBoolean(AllowNumericBooleanValues.no) == false);
	assert("1".isBoolean(AllowNumericBooleanValues.no) == false);

	assert(0.isBoolean == true);
	assert(1.isBoolean == true);
	assert(2.isBoolean == false);

	assert("13".isInteger == true);
	assert("13.333333".isInteger == false);
	assert("zzzz".isInteger == false);

	assert("13".isDecimal == false);
	assert("13.333333".isDecimal == true);
	assert("zzzz".isDecimal == false);

	assert(isTrue("true") == true);
	assert(isTrue("false") == false);
	assert(isTrue("1") == true);
	assert(isTrue("0") == false);
	assert(isTrue("12345") == false);
	assert(isTrue("trues") == false);

	assert("1".isTrue(AllowNumericBooleanValues.no) == false);

	assert(isFalse("false") == true);
	assert(isFalse("true") == false);
	assert(isFalse("1") == false);
	assert(isFalse("0") == true);
	assert(isFalse("12345") == false);
	assert(isFalse("trues") == false);

	assert("0".isFalse(AllowNumericBooleanValues.no) == false);

	import std.algorithm : findSplit;

	string name, value;
	list(name, null, value) = "key=value".findSplit("=");

	assert(name == "key" && value == "value");
}
