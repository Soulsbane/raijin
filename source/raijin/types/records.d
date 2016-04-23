module raijin.types.records;

import std.stdio;
import std.container : Array;
import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;

private Regex!char RECORD_FIELD_REGEX = ctRegex!(r"\s+(?P<key>\w+)\s+(?P<value>.*)");

struct RecordCollector(T)
{
	alias RecordArray = Array!T;
	alias StringArray = Array!string;

	T convertToRecord(StringArray strArray)
	{
		T data;

		foreach(line; strArray)
		{
			auto re = matchFirst(line, RECORD_FIELD_REGEX);

			if(!re.empty)
			{
				immutable string key = re["key"].removechars("\"");
				immutable string value = re["value"].removechars("\"");

				foreach(field; __traits(allMembers, T))
				{
					if(field == key)
					{
						import std.conv : to;

						// This generates code in the form of: data.field=to!type(value);
						immutable string generatedCode = "data." ~ field ~ "=to!" ~ typeof(mixin("data." ~ field)).stringof ~ "(value);";
						mixin(generatedCode);
					}
				}
			}
		}

		return data;
	}

	void parse(const string records)
	{
		import std.algorithm : canFind;
		auto lines = records.lineSplitter();

		StringArray strArray;

		foreach(line; lines)
		{
			if(line.canFind("{"))
			{
				strArray.clear();
			}
			else if(line.canFind("}"))
			{
				recordArray_.insert(convertToRecord(strArray));
			}
			else
			{
				strArray.insert(line);
			}
		}
	}

	void dump()
	{
		foreach(entry; recordArray_)
		{
			debug writeln(entry);
		}
	}

private:
	RecordArray recordArray_;
}
