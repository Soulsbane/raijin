/**
	This module manages a config file format in the form of key=value. Much like an ini file but simpler.

	Authors:
		Paul Crane
*/

module raijin.keyvalueconfig;

import std.conv;
import std.string;
import std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.array;
import std.typecons;
import std.format;

import raijin.types.dynamic;
import raijin.types.functions;

private enum DEFAULT_GROUP_NAME = null;
private enum DEFAULT_CONFIG_FILE_NAME = "app.config";

private struct KeyValueData
{
	string key;
	DynamicType value;
	string group;
	string comment;
}

/**
	Generates a method for retrieving a key and returning it's value.

	Params:
		functionName = The generated functions name.

	Examples:
		mixin(generateAsMethodFor!long("asInteger"));
		// The above mixin call will generate the following code:
		long asInteger(const string key, long defaultValue = long.init)
		{
				DynamicType dynValue = get(key, defaultValue);
				return dynValue.asInteger;
		}
*/
private string generateAsMethodFor(T)(const string functionName) @safe
{
	return format(q{
		%s %s(const string key, %s defaultValue = %s.init)
		{
			DynamicType dynValue = get(key, defaultValue);
			return dynValue.%s;
		}
	}, T.stringof, functionName, T.stringof, T.stringof, functionName);
}

/**
	Handles the processing of config files.
*/
struct KeyValueConfig
{
	/**
		Processes the text found in config file into an array of KeyValueData structures.

		Params:
			text = The text to be processed.
	*/
	bool processText(const string text) @trusted
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
			else if(line.startsWith("["))
			{
				if(line.endsWith("]"))
				{
					immutable string groupName = line[1..$-1];
					currentGroupName = groupName;
				}
				else
				{
					return false; // Error incomplete group.
				}
			}
			else
			{
				auto groupAndKey = line.findSplit("=");
				immutable auto key = groupAndKey[0].stripRight();
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
				else
				{
					return false; // Error line doesn't contain an = sign.
				}
			}
		}

		return true;
	}

	/**
		Determines if the group string is in the form of group.key.

		Params:
			value = The string to test.

		Returns:
			true if the string is in the group.key form false otherwise.
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
		Retrieves the group and key from a string in the form of group.key.

		Params:
			value = The string to process.

		Returns:
			A tuple containing the group and key.
	*/
	auto getGroupAndKeyFromString(const string value) pure @safe
	{
		auto groupAndKey = value.findSplit(".");
		immutable auto group = groupAndKey[0].strip();
		immutable auto key = groupAndKey[2].strip();

		return tuple!("group", "key")(group, key);
	}

