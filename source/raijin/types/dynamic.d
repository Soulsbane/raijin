/**
	simple type that can store strings, integers, booleans and decimals only.
*/
struct DynamicType
{
	enum Type { integer, string, decimal, boolean }
	private Type type_;

	private union
	{
		long integer_;
		string str_;
		double decimal_;
		bool boolean_;
	}

	this(T)(T t)
	{
		this = t;
	}

	/// Assign a DynamicType to a long value.
	DynamicType opAssign(long value)
	{
		type_ = Type.integer;
		integer_ = value;

		return this;
	}

	/// Assign a DynamicType to a double value.
	DynamicType opAssign(double value)
	{
		type_ = Type.decimal;
		decimal_ = value;

		return this;
	}

	/// Assign a DynamicType to a string value.
	DynamicType opAssign(string value)
	{
		type_ = Type.string;
		str_ = value;

		return this;
	}

	/// Assign a DynamicType to a boolean value.
	DynamicType opAssign(bool value)
	{
		type_ = Type.boolean;
		boolean_ = value;

		return this;
	}

	DynamicType opAssign(DynamicType value)
	{
		import std.stdio;
		type_ = value.type;

		final switch(type_)
		{
			case Type.integer:
				integer_ = value.integer;
				break;
			case Type.string:
				str_ = value.str;
				break;
			case Type.decimal:
				decimal_ = value.decimal;
				break;
			case Type.boolean:
				boolean_ = value.boolean;
				break;
		}

		return this;
	}

	/// Compare a DynamicType to a long value.
	bool opEquals(long value) const
	{
		return(value == integer_);
	}

	/// Compare a DynamicType to a string value.
	bool opEquals(string value) const
	{
		return(value == str_);
	}

	/// Compare a DynamicType to a boolean value.
	bool opEquals(bool value) const
	{
		return(value == boolean_);
	}

	/// Compare a DynamicType to a double value.
	bool opEquals(double value) const
	{
		import std.math;
		return approxEqual(value, decimal_);
	}

	/// Compare a DynamicType to a DynamicType.
	bool opEquals(DynamicType value) const
	{
		if(type_ == value.type)
		{
			final switch(value.type)
			{
				case Type.integer:
					return (integer_ == value.integer);
				case Type.string:
					return (str_ == value.str);
				case Type.decimal:
					return (decimal_ == value.decimal);
				case Type.boolean:
					return (boolean_ == value.boolean);
			}
		}

		return false;
	}

	long asInteger()
	{
		final switch(type_)
		{
			case Type.integer:
				return integer_;
			case Type.string:
				return to!long(str_);
			case Type.decimal:
				return to!long(decimal_);
			case Type.boolean:
				return to!long(boolean_);
		}
	}

	string asString()
	{
		final switch(type_)
		{
			case Type.string:
				return str_;
			case Type.integer:
				return to!string(integer_);
			case Type.decimal:
				return to!string(decimal_);
			case Type.boolean:
				return to!string(boolean_);
		}
	}

	bool asBoolean()
	{
		final switch(type_)
		{
			case Type.string:
				return to!bool(str_);
			case Type.integer:
				return (integer_ < 1) ? false : true;
			case Type.decimal:
				return false; // Why would you convert a decimal?
			case Type.boolean:
				return boolean_;
		}
	}

	double asDecimal()
	{
		final switch(type_)
		{
			case Type.integer:
				return to!double(integer_);
			case Type.string:
				return to!double(str_);
			case Type.decimal:
				return decimal_;
			case Type.boolean:
				return to!double(boolean_); // FIXME
		}
	}

	string toString()
	{
		return asString();
	}

	// Properties to access union values and type.
	long integer() const @property
	{
		return integer_;
	}

	double decimal() const @property
	{
		return decimal_;
	}

	bool boolean() const @property
	{
		return boolean_;
	}

	string str() const @property
	{
		return str_;
	}

	Type type() const @property
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
	assert(compareDynString1.str == compareDynString2.str);

	DynamicType compareDynBoolean1 = false;
	DynamicType compareDynBoolean2 = false;
	assert(compareDynBoolean1 == compareDynBoolean2);
	assert(compareDynBoolean1.boolean == compareDynBoolean2.boolean);

	DynamicType compareDynInteger1 = 333;
	DynamicType compareDynInteger2 = 333;
	assert(compareDynInteger1 == compareDynInteger2);
	assert(compareDynInteger1.integer == compareDynInteger2.integer);

	DynamicType compareDynDecimal1 = 45.89;
	DynamicType compareDynDecimal2 = 45.89;
	DynamicType compareDynDecimalString3 = "45.89";
	assert(compareDynDecimal1 == compareDynDecimal2);
	assert(compareDynDecimal1.decimal == compareDynDecimal2.decimal);
	assert(!(compareDynDecimal2 == compareDynDecimalString3));

	DynamicType assignToDynamicType1 = 15;
	DynamicType assignToDynamicType2 = assignToDynamicType1;
	assert(assignToDynamicType2 == 15);

	// property tests
	DynamicType propInteger = 732;
	assert(propInteger.integer == 732);

	DynamicType propStr = "732";
	assert(propStr.str == "732");

	DynamicType propDec = 7.32;
	assert(propDec.decimal == 7.32);

	DynamicType propBoolean = true;
	assert(propBoolean.boolean == true);
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
