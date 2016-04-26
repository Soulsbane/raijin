/**
	A simple module for working with a record format.

	Authors:
		Paul Crane
*/
module raijin.types.records;

import std.stdio;
import std.container : Array;
import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;

private Regex!char RECORD_FIELD_REGEX = ctRegex!(r"\s+(?P<key>\w+)\s+(?P<value>.*)");

/**
	Manages a record format.

	Example:
		--------------------------------------
		string records = "
			{
				firstName "Albert"
				lastName "Einstein"
			}

			{
				firstName "Grace"
				lastName "Hopper"
			}
		";

		struct SimpleRecord
		{
			string firstName;
			string lastName;
		}

		void main()
		{
			RecordCollector!SimpleRecord collector;
			collector.parse(records);

			foreach(entry; collector.getRecords())
			{
				writeln(entry);
			}
		}
		--------------------------------------
*/
struct RecordCollector(T)
{
	alias RecordArray = Array!T;
	alias StringArray = Array!string;

	/**
		Converts the record from a file to its corresponding struct T.

		strArray = The array of lines that contains an actual record.
	*/
	private T convertToRecord(StringArray strArray)
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

	/**
		Parses a string into an array of records.

		records = The string of records to process.
	*/
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

	debug
	{
		/**
			Outputs each record to stdout.
		*/
		void dump()
		{
			foreach(entry; recordArray_)
			{
				debug writeln(entry);
			}
		}
	}

	/**
		Returns an array of records.

		Returns:
			An array of records.
	*/
	auto getRecords()
	{
		return recordArray_;
	}

private:
	RecordArray recordArray_;
}
