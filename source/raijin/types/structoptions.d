/**
	A key value configuration format using compile time reflection and structs.
*/
module raijin.types.structoptions;

import std.traits;
import std.typecons;
import std.typetuple;
import std.conv;
import std.string;
import std.file;
import std.algorithm;
import std.array;
import std.getopt;
import std.stdio;

private enum DEFAULT_CONFIG_FILE_NAME = "app.config";

/**
	Used for the creation of key/value configuration format.
*/
struct StructOptions(T)
{
	~this()
	{
		if(autoSave_)
		{
			save();
		}
	}

	/**
		Loads a config fileName(app.config by default).

		Params:
			fileName = The name of the file to be processed/loaded. Will use app.config if no argument is passed.
			autoSave = Enable saving on object destruction. Set to true by default.

		Returns:
			Returns true on a successful load false otherwise.
	*/
	bool loadFile(const string fileName = DEFAULT_CONFIG_FILE_NAME, const bool autoSave = true)
	{
		if(fileName.exists)
		{
			configFileName_ = fileName;
			return loadString(fileName.readText);
		}
		else
		{
			return false;
		}
	}

	/**
		Similar to loadFile but loads and processes the passed string instead.

		Params:
			text = The string to process.

		Returns:
			Returns true on a successful load false otherwise.
	*/
	bool loadString(const string text)
	{
		if(text.length)
		{
			auto lines = text.lineSplitter().array;

			foreach(line; lines)
			{
				auto keyAndValue = line.findSplit("=");
				immutable string key = keyAndValue[0].strip();
				immutable string value = keyAndValue[2].strip();

				if(keyAndValue[1].length)
				{
					foreach(field; __traits(allMembers, T))
					{
						if(field == key)
						{
							// This generates code in the form of: data_.field=to!type(value);
							immutable string generatedCode = "data_." ~ field ~ "=to!" ~ typeof(mixin("data_." ~ field))
								.stringof ~ "(value);";

							mixin(generatedCode);
						}
					}
				}
			}

			return true;
		}
		else
		{
			return false;
		}
	}

	/**
		Saves config values to the config file to app.config or the user supplied name.
	*/
	void save()
	{
		if(configFileName_.length)
		{
			auto configFile = File(configFileName_, "w+");
			string keyValueData;

			foreach(field; __traits(allMembers, T))
			{
				keyValueData ~= field ~ " = " ~ mixin("to!string(data_." ~ field ~ ")") ~ "\n";
			}

			configFile.write(keyValueData);
		}
	}

	/**
		Retrieves the value  associated with key where T is the designated type to be converted to.

		Params:
			key = Name of the key to get.
			defaultValue = The defaultValue to use should the key not exist.

		Returns:
			The value associated with key.
	*/
	S as(S)(const string key, const S defaultValue = S.init)
	{
		S value = defaultValue;

		foreach(field; __traits(allMembers, T))
		{
			if(field == key)
			{
				try
				{
					immutable string generatedCode = "value = data_." ~ field ~ ".to!S;";
					mixin(generatedCode);
				}
				catch(ConvException ex)
				{
					return defaultValue;
				}
			}
		}

		return value;
	}

	/**
		Sets a config value.

		Params:
			key = Name of the key to set.
			value = The value of key.
	*/
	void set(S)(const string key, const S value)
	{
		foreach(field; __traits(allMembers, T))
		{
			if(field == key)
			{
				immutable string generatedCode = "data_." ~ field ~ " = value.to!" ~ typeof(mixin("data_." ~ field))
					.stringof ~ ";";

				mixin(generatedCode);
			}
		}
	}

	/**
		Determines if the key is found in the config file.

		Params:
			key = Name of the key to get the value of

		Returns:
			true if the config file contains the key false otherwise.
	*/
	bool contains(const string key) const
	{
		foreach(field; __traits(allMembers, T))
		{
			if(field == key)
			{
				return true;
			}
		}

		return false;
	}

	void opIndexAssign(T)(T value, const string key)
	{
		set(key, value);
	}

	alias data_ this;

	alias asInteger = as!long;
	alias asDecimal = as!double;
	alias asString = as!string;
	alias asBoolean = as!bool;
	alias get = as;

private:
	string configFileName_;
	bool autoSave_;
	T data_;
}

///
unittest
{
	struct VariedData
	{
		string name;
		size_t id;
	}

	immutable string data =
	q{
			name = Paul
			id = 50
	};

	StructOptions!VariedData options;
	options.loadString(data);

	assert(options.as("name", "onamae") == "Paul");
	assert(options.get("foo", "bar") == "bar");

	assert(options.contains("id"));
	assert(options.asInteger("id", 10) == 50);
	assert(options.asInteger("id") == 50);

	assert(options.name == "Paul");

	options.name = "Bob";
	assert(options.name == "Bob");

	options.set("name", "Kyle");
	assert(options.name == "Kyle");

	options["name"] = "Jim";
	assert(options.name == "Jim");

	assert(options.as!long("id", 1) == 50); // Can be infered but we'll explicitly send it here.
}
