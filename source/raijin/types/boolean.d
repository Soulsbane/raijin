/*
	Contains a boolean type which can convert boolean like values(numeric, string, etc) to a bool.

	Author:
		Paul Crane
**/

module raijin.types.boolean;

/**
	Creates a boolean type which can convert boolean like values(numeric, string, etc) to a bool.

	A note on what true and false values are:

	True values include 1, "Yes", true and "true".
	False values are anything other than 1, "No", false and "false".
*/
struct Boolean
{
public:
	this(const string value)
	{
		import raijin.utils.string : toBoolean;
		boolean_ = value.toBoolean;
	}

	this(const size_t value)
	{
		boolean_ = value == 1 ? true : false;
	}

	this(const bool value)
	{
		boolean_ = value;
	}

	this(const Boolean value)
	{
		boolean_ = value.boolean_;
	}

	bool opEquals(const string value)
	{
		import raijin.utils.string : toBoolean;
		return (boolean_ == value.toBoolean);
	}

	bool opEquals(const size_t value)
	{
		bool temp = value == 1 ? true : false;
		return (boolean_ == temp);
	}

	bool opEquals(const bool value)
	{
		return (boolean_ == value);
	}

	void opAssign(const string value)
	{
		import raijin.utils.string : toBoolean;
		boolean_ = value.toBoolean;
	}

	void opAssign(const size_t value)
	{
		boolean_ = value == 1 ? true : false;
	}

	void opAssign(const bool value)
	{
		boolean_ = value;
	}

	bool toBool() @property
	{
		return boolean_;
	}

	alias toBool this;

private:
	bool boolean_;
}

///
unittest
{
	Boolean value = 1;
	assert(value == true);

	Boolean strValue = "Yes";
	assert(strValue == true);

	Boolean boolValue = true;
	boolValue = "No";
	assert(boolValue == false);
	boolValue = 1;
	assert(boolValue == true);

	Boolean compare1 = true;
	Boolean compare2 = true;
	Boolean compare3 = false;
	assert(compare1 == compare2);
	compare2 = compare3;
	assert(compare2 == compare2);

	size_t tValue = 1;
	Boolean tBoolValue = tValue;
	assert(tBoolValue == true);
}
