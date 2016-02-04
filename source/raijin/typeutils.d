/**
*   Various functions to determine types at runtime.
*
*	Author: Paul Crane
*/

module raijin.typeutils;

import std.typecons;
import std.traits;
import std.conv;

alias AllowNumericBooleanValues = Flag!"allowNumericBooleanValues";

/**
*   A simple type that can store strings, integers, booleans and decimals only.
*/
struct DynamicType
{
	enum Type { integer, string, decimal, boolean }
	private Type type_;

	private union
	{
		long integer;
		string str;
		double decimal;
		bool boolean;
	}

	this(T)(T t)
	{
		this = t;
	}

	/// Assign a DynamicType to a long value.
	DynamicType opAssign(long value)
	{
		type_ = Type.integer;
		integer = value;

		return this;
	}

	/// Assign a DynamicType to a double value.
	DynamicType opAssign(double value)
	{
		type_ = Type.decimal;
		decimal = value;

		return this;
	}

	/// Assign a DynamicType to a string value.
	DynamicType opAssign(string value)
	{
		type_ = Type.string;
		str = value;

		return this;
	}

	/// Assign a DynamicType to a boolean value.
	DynamicType opAssign(bool value)
	{
		type_ = Type.boolean;
		boolean = value;

		return this;
	}

	DynamicType opAssign(DynamicType value)
	{
		import std.stdio;
		type_ = value.type;

		final switch(type_)
		{
			case Type.integer:
				integer = value.integer;
				break;
			case Type.string:
				str = value.str;
				break;
			case Type.decimal:
				decimal = value.decimal;
				break;
			case Type.boolean:
				boolean = value.boolean;
				break;
		}

		return this;
	}

	/// Compare a DynamicType to a long value.
	bool opEquals(long value) const
	{
		return(value == integer);
	}

	/// Compare a DynamicType to a string value.
	bool opEquals(string value) const
	{
		return(value == str);
	}

	/// Compare a DynamicType to a boolean value.
	bool opEquals(bool value) const
	{
		return(value == boolean);
	}

	/// Compare a DynamicType to a double value.
	bool opEquals(double value) const
	{
		import std.math;
		return approxEqual(value, decimal);
	}

	/// Compare a DynamicType to a DynamicType.
	bool opEquals(DynamicType value) const
	{
		if(type_ == value.type)
		{
			final switch(value.type)
			{
				case Type.integer:
					return (integer == value.integer);
				case Type.string:
					return (str == value.str);
				case Type.decimal:
					return (decimal == value.decimal);
				case Type.boolean:
					return (boolean == value.boolean);
			}
		}

		return false;
	}

	long asInteger()
	{
		final switch(type_)
		{
			case Type.integer:
				return integer;
			case Type.string:
				return to!long(str);
			case Type.decimal:
				return to!long(decimal);
			case Type.boolean:
				return to!long(boolean);
		}
	}

	string asString()
	{
		final switch(type_)
		{
			case Type.string:
				return str;
			case Type.integer:
				return to!string(integer);
			case Type.decimal:
				return to!string(decimal);
			case Type.boolean:
				return to!string(boolean);
		}
	}

	bool asBoolean()
	{
		final switch(type_)
		{
			case Type.string:
				return to!bool(str);
			case Type.integer:
				return (integer < 1) ? false : true;
			case Type.decimal:
				return false; // Why would you convert a decimal?
			case Type.boolean:
				return boolean;
		}
	}

	double asDecimal()
	{
		final switch(type_)
		{
			case Type.integer:
				return to!double(integer);
			case Type.string:
				return to!double(str);
			case Type.decimal:
				return decimal;
			case Type.boolean:
				return to!double(boolean); // FIXME
		}
	}

	string toString()
	{
		return asString();
	}

	Type type() @property
	{
		return type_;
	}
}

///
unittest
{
	DynamicType compareInt = 666;
	assert(compareInt == 666);
	assert(compareInt.asString == "666");
	assert(compareInt.asBoolean == true);
	assert(compareInt.asDecimal == 666);

	DynamicType compareDec = 36.786;
	assert(compareDec == 36.786);
	assert(compareDec.asString == "36.786");
	assert(compareDec.asInteger == 36);
	assert(compareDec.asBoolean == false);

	DynamicType compareBool = false;
	assert(compareBool == false);
	import std.stdio;

	DynamicType compareBool2 = true;
	assert(compareBool2 == true);

	DynamicType compareDynString1 = "Hello World";
	DynamicType compareDynString2 = "Hello World";
	assert(compareDynString1 == compareDynString2);

	DynamicType compareDynBoolean1 = false;
	DynamicType compareDynBoolean2 = false;
	assert(compareDynBoolean1 == compareDynBoolean2);

	DynamicType compareDynInteger1 = 333;
	DynamicType compareDynInteger2 = 333;
	assert(compareDynInteger1 == compareDynInteger2);

	DynamicType compareDynDecimal1 = 45.89;
	DynamicType compareDynDecimal2 = 45.89;
	DynamicType compareDynDecimalString3 = "45.89";
	assert(compareDynDecimal1 == compareDynDecimal2);
	assert(!(compareDynDecimal2 == compareDynDecimalString3));

	DynamicType assignToDynamicType1 = 15;
	DynamicType assignToDynamicType2 = assignToDynamicType1;
	assert(assignToDynamicType2 == 15);
}

