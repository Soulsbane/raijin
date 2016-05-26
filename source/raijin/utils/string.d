/**
	This module contains a few additons to handling strings.

	Authors:
		Paul Crane
*/

module raijin.utils.string;

import std.string : indexOf, CaseSensitive;
import std.conv : to;
import std.range : empty, popFront, front;
import std.algorithm : canFind, map, equal;

/**
	Determines if a string has the value specified

	Params:
		value = The string to search.
		toFindValue = The value to find.
		cs = Set whether the search term is case sensitive. CaseSensitive.yes or CaseSensitive.no

	Returns:
		True if the toFindValue is found false otherwise.
*/
bool find(const string value, const string toFindValue, CaseSensitive cs = CaseSensitive.no) pure @safe
{
	if(value.indexOf(toFindValue, cs) == -1)
	{
		return false;
	}
	return true;
}

///
unittest
{
	assert("Hello World".find("Hello") == true);
	assert("Hello World".find("hello") == true);
	assert("Hello World".find("hello", CaseSensitive.yes) == false);
}

/**
	Determines is a character is a vowel

	Params:
		vowelChar = The character to check.

	Returns:
*		true if the character is a vowel false otherwise.
*/
bool isVowelChar(const char vowelChar) pure @safe
{
	immutable string vowels = "aeiou";
	return vowels.canFind!(a => a == vowelChar);
}

///
unittest
{
	assert('a'.isVowelChar);
	assert('e'.isVowelChar);
	assert('i'.isVowelChar);
	assert('o'.isVowelChar);
	assert('u'.isVowelChar);
	assert('b'.isVowelChar == false);
	assert('z'.isVowelChar == false);
}

/**
	Pluralizes a string.

	Params:
		word = The word to pluralize.
		pluralizeToWord = The word to use when a value needs to be pluralized

	Returns:
		The pluralized string.
*/
string inPluralAlways(const string word, const string pluralizeToWord = null) pure @safe
{
	return inPlural(word, 2, pluralizeToWord);
}

/**
	Pluralizes a string if count is greater than one.

	Params:
		word = The word to pluralize.
		count = The number of words.
		pluralizeToWord = The word to use when a value needs to be pluralized

	Returns:
		The pluralized string if more than one of type or singular form otherwise.
*/
string inPlural(const string word, const size_t count = 2, const string pluralizeToWord = null) pure @safe
{
	if(count == 1 || word.length == 0)
	{
		return word;
	}

	if(pluralizeToWord !is null)
	{
		return pluralizeToWord;
	}

	switch(word[$ - 1])
	{
		case 's':
		//case 'a', 'e', 'i', 'o', 'u':
			return word ~ `es`;
		case 'f':
			return word[0 .. $-1] ~ `ves`;
		case 'y':
			return word[0 .. $-1] ~ `ies`;
		default:
			return word ~ `s`;
	}
}

///
unittest
{
	assert("fly".inPlural(10) == "flies");
	assert("fly".inPlural(1) == "fly");
	assert("book".inPlural(10) == "books");
	assert("book".inPlural(1) == "book");
	assert("boy".inPlural(2, "boys") == "boys");
	assert("key".inPlural(2, "keyz") == "keyz");
	assert("key".inPlural(1, "keyz") == "key");
	assert("fly".inPlural(2, "fliez") == "fliez");
	assert("cat".inPlural == "cats");
	assert("cat".inPluralAlways("catz") == "catz");
	assert("half".inPlural(10) == "halves");
	assert("zoo".inPlural(10) == "zoos");
	assert("boss".inPlural(10) == "bosses");
}

/**
	Pluralizes a string if count is greater than one in place.

	Params:
		word = The word to pluralize.
		count = The number of words.
		pluralizeToWord = The word to use when a value needs to be pluralized
*/
void inPluralInPlace(ref string word, const size_t count = 2, const string pluralizeToWord = null) pure @safe
{
	string temp = word;

	if(count == 1 || word.length == 0)
	{
		return;
	}

	if(pluralizeToWord !is null)
	{
		word = pluralizeToWord;
		return;
	}

	switch(temp[$ - 1])
	{
		case 's':
		//case 'a', 'e', 'i', 'o', 'u':
			word = word ~ `es`;
			break;
		case 'f':
			word = temp[0 .. $-1] ~ `ves`;
			break;
		case 'y':
			word = temp[0 .. $-1] ~ `ies`;
			break;
		default:
			word = word ~ `s`;
	}
}

///
unittest
{
	string fly = "fly";
	fly.inPluralInPlace(10);
	assert(fly == "flies");

	string fly2 = "fly";
	fly2.inPluralInPlace(1);
	assert(fly2 == "fly");

	string book = "book";
	book.inPluralInPlace(10);
	assert(book == "books");

	string book2 = "book";
	book2.inPluralInPlace(1);
	assert(book2 == "book");

	string boys = "boy";
	boys.inPluralInPlace(2, "boys");
	assert(boys == "boys");

	string fliez = "fly";
	fliez.inPluralInPlace(2, "fliez");
	assert(fliez == "fliez");

	string cat = "cat";
	cat.inPluralInPlace;
	assert(cat == "cats");

	string half = "half";
	half.inPluralInPlace(10);
	assert(half == "halves");

	string zoo = "zoo";
	zoo.inPluralInPlace(10);
	assert(zoo == "zoos");

	string boss = "boss";
	boss.inPluralInPlace(10);
	assert(boss == "bosses");
}

