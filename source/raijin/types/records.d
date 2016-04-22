module raijin.types.records;

import std.stdio;
import std.container : Array;
import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;
import std.parallelism : parallel;

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
						immutable string generatedCode = "data." ~ field ~ " = value;";
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
