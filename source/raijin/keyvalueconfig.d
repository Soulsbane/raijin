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
	*		key = Name of the key to get.
	*
	*	Returns:
	*		The value of value of the key/value pair.
	*
	*/
	T get(T = string)(immutable string key) pure @safe
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

		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return get(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			auto groupValues = values_[defaultGroupName_];
			return to!T(groupValues.get(key, defaultValue));
		}
	}

	/**
	*	Gets the value T of the key/value pair where T is the type the value should be converted to.
	*
	*	Params:
	*		key = Name of the key to get.
	*		defaultValue = Allow the assignment of a default value if key does not exist.
	*
	*	Returns:
	*		The value of value of the key/value pair.
	*
	*/
	T get(T = string)(immutable string key, string defaultValue) pure @safe
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return get(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			auto groupValues = values_[defaultGroupName_];
			return to!T(groupValues.get(key, defaultValue));
		}
	}

	/**
	*	Gets the value T of the key/value pair where T is the type the value should be converted to.
	*
	*	Params:
	*		group = Name of the group to retrieve ie portion [groupName] of config file/string.
	*		key = Name of the key to get.
	*		defaultValue = Allow the assignment of a default value if key does not exist.
	*
	*	Returns:
	*		The value of value of the key/value pair.
	*
	*/
	T get(T = string)(immutable string group, immutable string key, string defaultValue) pure @safe
	{
		auto groupValues = getGroup(group);
		auto groupValue = groupValues.get(key, defaultValue);

		return to!T(groupValue);
	}

	/**
	*	Gets the group portion of a config file/string.
	*
	*	Params:
	*		group = Name of the the group to retrieve.
	*
	*	Returns:
	*		Retruns an associative array of key/value pairs for the group.
	*
	*/
	KeyValueData getGroup(immutable string group) pure @safe
	{
		return values_[group];
	}

	/**
	*	Sets a config value.
	*
	*	Params:
	*		key = Name of the key to set.
	*		value = The value to be set to.
	*/
	void set(T)(immutable string key, T value) pure @safe
	{
		static if(!is(T == string))
		{
			string convValue = to!string(value);
		}
		else
		{
			string convValue = value;
		}

		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			values_[groupAndKey.group][groupAndKey.key] = convValue;
		}
		else
		{
			values_[defaultGroupName_][key] = convValue;
		}

		valuesModified_ = true;
	}

	/**
	*	Sets the name used for the default section.
	*
	*	Params:
	*		name = The name of the default section should be called.
	*/
	void setDefaultGroupName(immutable string name) pure @safe
	{
		defaultGroupName_ = name;
	}

	/**
	*	Gets the name of the default section.
	*
	*	Returns:
	*		The name of the default section.
	*/
	string getDefaultGroupName()
	{
		return defaultGroupName_;
	}

	/**
	*	Determines if the key is found in the config file.
	*	The key can be either its name of in the format of groupName.keyName or just the keyName.
	*
	*	Params:
	*		key = Name of the key to get the value of
	*
	*	Returns:
	*		true if the config contains the key false otherwise.
	*/
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

	/**
	*	Determines if the key is found in the config file.
	*
	*	Params:
	*		groupName = Name of the group to retries keyName from.
	*		key = Name of the key to get the value from.
	*
	*	Returns:
	*		true if the config contains the key false otherwise.
	*/
	bool contains(immutable string group, immutable string key) pure @safe
	{
		if(containsGroup(group))
		{
			auto groupValues = getGroup(group);

			if(key in groupValues)
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
			auto groupValues = getGroup(defaultGroupName_);

			if(key in groupValues)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
	}

	/**
	*	Determines if the given groupName Exists.
	*
	*	Params:
	*		key = Name of the group to check for.
	*
	*	Returns:
	*		true if the group exists false otherwise.
	*/
	bool containsGroup(immutable string key) pure @safe
	{
		if(key in values_)
		{
			return true;
		}
		return false;
	}

	/**
	*	Removes a key/value from config.
	*	The key can be either its name of in the format of groupName.keyName or just the keyName.
	*
	*	Params:
	*		key = Name of the key to remove.
	*
	*	Returns:
	*		true if it was successfully removed false otherwise.
	*/
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

	/**
	*	Removes a key/value from config.
	*	The key can be either its name of in the format of group.keyor just the key.
	*
	*	Params:
	*		group = Name of the group where key is found.
	*		key = Name of the key to remove.
	*
	*	Returns:
	*		true if it was successfully removed false otherwise.
	*/
	bool remove(immutable string group, immutable string key) pure @safe
	{
		auto groupValues = getGroup(group);
		return groupValues.remove(key);
	}

	/**
	*	Removes a group from config.
	*
	*	Params:
	*		key = Name of the group to remove.
	*
	*	Returns:
	*		true if group was successfully removed false otherwise.
	*/
	bool removeGroup(immutable string key) pure @safe
	{
		return values_.remove(key);
	}

	string opIndex(string key) pure @safe
	{
		return get(key);
	}

	void opIndexAssign(T = string)(T value, string key) pure @safe
	{
		set(key, value);
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
	string text = "
		aBool=true
		float = 3443.443
		number=12071
		sentence=This is a really long sentence to test for a really long value string!
		time=12:04
		[section]
		groupSection=is really cool if this works!
		japan=true
		[another]
		world=hello
		japan=false
	";

	KeyValueConfig config;

	bool loaded = config.loadString(text);
	assert(loaded, "Failed to load string!");

	assert(config.containsGroup("section"));
	config.removeGroup("section");
	assert(!config.containsGroup("section"));
}
