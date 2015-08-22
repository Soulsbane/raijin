/**
*	This modules manages a config file format in the form of key=value. Much like an ini file but simpler.
*
*	Author: Paul Crane
*/

module raijin.keyvalueconfig;

import std.conv;
import std.string;
import std.stdio : File, writeln;
import std.file : exists, readText;
import std.algorithm : sort, findSplit;
import std.traits : isNumeric, isBoolean;
import std.array : empty;
import std.typecons;
import std.datetime : Clock;

struct KeyValueConfig
{
	alias string[string] KeyValueData;
	alias KeyValueData[string] GroupData;

private:
	void processText(immutable string text) @safe
	{
		if(defaultGroupName_ == defaultGroupName_.init) // If default group name wasn't changed generate a random string for it.
		{
			setDefaultGroupName(Clock.currTime().toString);
		}

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
		if(fileName_ != string.init)
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

	/**
	* Loads a config fileName(app.config by default) to be processed.
	*
	* Params:
	*  fileName = The name of the file to be processed/loaded.
	* Returns:
	*  Returns true on a successful load false otherwise.
	*/
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

	/**
	*	Similar to loadFile but loads and processes the passed string instead.
	*
	*	Params:
	*		text = The string to process.
	*		fileName = The name of the file to save processed strings key/values. If no fileName is provided values will NOT BE SAVED!
	*	Returns:
	*		Returns true on a successful load false otherwise.
	*/
	bool loadString(immutable string text, string fileName = string.init) @safe
	{
		if(text.length > 0)
		{
			processText(text);

			if(fileName != string.init)
			{
				fileName_ = fileName;
			}

			return true;
		}
		else
		{
			return false;
		}
	}

	/**
	*	Gets the value T of the key/value pair where T is the type the value should be converted to.
	*
	*	Params:
	*		mapKey = Name of the key to get.
	*
	*	Returns:
	*		The value of value of the key/value pair.
	*
	*/
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

	/**
	*	Gets the value T of the key/value pair where T is the type the value should be converted to.
	*
	*	Params:
	*		mapKey = Name of the key to get.
	*		defaultValue = Allow the assignment of a default value if key does not exist.
	*
	*	Returns:
	*		The value of value of the key/value pair.
	*
	*/
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

	/**
	*	Gets the value T of the key/value pair where T is the type the value should be converted to.
	*
	*	Params:
	*		groupName = Name of the group to retrieve ie portion [groupName] of config file/string.
	*		mapKey = Name of the key to get.
	*		defaultValue = Allow the assignment of a default value if key does not exist.
	*
	*	Returns:
	*		The value of value of the key/value pair.
	*
	*/
	T get(T = string)(immutable string groupName, immutable string mapKey, string defaultValue) pure @safe
	{
		auto group = getGroup(groupName);
		auto groupValue = group.get(mapKey, defaultValue);

		return to!T(groupValue);
	}

	/**
	*	Gets the group portion of a config file/string.
	*
	*	Params:
	*		groupName = Name of the the group to retrieve.
	*
	*	Returns:
	*		Retruns an associative array of key/value pairs for the groupName.
	*
	*/
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

	string getDefaultGroupName()
	{
		return defaultGroupName_;
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
			return remove(groupAndKey.group, groupAndKey.key);
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
	string defaultGroupName_;
	string fileName_;
	bool valuesModified_;
}

unittest
{
	import std.stdio;

	KeyValueConfig config;
	config["blah.sucks"] = "this is it";
	writeln(config["blah.sucks"]);
	assert(config["blah.sucks"] == "hell");
	config["it"] = "comes in the night";
	writeln(config["it"]);
}
