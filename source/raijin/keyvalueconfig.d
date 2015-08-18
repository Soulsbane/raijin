module raijin.keyvalueconfig;

import std.conv;
import std.string;
import std.stdio : File, writeln;
import std.file : exists, readText;
import std.algorithm : sort, findSplit;
import std.traits : isNumeric, isBoolean;
import std.array : empty;
import std.typecons;

struct KeyValueConfig
{
	alias string[string] KeyValueData;
	alias KeyValueData[string] GroupData;

private:
	void processText(immutable string text) @safe
	{
		auto lines = text.lineSplitter();
		string currentGroupName = defaultGroupName_;

		foreach(line; lines)
		{
			line = strip(line);

			if(line.empty)
			{
				continue;
			}
			else if(line.startsWith("[") && line.endsWith("]"))
			{
				string groupName = line[1..$-1];
				currentGroupName = groupName;
			}
			else
			{
				auto groupAndKey = line.findSplit("=");
	            auto key = groupAndKey[0].stripRight();
	            auto value = groupAndKey[2].stripLeft();

	            if (groupAndKey[1].length)
	            {
	            	values_[currentGroupName][key] = value;
	           	}
			}
		}
	}

	void save() @trusted
	{
		auto configfile = File(fileName_, "w+");

		foreach(groupName, data; values_)
		{
			if(groupName != defaultGroupName_)
			{
				configfile.writeln("[", groupName, "]");
			}

			foreach(key, value; data)
			{
				configfile.writeln(key, separator_, value);
			}
		}
	}

	bool isGroupString(immutable string value) pure @safe
	{
		if(value.indexOf(".") == -1)
		{
			return false;
		}
		return true;
	}

	auto getGroupAndKeyFromString(immutable string value) pure @safe
	{
		auto groupAndKey = value.findSplit(".");
		auto group = groupAndKey[0].strip();
		auto key = groupAndKey[2].strip();

		return tuple!("group", "key")(group, key);
	}

public:
	~this()
	{
		if(valuesModified_)
		{
			save();
		}
	}

	bool loadFile(string fileName = "app.config") @safe
	{
		if(exists(fileName))
		{
			processText(readText(fileName));
			fileName_ = fileName;

			return true;
		}
		else
		{
			return false;
		}
	}

	bool loadString(immutable string text, string fileName = "app.config")
	{
		if(text.length > 0)
		{
			processText(text);
			fileName_ = fileName;

			return true;
		}
		else
		{
			return false;
		}
	}

	T get(T = string)(immutable string mapKey) pure @safe
	{
		string defaultValue;

		if(isBoolean!T)
		{
			defaultValue = "false";
		}

		if(isNumeric!T)
		{
			defaultValue = "0";
		}

		if(isGroupString(mapKey))
		{
			auto groupAndKey = getGroupAndKeyFromString(mapKey);
			return get(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			auto groupValues = values_[defaultGroupName_];
			return to!T(groupValues.get(mapKey, defaultValue));
		}
	}

	T get(T = string)(immutable string mapKey, string defaultValue) pure @safe
	{
		if(isGroupString(mapKey))
		{
			auto groupAndKey = getGroupAndKeyFromString(mapKey);
			return get(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			auto groupValues = values_[defaultGroupName_];
			return to!T(groupValues.get(mapKey, defaultValue));
		}
	}

	T get(T = string)(immutable string groupName, immutable string mapKey, string defaultValue) pure @safe
	{
		auto group = getGroup(groupName);
		auto groupValue = group.get(mapKey, defaultValue);

		return to!T(groupValue);
	}

	KeyValueData getGroup(immutable string groupName) pure @safe
	{
		return values_[groupName];
	}

	void set(T)(immutable string mapKey, T value) pure @safe
	{
		static if(!is(T == string))
		{
			string convValue = to!string(value);
		}
		else
		{
			string convValue = value;
		}

		if(isGroupString(mapKey))
		{
			auto groupAndKey = getGroupAndKeyFromString(mapKey);
			values_[groupAndKey.group][groupAndKey.key] = convValue;
		}
		else
		{
			values_[defaultGroupName_][mapKey] = convValue;
		}

		valuesModified_ = true;
	}

	void setDefaultGroupName(immutable string name) pure @safe
	{
		defaultGroupName_ = name;
	}

	bool contains(immutable string key) pure @safe
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return contains(groupAndKey.group, groupAndKey.key);
		}
		else
		{
			return contains(defaultGroupName_, key);
		}
	}

	bool contains(immutable string groupName, immutable string key) pure @safe
	{
		if(containsGroup(groupName))
		{
			auto group = getGroup(groupName);

			if(key in group)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			auto group = getGroup(defaultGroupName_);

			if(key in group)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
	}

	bool containsGroup(immutable string key) pure @safe
	{
		if(key in values_)
		{
			return true;
		}
		return false;
	}

	bool remove(immutable string key) pure @safe
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			auto group = getGroup(groupAndKey.group);

			return group.remove(groupAndKey.key);
		}
		else
		{
			auto group = getGroup(defaultGroupName_);
			return group.remove(key);
		}
	}

	bool remove(immutable string groupName, immutable string key) pure @safe
	{
		auto group = getGroup(groupName);
		return group.remove(key);
	}

	bool removeGroup(immutable string key) pure @safe
	{
		return values_.remove(key);
	}

	string opIndex(string mapKey)
	{
		return get(mapKey);
	}

	void opIndexAssign(T = string)(T value, string mapKey)
	{
		set(mapKey, value);
	}

private:
	immutable char separator_ = '=';
	GroupData values_;
	// TODO: Create a random name for default group
	string defaultGroupName_ = "10DefaultGroup";
	string fileName_ = "app.config";
	bool valuesModified_;
}

unittest
{
	import std.stdio;

	KeyValueConfig config;
	config["blah.sucks"] = "this is it";
	writeln(config["blah.sucks"]);

	config["it"] = "comes in the night";
	writeln(config["it"]);
}
