
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

struct StructOptions(T)
{
	~this()
	{
		if(autoSave_)
		{
			save();
		}
	}

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
							writeln(generatedCode);
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

	void save()
	{
		if(configFileName_.length)
		{
			auto configFile = File(configFileName_, "w+");
			string keyValueData;

			foreach(field; __traits(allMembers, T))
			{
				keyValueData ~= field ~ " = " ~ mixin("to!string(data_." ~ field ~ ")") ~ "\n";
				//writeln(field, " = ", mixin("data_." ~ field));
			}

			configFile.write(keyValueData);
		}
	}

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

	void opIndexAssign(T)(T value, const string key) @trusted
	{
		set(key, value);
	}

	string configFileName_;
	bool autoSave_;
	T data_;
	alias data_ this;

	alias asInteger = as!long;
	alias asDecimal = as!double;
	alias asString = as!string;
	alias asBoolean = as!bool;
}