/**
	Pluralizes a string in place.

	Params:
		word = The word to pluralize.
		pluralizeToWord = The word to use when a value needs to be pluralized
*/
void inPluralAlwaysInPlace(ref string word, const string pluralizeToWord = null) pure @safe
{
	inPluralInPlace(word, 2, pluralizeToWord);
}

///
unittest
{
	string cat = "cat";
	cat.inPluralAlwaysInPlace("catz");
	assert(cat == "catz");
}

/**
	Removes the charactor from the beginning of a string.

	Params:
		str = The string to remove characters from.
		charToRemove = The character to remove.

	Returns:
		The modified string with all characters to be removed are removed.
*/
string removeLeadingChars(string str, const dchar charToRemove) pure @safe
{
	// INFO: Surely there is a phobos function to do this but I couldn't find it.
	while(!str.empty)
	{
		immutable auto c = str.front;

		if(c != charToRemove)
		{
			break;
		}

		str.popFront();
	}

	return str;
}

///
unittest
{
	assert("--help".removeLeadingChars('-') == "help");
	assert("--help-me".removeLeadingChars('-') == "help-me");
}

/**
	Modifies the passed string by removing the character specified.

	Params:
		str = The string to remove characters from.
		charToRemove = The character to remove.
*/
void removeLeadingCharsInPlace(ref string str, const dchar charToRemove) pure @safe
{
	// INFO: Surely there is a phobos function to do this but I couldn't find it.
	while(!str.empty)
	{
		immutable auto c = str.front;

		if(c != charToRemove)
		{
			break;
		}

		str.popFront();
	}
}

///
unittest
{
	string value = "--help";
	string anotherValue = "--help-me";

	value.removeLeadingCharsInPlace('-');
	anotherValue.removeLeadingCharsInPlace('-');

	assert(value == "help");
	assert(anotherValue == "help-me");
}

/// Converts all elements of an array to strings.
alias toStringAll = map!(to!string);

///
unittest
{
	assert(equal(toStringAll([ 1, 2, 3, 4 ]), [ "1", "2", "3", "4" ]));
}

/**
	Converts each argument to a string.

	Params:
		args = The variable number of arguments to convert.

	Returns:
		An array of containing the arguments converted to a string.
*/
auto toStringAll(T...)(T args)
{
	string[] output;

	foreach(arg; args)
	{
		output ~= to!string(arg);
	}

	return output;
}

///
unittest
{
	auto strings = toStringAll(10, 15);
	assert(equal(strings, ["10", "15"]));

	auto variousStrings = toStringAll(4.1, true, "hah", 5000);
	assert(equal(variousStrings, ["4.1", "true", "hah", "5000"]));
}

/**
	Converts a boolean value to a Yes or No string.

	Params:
		value = The boolean value to convert.

	Returns:
		Either a Yes for a true value or No for a false value.
*/
string toYesNo(T)(const T value)
{
	import std.typecons : isIntegral, isBoolean;

	static if(isIntegral!T)
	{
		return (value == 1) ? "Yes" : "No";
	}
	else static if(isBoolean!T)
	{
		return value ? "Yes" : "No";
	}
	else
	{
		return "No";
	}
}

///
unittest
{
	assert(true.toYesNo == "Yes");
	assert(false.toYesNo == "No");
	assert(1.toYesNo == "Yes");
	assert(0.toYesNo == "No");
	assert("hellow world".toYesNo == "No");
}

/**
	Converts a string value of Yes, 1 to true. Converts No or any other numeric value to false.

	Params:
		value = The stirng value to convert.

	Returns:
		Either a true for a "Yes" or false for No or any other numeric value.
*/
bool toBoolean(const string value)
{
	return (value == "Yes") || (value == "yes") || (value == "1") || (value == "true") ? true : false;
}

///
unittest
{
	assert("Yes".toBoolean == true);
	assert("yes".toBoolean == true);
	assert("No".toBoolean == false);
	assert("1".toBoolean == true);
	assert("0".toBoolean == false);
	assert("true".toBoolean == true);
	assert("false".toBoolean == false);
}

/**
	Formats a number using commas. Example 1000 => 1,000.

	Params:
		number = The number to format.

	Returns:
		The formatted number;
*/
string formatNumber(const string number)
{
	import std.regex : regex, replaceAll;

	auto re = regex(r"(?<=\d)(?=(\d\d\d)+\b)","g");
	return number.replaceAll(re, ",");
}

///
unittest
{
	assert(formatNumber("100") == "100");
	assert(formatNumber("1000") == "1,000");
	assert(formatNumber("1000000") == "1,000,000");
}

/**
	Formats a number using commas. Example 1000 => 1,000.

	Params:
		number = The number to format.

	Returns:
		The formatted number;
*/
string formatNumber(const size_t number)
{
	import std.conv : to;
	return number.to!string.formatNumber;
}

///
unittest
{
	assert(formatNumber(100) == "100");
	assert(formatNumber(1000) == "1,000");
	assert(formatNumber(1000000) == "1,000,000");
}
