module raijin.keyvalueconfig;

import std.conv;
import std.string;
import std.stdio : File;
import std.file : exists, readText;
import std.algorithm : sort;
import std.traits : isNumeric;

struct KeyValueConfig
{
private:
	void load() @safe
	{
		if(exists(fileName_))
		{
			auto lines = readText(fileName_).lineSplitter();

			foreach(line; lines)
			{
				auto fields = split(line, separator_);

				if(fields.length == 2)
				{
					values_[strip(fields[0])] = strip(fields[1]);
				}
			}
		}
	}

	void save() @trusted
	{
		auto configfile = File(fileName_, "w+");

		foreach(key; sort(values_.keys))
		{
			configfile.writeln(key, separator_, values_[key]);
		}
	}

public:
	this(immutable string fileName)
	{
		fileName_ = fileName;
		load();
	}

	~this()
	{
		save();
	}

	bool hasValue(immutable string key) pure @safe
	{
		if(key in values_)
		{
			return true;
		}
		return false;
	}

	T getValue(T = string)(immutable string key) pure @safe
	{
		if(isNumeric!T)
		{
			return to!T(values_.get(key, "0"));
		}
		else
		{
			return to!T(values_.get(key, ""));
		}
	}

	T getValue(T = string)(immutable string key, string defval) pure @safe
	{
		return to!T(values_.get(key, defval));
	}

	void setValue(T)(immutable string key, T value) pure @safe
	{
		static if(is(T == string))
		{
			values_[key] = value;
		}
		else
		{
			values_[key] = to!string(value);
		}
	}

	string opIndex(string key)
	{
		return getValue(key);
	}

	/*T opIndex(T)(string key)
	{
		return getValue!T(key);
	}*/

	void opIndexAssign(T = string)(T value, string key)
	{
		setValue(key, value);
	}

private:
	immutable char separator_ = '=';
	string[string] values_;
	immutable string fileName_;
}

