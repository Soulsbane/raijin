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
import std.traits : isNumeric, isBoolean;
import std.array : empty, array;
import std.typecons : tuple;

// TODO: Possibly make values use ValueType instead of strings.
//import std.variant;
//import raijin.typeutils;
//alias ValueType = Algebraic!(string, bool, long, real);

private enum DEFAULT_GROUP_NAME = null;

struct KeyValueData
{
	string key;
	string value;
	string group;
	string comment;
}

struct KeyValueConfig
{
private:
	void processText(const string text) @safe
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
					data.value = value;
					data.group = currentGroupName;

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

	bool isGroupString(const string value) pure @safe
	{
		if(value.indexOf(".") == -1)
		{
			return false;
		}
		return true;
	}

	auto getGroupAndKeyFromString(const string value) pure @safe
	{
		auto groupAndKey = value.findSplit(".");
		auto group = groupAndKey[0].strip();
		auto key = groupAndKey[2].strip();

		return tuple!("group", "key")(group, key);
	}

public:
	
	/**
	*	Saves config values to config file.
	*
	*	Note:
	*		Currently there is a bug in DMD where a global objects destructor will not be called when it goes out of scope.
	*		Which in effect makes it so save is never called if your KeyValueConfig variable is a global variable. You must
	*		Manually call save() in this case until the bug is fixed in DMD.
	*/
	void save() @trusted
	{
		if(fileName_ != string.init)// && valuesModified_)
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
	*	Gets the value T of the key/value pair where T is the type the value should be converted to.
	*
	*	Params:
	*		key = Name of the key to get.
	*
	*	Returns:
	*		The value of value of the key/value pair.
	*
	*/
	T get(T = string)(const string key) @safe
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
			return get!T(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			return get!T(DEFAULT_GROUP_NAME, key, defaultValue);
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
	T get(T = string)(const string key, string defaultValue) @safe
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return get!T(groupAndKey.group, groupAndKey.key, defaultValue);
		}
		else
		{
			return get!T(DEFAULT_GROUP_NAME, key, defaultValue);
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
	T get(T = string)(const string group, const string key, string defaultValue) @safe
	{
		if(containsGroup(group))
		{
			return to!T(getGroupValue(group, key));
		}
		else
		{
			return to!T(defaultValue);
		}
	}

	string getGroupValue(const string group, const string key) @safe
	{
		auto value = values_.filter!(a => (a.group == group) && (a.key == key));//.take(1);
		return to!string(value.front.value);
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
	auto getGroup(const string group) pure @safe
	{
		return values_.filter!(a => a.group == group);
	}

	/**
	*	Retrieves an associative array containing every group
	*
	*	Returns:
	*		An associative array containing every group.
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
	void set(T)(const string key, T value) pure @safe
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

		valuesModified_ = true;
	}

	/**
	*	Sets a config value.
	*
	*	Params:
	*		group = Name of the group key belongs to.
	*		key = Name of the key to set.
	*		value = The value to be set to.
	*/
	void set(T)(const string group, const string key, T value) pure @safe
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
	*	The key can be either its name of in the format of groupName.keyName or just the keyName.
	*
	*	Params:
	*		key = Name of the key to get the value of
	*
	*	Returns:
	*		true if the config contains the key false otherwise.
	*/
	bool contains(const string key) pure @safe
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
	*		true if the config contains the key false otherwise.
	*/
	bool contains(const string group, const string key) pure @safe
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
	*	Determines if the given groupName Exists.
	*
	*	Params:
	*		key = Name of the group to check for.
	*
	*	Returns:
	*		true if the group exists false otherwise.
	*/
	bool containsGroup(const string value) pure @safe
	{
		return values_.canFind!(a => a.group == value);
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
	bool remove(const string key) pure @safe
	{
		if(isGroupString(key))
		{
			auto groupAndKey = getGroupAndKeyFromString(key);
			return remove(groupAndKey.group, groupAndKey.key);
		}
		else
		{
			return remove(DEFAULT_GROUP_NAME, key);
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
	bool remove(const string group, const string key) pure @safe
	{
		values_ = values_.remove!(a => (a.group == group) && (a.key == key));
		return contains(group, key);
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
	bool removeGroup(const string group) pure @trusted
	{
		values_ = values_.remove!(a => a.group == group);
		return containsGroup(group);
	}

	/**
	*	Allows config values to be accessed as you would with an associative array.
	*
	*	Params:
	*		key = Name of the value to retrieve
	*
	*	Returns:
	*		The value associated with the key.
	*/
	string opIndex(string key) @safe
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
	void opIndexAssign(T)(T value, string key) pure @safe
	{
		set(key, value);
	}

	// FIXME: Surely there is a better way to do this but at the moment dmd can't decern which overloaded function to use.
	private T getT(T)(const string key) @safe
	{
		return get!T(key);
	}

	alias integer = getT!long;
	alias uinteger = getT!ulong;
	alias floating = getT!double;
	alias boolean = getT!bool;

private:
	KeyValueData[] values_;
	string fileName_;
	bool valuesModified_;
}

unittest
{
	string text = "
		aBool=true
		float = 3443.443
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

	assert(config.get!bool("aBool") == true);
	assert(config.boolean("aBool")); // Syntactic sugar

	assert(config.contains("time"));

	assert(config.contains("another.world"));
	assert(config.get("another.world") == "hello");
	config.remove("another.world");
	assert(config.contains("another.world") == false);

	assert(config.contains("number"));
	config.remove("number");
	assert(config.contains("number") == false);

	assert(config["another.japan"] == "false");

	writeln("KeyValueConfig: Testing getGroup...");

	auto group = config.getGroup("another");

	foreach(value; group)
	{
		writeln(value);
	}

	writeln();

	config.set("aBool", "false");
	assert(config.get!bool("aBool") == false);
	config["aBool"] = true;
	assert(config.get!bool("aBool") == true);

	debug config.save();
}