/**
	Converts a string to its appropriate type to be stored in a DynamicType.

	Params:
		value = The string to convert.

	Returns:
		The converted string as a DynamicType.
*/
DynamicType getDynamicTypeFromString(const string value)
{
	DynamicType dynValue;

	if(value.isInteger)
	{
		dynValue = to!long(value);
	}
	else if(value.isDecimal)
	{
		dynValue = to!double(value);
	}
	else if(isBoolean(value, AllowNumericBooleanValues.no))
	{
		dynValue = to!bool(value);
	}
	else
	{
		dynValue = to!string(value);
	}

	return dynValue;
}

///
unittest
{
	const string strInt = "90210";
	DynamicType dynInt = getDynamicTypeFromString(strInt);
	assert(dynInt == 90210);

	const string strDec = "90.210";
	DynamicType dynDec = getDynamicTypeFromString(strDec);
	assert(dynDec == 90.210);

	const string strBool = "true";
	DynamicType dynBool = getDynamicTypeFromString(strBool);
	assert(dynBool == true);

	const string str = "My zip code is 90210";
	DynamicType dynStr = getDynamicTypeFromString(str);
	assert(dynStr == str);
}

/**
*   Determines if value is a true value
*
*   Params:
*       value = The value to check for a true value
*		allowInteger = Set to allowNumericBooleanValues.yes if a true value can be a numeric 1
*
*   Returns:
*       true if the value is true false otherwise.
*/
bool isTrue(T)(const T value, const AllowNumericBooleanValues allowInteger = AllowNumericBooleanValues.yes) @trusted
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

///
unittest
{
	assert(isTrue("true") == true);
	assert(isTrue("false") == false);
	assert(isTrue("1") == true);
	assert(isTrue("0") == false);
	assert(isTrue("12345") == false);
	assert(isTrue("trues") == false);

	assert("1".isTrue(AllowNumericBooleanValues.no) == false);
}

/**
*   Determines if value is a false value
*
*   Params:
*       value = The value to check for a false value
*		allowInteger = Set to allowNumericBooleanValues.yes if a false value can be a numeric 0
*
*   Returns:
*       true if the value is false false otherwise.
*/
bool isFalse(T)(const T value, const AllowNumericBooleanValues allowInteger = AllowNumericBooleanValues.yes) @trusted
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

///
unittest
{
	assert(isFalse("false") == true);
	assert(isFalse("true") == false);
	assert(isFalse("1") == false);
	assert(isFalse("0") == true);
	assert(isFalse("12345") == false);
	assert(isFalse("trues") == false);

	assert("0".isFalse(AllowNumericBooleanValues.no) == false);
}

/**
*   Determines if a value is of type boolean using 0, 1, true and false as qualifiers.
*
*   Params:
*       value = number or boolean string to use. Valid values of 0, 1, "0", "1", "true", "false"
*		allowInteger = Set to allowNumericBooleanValues.yes if a true/false value can be a numeric 0 or 1
*
*   Returns:
*       true if the value is a boolean false otherwise.
*/
bool isBoolean(T)(const T value, const AllowNumericBooleanValues allowInteger = AllowNumericBooleanValues.yes) @trusted
{
	return(isTrue(value, allowInteger) || isFalse(value, allowInteger));
}

///
unittest
{
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
bool isDecimal(const string value) pure @safe
{
	import std.string : isNumeric, countchars;
	return (isNumeric(value) && value.countchars(".") == 1) ? true : false;
}

///
unittest
{
	assert("13".isDecimal == false);
	assert("13.333333".isDecimal == true);
	assert("zzzz".isDecimal == false);
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
bool isInteger(const string value) pure @safe
{
	import std.string : isNumeric, countchars;
	return (isNumeric(value) && value.countchars(".") == 0) ? true : false;
}

///
unittest
{
	assert("13".isInteger == true);
	assert("13.333333".isInteger == false);
	assert("zzzz".isInteger == false);
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
private template ValueTuple(T...)
{
	alias ValueTuple = T;
}

private template RangeTupleImpl(size_t N, R...)
{
	static if (N==R.length)
		alias RangeTupleImpl = R;
	else
		alias RangeTupleImpl = RangeTupleImpl!(N, ValueTuple!(R, R.length));
}

/// Generate a tuple containing integers from 0 to N-1.
/// Useful for static loop unrolling. (staticIota)
private template RangeTuple(size_t N)
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

///
unittest
{
	import std.algorithm : findSplit;

	string name, value;
	list(name, null, value) = "key=value".findSplit("=");

	assert(name == "key" && value == "value");
}
