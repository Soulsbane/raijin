/**
*	This module manages a config file format in the form of key=value. Much like an ini file but simpler.
*
*	Author: Paul Crane
*/

module raijin.keyvalueconfig;

import std.conv : to;
import std.string : lineSplitter, indexOf, strip, startsWith, endsWith, stripLeft, stripRight;
import std.stdio : File, writeln;
import std.file : exists, readText;
import std.algorithm : sort, findSplit, filter, canFind, remove;
import std.range : take;
//import std.traits : isNumeric, isBoolean;
import std.array : empty, array;
import std.typecons : tuple;
import std.variant;



import raijin.typeutils;
private enum DEFAULT_GROUP_NAME = null;

private struct KeyValueData
{
	string key;
	Variant value;
	string group;
	string comment;
}

/**
*	Handles the processing of config files.
*/
struct KeyValueConfig
{
private:

	/**
	*	Processes the text found in config file into an array of KeyValueData structures.
	*
	*	Params:
	*		text = The text to be processed.
	*/
	void processText(const string text) @trusted
	{
		auto lines = text.lineSplitter();
		string currentGroupName = DEFAULT_GROUP_NAME;
		string currentComment;

		foreach(line; lines)
		{
			line = strip(line);

			if(line.empty)
			{
				continue;
			}
			else if(line.startsWith("#"))
			{
				currentComment = line[1..$];
			}
			else if(line.startsWith("[") && line.endsWith("]"))
			{
				immutable string groupName = line[1..$-1];

				currentGroupName = groupName;
			}
			else
			{
				auto groupAndKey = line.findSplit("=");
				auto key = groupAndKey[0].stripRight();
				immutable auto value = groupAndKey[2].stripLeft();

				if(groupAndKey[1].length)
				{
					KeyValueData data;

					data.key = key;
					data.group = currentGroupName;

					if(value.isInteger)
					{
						data.value = to!long(value);
					}
					else if(value.isDecimal)
					{
						data.value = to!double(value);
					}
					else if(isBoolean(value, AllowNumericBooleanValues.no))
					{
						data.value = to!bool(value);
					}
					else
					{
						data.value = value;
					}

					if(currentComment != "")
					{
						data.comment = currentComment;
						currentComment = string.init;
					}

					values_ ~= data;
				}
			}
		}
	}

	/**
	*	Determines if the group string is in the form of group.key.
	*
	*	Params:
	*		value = The string to test.
	*
	*	Returns:
	*		true if the string is in the group.key form false otherwise.
	*/
	bool isGroupString(const string value) pure @safe
	{
		if(value.indexOf(".") == -1)
		{
			return false;
		}
		return true;
	}

	/**
	*	Retrieves the group and key from a string in the form of group.key.
	*
	*	Params:
	*		value = The string to process.
	*
	*	Returns:
	*		A tuple containing the group and key.
	*/
	auto getGroupAndKeyFromString(const string value) pure @safe
	{
		auto groupAndKey = value.findSplit(".");
		auto group = groupAndKey[0].strip();
		auto key = groupAndKey[2].strip();

		return tuple!("group", "key")(group, key);
	}

public:

	/**
	*	Saves config values to the config file.
	*/
	void save() @trusted
	{
		if(fileName_ != string.init && valuesModified_)
		{
			auto configfile = File(fileName_, "w+");
			string curGroup;

			foreach(key, data; values_)
			{
				if(curGroup != data.group)
				{
					curGroup = data.group;
					if(curGroup != DEFAULT_GROUP_NAME)
					{
						configfile.writeln("[", curGroup, "]");
					}
				}

				if(data.comment.length)
				{
					configfile.writeln("#", data.comment);
				}

				configfile.writeln(data.key, " = ", data.value);
			}
		}
	}

	/**
	*	Loads a config fileName(app.config by default) to be processed.
	*
	*	Params:
	*		fileName = The name of the file to be processed/loaded.
	*	Returns:
	*		Returns true on a successful load false otherwise.
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

	bool loadString(const string text, string fileName = "app.config") @safe
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
	*	Retrieves the value T associated with key where T is the designated type to be converted to.
	*
	*	Params:
	*		key = Name of the key to get.
	*
	*	Returns:
	*		The value associated with key.
	*
	*/
	Variant get(const string key) @safe
	{
		string defaultValue;

		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return get(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			return get(DEFAULT_GROUP_NAME, key, defaultValue);
		}
	}