public
	/**
		Retrieves the value T associated with key where T is the designated type to be converted to.

		Params:
			key = Name of the key to get.

		Returns:
			The value associated with key.
	*/
	DynamicType get(const string key) @trusted
	{
		DynamicType defaultValue;

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
		Retrieves the value T associated with key where T is the designated type to be converted to.

		Params:
			key = Name of the key to get.
			defaultValue = Allow the assignment of a default value if key does not exist.

		Returns:
			The value associated with key.
	*/
	DynamicType get(T)(const string key, const T defaultValue) @trusted
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
		Retrieves the value T associated with key where T is the designated type to be converted to.

		Params:
			group = Name of the group to retrieve ie portion [groupName] of config file/string.
			key = Name of the key to get.
			defaultValue = Allow the assignment of a default value if key does not exist.

		Returns:
			The value of value of the key/value pair.
	*/
	DynamicType get(T)(const string group, const string key, const T defaultValue) @trusted
	{
		if(containsGroup(group))
		{
			return getGroupValue(group, key, defaultValue);
		}
		else
		{
			DynamicType value = defaultValue;
			return value;
		}
	}

	~this()
	{
		if(autoSave_)
		{
			save();
		}
	}

	/**
		Saves config values to the config file used when loading(loadFile).
	*/
	void save() @trusted
	{
		save(saveToFileName_);
	}

	/**
		Saves config values to the config file.

		Params:
			fileName = Name of the file which values will be stored.
	*/
	void save(string fileName) @trusted
	{
		if(fileName.length && valuesModified_)
		{
			auto configfile = File(fileName, "w+");
			string curGroup;

			foreach(data; values_)
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
		Loads a config fileName(app.config by default) to be processed.

		Params:
			fileName = The name of the file to be processed/loaded.
			autoSave = Enable saving on object destruction. Set ot true by default.

		Returns:
			Returns true on a successful load false otherwise.
	*/
	bool loadFile(const string fileName = DEFAULT_CONFIG_FILE_NAME, bool autoSave = true) @safe
	{
		autoSave_ = autoSave;
		saveToFileName_ = fileName;

		if(fileName.exists)
		{
			return processText(fileName.readText);
		}

		return false;
	}

	/**
		Similar to loadFile but loads and processes the passed string instead.

		Params:
			text = The string to process.
			autoSave = Enable saving on object destruction. Set ot true by default.

		Returns:
			Returns true on a successful load false otherwise.
	*/

	bool loadString(const string text, bool autoSave = true) @safe
	{
		autoSave_ = autoSave;

		if(text.length)
		{
			return processText(text);
		}
		else
		{
			return false;
		}
	}

	mixin(generateAsMethodFor!long("asInteger"));
	mixin(generateAsMethodFor!bool("asBoolean"));
	mixin(generateAsMethodFor!double("asDecimal"));
	mixin(generateAsMethodFor!string("asString"));

	/**
		Gets the value associated with the group and key.

		Params:
			group = Name of the group the value is stored in.
			key = Name of the key the value is stored in.
			defaultValue = The value to use if group and or key is not found.

		Returns:
			The value associated with the group and key.
	*/
	DynamicType getGroupValue(T)(const string group, const string key, const T defaultValue = T.init) @trusted
	{
		DynamicType value = defaultValue;
		auto found = values_.filter!(a => (a.group == group) && (a.key == key));

		if(!found.empty)
		{
			value = found.front.value;
		}

		return value;
	}

	/**
		Retrieves key/values associated with the group portion of a config file/string.

		Params:
			group = Name of the the group to retrieve.

		Returns:
			Returns an array containing all the key/values associated with group.

	*/
	auto getGroup(const string group) @trusted
	{
		return values_.filter!(a => a.group == group);
	}

	/**
		Retrieves an array containing key/values of all groups in the configfile omitting groupless key/values.

		Returns:
			An array containing every group.
	*/
	auto getGroups() @trusted
	{
		return values_.filter!(a => a.group != "");
	}

	/**
		Sets a config value.

		Params:
			key = Name of the key to set. Can be in the group.key form.
			value = The value to be set to.
	*/
	void set(T)(const string key, const T value) @trusted
	{
		if(isGroupString(key))
		{
			immutable auto groupAndKey = getGroupAndKeyFromString(key);
			set(groupAndKey.group, groupAndKey.key, value);
		}
		else
		{
			set(DEFAULT_GROUP_NAME, key, value);
		}
	}

	/**
		Sets a config value.

		Params:
			group = Name of the group key belongs to.
			key = Name of the key to set.
			value = The value to be set to.
	*/
	void set(T = string)(const string group, const string key, const T value) @trusted
	{
		auto foundValue = values_.filter!(a => (a.group == group) && (a.key == key));

		if(foundValue.empty)
		{
			KeyValueData data;

			data.key = key;
			data.group = group;
			data.value = value;

			values_ ~= data;
		}
		else
		{
			foundValue.front.value = value;
		}

		valuesModified_ = true;
	}

	/**
		Determines if the key is found in the config file.
		The key can be either its name of in the format of groupName.keyName or just the key name.

		Params:
			key = Name of the key to get the value of

		Returns:
			true if the config file contains the key false otherwise.
	*/
	bool contains(const string key) @safe
	{
		if(isGroupString(key))
		{
			immutable auto groupAndKey = getGroupAndKeyFromString(key);
			return contains(groupAndKey.group, groupAndKey.key);
		}

		return contains(DEFAULT_GROUP_NAME, key);
	}

	/**
		Determines if the key is found in the config file.

		Params:
			group = Name of the group to get entries from.
			key = Name of the key to get the value from.

		Returns:
			true if the config file contains the key false otherwise.
	*/
	bool contains(const string group, const string key) @trusted
	{
		if(containsGroup(group))
		{
			auto groupValues = getGroup(group);
			return groupValues.canFind!(a => a.key == key);
		}

		return false; // The group wasn't found so no point in checking for a group and value.
	}

	/**
		Determines if the given group exists.

		Params:
			group = Name of the group to check for.

		Returns:
			true if the group exists false otherwise.
	*/
	bool containsGroup(const string group) @trusted
	{
		return values_.canFind!(a => a.group == group);
	}

	/**
		Removes a key/value from config file.
		The key can be either its name of in the format of groupName.keyName or just the keyName.

		Params:
			key = Name of the key to remove. Can be in the group.name format.

		Returns:
			true if it was successfully removed false otherwise.
	*/
	bool remove(const string key) @trusted
	{
		if(isGroupString(key))
		{
			immutable auto groupAndKey = getGroupAndKeyFromString(key);

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
		Removes a key/value from config file.
		The key can be either its name of in the format of group.keyor just the key.

		Params:
			group = Name of the group where key is found.
			key = Name of the key to remove.

		Returns:
			true if it was successfully removed false otherwise.
	*/
	bool remove(const string group, const string key) @trusted
	{
		values_ = values_.remove!(a => (a.group == group) && (a.key == key));
		valuesModified_ = true;

		return contains(group, key);
	}

	/**
		Removes a group from the config file.

		Params:
			group = Name of the group to remove.

		Returns:
			true if group was successfully removed false otherwise.
	*/
	bool removeGroup(const string group) @trusted
	{
		values_ = values_.remove!(a => a.group == group);
		valuesModified_ = true;

		return containsGroup(group);
	}

	/**
		Allows config values to be accessed as you would with an associative array.

		Params:
			key = Name of the value to retrieve

		Returns:
			The string value associated with the key.
	*/
	DynamicType opIndex(const string key) @trusted
	{
		immutable string defaultValue;
		return get(key, defaultValue);
	}

	/**
		Allows config values to be assigned as you would with an associative array.

		Params:
			key = Name of the key to assign the value to.
			value = The value in which key should be assigned to.
	*/
	void opIndexAssign(T)(T value, const string key) @trusted
	{
		set(key, value);
	}

private:
	KeyValueData[] values_;
	bool valuesModified_;
	bool autoSave_;
	string saveToFileName_;
}

///
unittest
{
	writeln;
	writeln("<=====================Beginning test for keyvalueconfig module=====================>");

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
		[group]
		dog=false
		#Who doesn't love cats?
		cat=true
	";

	KeyValueConfig config;

	immutable bool loaded = config.loadString(text, false);
	immutable bool failLoaded = config.loadString("", false);

	assert(loaded, "Failed to load string!");
	assert(!failLoaded);

	assert(config.containsGroup("section"));
	config.removeGroup("section");
	assert(config.containsGroup("section") == false);

	assert(config.asBoolean("aBool"));
	assert(config.contains("time"));

	immutable auto number = config["number"];

	assert(number == 12_071);
	assert(config["decimal"] == 3443.443);

	assert(config.contains("another.world"));
	assert(config["another.world"] == "hello");
	config.remove("another.world");
	assert(config.contains("another.world") == false);
	assert(config.contains("anothers", "world") == false);

	assert(config.contains("number"));
	config.remove("number");
	assert(config.contains("number") == false);

	assert(config["another.japan"] == false);
	config.set("another.japan", true);
	assert(config["another.japan"] == true);
	config["another.japan"] = false;
	assert(config.get("another.japan") == false);
	assert(config.get("another.nippon", true) == true);
	assert(config.get("japan", "nippon", true) == true);

	// Tests for nonexistent keys
	assert(config.asString("nonexistent", "Value doesn't exist!") == "Value doesn't exist!");
	config["nonexistent"] = "The value now exists!!!";
	assert(config.asString("nonexistent", "Value doesn't exist!") == "The value now exists!!!");

	writeln("Testing getGroup...");

	auto group = config.getGroup("group");

	foreach(value; group)
	{
		writeln(value.comment);
		writeln(value.key, " = ", value.value);
	}

	writeln();

	config.set("aBool", false);
	config["aBool"] = true;
	assert(config["aBool"].asString == "true");

	bool removeFileIfExists(const string fileName)
	{
		if(fileName.exists)
		{
			fileName.remove;
		}

		return !fileName.exists;
	}

	immutable fileName = "custom-config-format.dat";

	removeFileIfExists(fileName);
	assert(!config.loadFile(fileName, false));
	debug config.save();
	debug config.save(fileName);
	assert(config.loadFile(fileName, false));

	removeFileIfExists(fileName);
	removeFileIfExists(DEFAULT_CONFIG_FILE_NAME);

	string noEqualSign = "
		equal=sign
		time=12:04
		This is a really long sentence to test for a really long value string!
	";

	immutable bool equalSignValue = config.loadString(noEqualSign, false);
	assert(equalSignValue == false);

	string invalidGroup = "
		[first]
		equal=sign
		time=12:04
		[second
		another=key value is here
	";

	immutable bool invalidGroupValue = config.loadString(invalidGroup, false);
	assert(invalidGroupValue == false);

	auto groups = config.getGroups();

	writeln("Generating asByte method string:");
	writeln(generateAsMethodFor!byte("asByte"));
	writeln;
}
