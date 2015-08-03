module raijin.keyvalueconfig;

public import std.conv;

import std.string;
import std.stdio : File;
import std.file : exists, readText;
import std.algorithm : sort;
import std.traits : isNumeric;

struct KeyValueConfig
{
private:
	void load(immutable string fileName) @safe
	{
		string text;

		if(fileName.indexOf("=") == -1)
		{
			if(exists(fileName))
			{
				text = readText(fileName);
			}

			fileName_ = fileName;
		}
		else
		{
			text = fileName; // In this case it's a string not a filename.
		}

		processText(text);
	}

	void processText(immutable string text) @safe
	{
		auto lines = text.lineSplitter();

		foreach(line; lines)
		{
			auto fields = split(line, separator_);

			if(fields.length == 2)
			{
				values_[fields[0].strip] = fields[1].strip;
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
		load(fileName);
	}

	~this()
	{
		if(valuesModified_)
		{
			save();
		}
	}

	bool contains(immutable string key) pure @safe
	{
		if(key in values_)
		{
			return true;
		}
		return false;
	}

	T get(T = string)(immutable string key) pure @safe
	{
		return to!T(values_.get(key, "0"));
	}

	T get(T = string)(immutable string key, string defval) pure @safe
	{
		return to!T(values_.get(key, defval));
	}

	void set(T)(immutable string key, T value) pure @safe
	{
		static if(is(T == string))
		{
			values_[key] = value;
		}
		else
		{
			values_[key] = to!string(value);
		}

		valuesModified_ = true;
	}

	bool remove(immutable string key) pure @safe
	{
		return values_.remove(key);
	}

	string opIndex(string key)
	{
		return get(key);
	}

	void opIndexAssign(T = string)(T value, string key)
	{
		set(key, value);
	}

private:
	immutable char separator_ = '=';
	string[string] values_;
	string fileName_ = "app.config";
	bool valuesModified_;
}