	/**
	*	Retrieves the value T associated with key where T is the designated type to be converted to.
	*
	*	Params:
	*		key = Name of the key to get.
	*		defaultValue = Allow the assignment of a default value if key does not exist.
	*
	*	Returns:
	*		The value associated with key.
	*
	*/
	Variant get(const string key, string defaultValue) @safe
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return get(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			return get(DEFAULT_GROUP_NAME, key, defaultValue);
		}
	}

	/**
	*	Retrieves the value T associated with key where T is the designated type to be converted to.
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
	Variant get(const string group, const string key, string defaultValue) @trusted
	{
		if(containsGroup(group))
		{
			return getGroupValue(group, key);
		}
		else
		{
			return Variant(defaultValue);
		}
	}

	/**
	*	Gets the value associated with the group and key.
	*
	*	Params:
	*		group = Name of the group the value is stored in.
	*		key = Name of the key the value is stored in.
	*
	*	Returns:
	*		The value associated with the group and key.
	*/
	Variant getGroupValue(const string group, const string key) @trusted
	{
		auto value = values_.filter!(a => (a.group == group) && (a.key == key));//.take(1);
		return value.front.value;
	}

	/**
	*	Retrieves key/values associated with the group portion of a config file/string.
	*
	*	Params:
	*		group = Name of the the group to retrieve.
	*
	*	Returns:
	*		Returns an array containing all the key/values associated with group.
	*
	*/
	auto getGroup(const string group) @trusted
	{
		return values_.filter!(a => a.group == group);
	}

	/**
	*	Retrieves an array containing key/values of all groups in the configfile omitting groupless key/values.
	*
	*	Returns:
	*		An array containing every group.
	*/
	auto getGroups()
	{
		return values_.filter!(a => a.group != "");
	}

	/**
	*	Sets a config value.
	*
	*	Params:
	*		key = Name of the key to set. Can be in the group.key form.
	*		value = The value to be set to.
	*/
	void set(T)(const string key, T value) @trusted
	{
		string convValue;

		static if(!is(T == string))
		{
			convValue = to!string(value);
		}
		else
		{
			convValue = value;
		}

		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			auto group = groupAndKey.group;

			set(group, key, value);
		}
		else
		{
			set(DEFAULT_GROUP_NAME, key, value);
		}
	}

	/**
	*	Sets a config value.
	*
	*	Params:
	*		group = Name of the group key belongs to.
	*		key = Name of the key to set.
	*		value = The value to be set to.
	*/
	void set(T)(const string group, const string key, T value) @trusted
	{
		string convValue;

		static if(!is(T == string))
		{
			convValue = to!string(value);
		}
		else
		{
			convValue = value;
		}

		auto foundValue = values_.filter!(a => (a.group == group) && (a.key == key));

		foundValue.front.value = convValue;
		valuesModified_ = true;
	}

	/**
	*	Determines if the key is found in the config file.
	*	The key can be either its name of in the format of groupName.keyName or just the key name.
	*
	*	Params:
	*		key = Name of the key to get the value of
	*
	*	Returns:
	*		true if the config file contains the key false otherwise.
	*/
	bool contains(const string key) @trusted
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return contains(groupAndKey.group, groupAndKey.key);
		}
		else
		{
			return contains(DEFAULT_GROUP_NAME, key);
		}
	}

	/**
	*	Determines if the key is found in the config file.
	*
	*	Params:
	*		group = Name of the group to get entries from.
	*		key = Name of the key to get the value from.
	*
	*	Returns:
	*		true if the config file contains the key false otherwise.
	*/
	bool contains(const string group, const string key) @trusted
	{
		if(containsGroup(group))
		{
			auto groupValues = getGroup(group);
			return groupValues.canFind!(a => a.key == key);
		}
		else
		{
			//FIXME: Really this should just return false?
			auto groupValues = getGroup(DEFAULT_GROUP_NAME);
			return groupValues.canFind!(a => a.key == key);
		}
	}

	/**
	*	Determines if the given group exists.
	*
	*	Params:
	*		group = Name of the group to check for.
	*
	*	Returns:
	*		true if the group exists false otherwise.
	*/
	bool containsGroup(const string group) @trusted
	{
		return values_.canFind!(a => a.group == group);
	}

	/**
	*	Removes a key/value from config file.
	*	The key can be either its name of in the format of groupName.keyName or just the keyName.
	*
	*	Params:
	*		key = Name of the key to remove. Can be in the group.name format.
	*
	*	Returns:
	*		true if it was successfully removed false otherwise.
	*/
	bool remove(const string key) @trusted
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);

			valuesModified_ = true;
			return remove(groupAndKey.group, groupAndKey.key);
		}
		else
		{
			valuesModified_ = true;
			return remove(DEFAULT_GROUP_NAME, key);
		}
	}

	/**
	*	Removes a key/value from config file.
	*	The key can be either its name of in the format of group.keyor just the key.
	*
	*	Params:
	*		group = Name of the group where key is found.
	*		key = Name of the key to remove.
	*
	*	Returns:
	*		true if it was successfully removed false otherwise.
	*/
	bool remove(const string group, const string key) @trusted
	{
		values_ = values_.remove!(a => (a.group == group) && (a.key == key));
		valuesModified_ = true;

		return contains(group, key);
	}

	/**
	*	Removes a group from the config file.
	*
	*	Params:
	*		group = Name of the group to remove.
	*
	*	Returns:
	*		true if group was successfully removed false otherwise.
	*/
	bool removeGroup(const string group) @trusted
	{
		values_ = values_.remove!(a => a.group == group);
		valuesModified_ = true;

		return containsGroup(group);
	}

	/**
	*	Allows config values to be accessed as you would with an associative array.
	*
	*	Params:
	*		key = Name of the value to retrieve
	*
	*	Returns:
	*		The string value associated with the key.
	*/
	Variant opIndex(string key) @trusted
	{
		return get(key);
	}

	/**
	*	Allows config values to be assigned as you would with an associative array.
	*
	*	Params:
	*		key = Name of the key to assign the value to.
	*		value = The value in which key should be assigned to.
	*/
	void opIndexAssign(T)(T value, string key) @trusted
	{
		set(key, value);
	}

	// FIXME: Surely there is a better way to do this but at the moment dmd can't decern which overloaded function to use.
	private T getT(T)(const string key) @trusted
	{
		Variant value = get(key);
		return value.coerce!T;
	}

	alias getBool = getT!bool;
	alias getInt = getT!int;
	alias getFloat = getT!float;
	alias getReal = getT!real;
	alias getLong = getT!long;
	alias getByte = getT!byte;
	alias getShort = getT!short;
	alias getDouble = getT!double;
	alias getString = getT!string;

