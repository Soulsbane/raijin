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
import std.algorithm : each;

private Regex!char RECORD_FIELD_REGEX = ctRegex!(r"\s+(?P<key>\w+)\s{1,1}(?P<value>.*)");

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

		Params:
			strArray = The array of lines that contains an actual record.

		Returns:
			A struct of type T filled with record values mapped to the struct members.

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

		Params:
			records = The string of records to process.

		Returns:
			An $(LINK2 http://dlang.org/phobos/std_container_array.html, std.container.Array) of records.
	*/
	RecordArray parse(const string records)
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

		return recordArray_;
	}

	/**
		Loads a file of records and parses it.

		Params:
			fileName = The name of the file to parse.

		Returns:
			An $(LINK2 http://dlang.org/phobos/std_container_array.html, std.container.Array) of records.
	*/
	RecordArray parseFile(const string fileName)
	{
		import std.path : exists;
		import std.file : readText;

		RecordArray recArray;

		if(fileName.exists)
		{
			recArray = parse(fileName.readText);
		}

		return recArray;
	}

	debug
	{
		/**
			Outputs each record to stdout. $(B This method is only available in debug build).
		*/
		void dump()
		{
			debug recordArray_.each!writeln;
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

///
unittest
{
	import std.stdio : writeln;

	writeln;
	writeln("<=====================Beginning test for records module=====================>");

	immutable string data =
	q{
		{
			firstName "Albert"
			lastName "Einstein"
		}
	};

	struct NameData
	{
		string firstName;
		string lastName;
	}

	writeln("Processing records for NameData:");

	RecordCollector!NameData collector;
	collector.parse(data);

	auto records = collector.getRecords();

	foreach(record; records)
	{
		assert(record.firstName == "Albert");
		assert(record.lastName== "Einstein");
	}

	collector.dump();
	writeln;

	writeln("Processing records for VariedData:");

	immutable string variedData =
	q{
		{
			name "Albert Einstein"
			id "100"
		}
	};

	import raijin.utils.file : ensureFileExists, removeFileIfExists;

	enum fileName = "test-record.dat";
	fileName.ensureFileExists(variedData);

	struct VariedData
	{
		string name;
		size_t id;
	}

	RecordCollector!VariedData variedCollector;
	variedCollector.parseFile(fileName);

	auto variedRecords = variedCollector.getRecords();

	foreach(variedRecord; variedRecords)
	{
		assert(variedRecord.name == "Albert Einstein");
		assert(variedRecord.id == 100);
	}

	variedCollector.dump();
	writeln;
	fileName.removeFileIfExists;
}