private:
	KeyValueData[] values_;
	string fileName_;
	bool valuesModified_;
}

unittest
{
	string text = "
		aBool=true
		decimal = 3443.443
		number=12071
		#Here is a comment
		sentence=This is a really long sentence to test for a really long value string!
		time=12:04
		[section]
		groupSection=is really cool if this works!
		japan=true
		babymetal=the one
		[another]
		#And another comment!
		world=hello
		japan=false
	";

	KeyValueConfig config;

	immutable bool loaded = config.loadString(text);
	assert(loaded, "Failed to load string!");

	assert(config.containsGroup("section"));
	config.removeGroup("section");
	assert(config.containsGroup("section") == false);

	assert(config.get("aBool").coerce!bool == true);
	assert(config.getBool("aBool")); // Syntactic sugar
	assert(config["aBool"].coerce!bool == true); // Also works

	assert(config.contains("time"));

	assert(config["number"] == 12071);
	assert(config["decimal"] == 3443.443);

	assert(config.contains("another.world"));
	assert(config["another.world"] == "hello");
	config.remove("another.world");
	assert(config.contains("another.world") == false);

	assert(config.contains("number"));
	config.remove("number");
	assert(config.contains("number") == false);

	assert(config["another.japan"] == false);

	writeln("KeyValueConfig: Testing getGroup...");

	auto group = config.getGroup("another");

	foreach(value; group)
	{
		writeln(value);
	}

	writeln();

	config.set("aBool", "false");
	assert(config["aBool"].coerce!bool == false);
	config["aBool"] = true;
	assert(config["aBool"].coerce!bool == true);
	assert(config["aBool"].toString == "true");

	debug config.save();
}
