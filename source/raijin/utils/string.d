/**
	This module contains a few additons to handling strings.

	Author: Paul Crane
*/

module raijin.utils.string;

import std.string;
import std.conv;
import std.range;
import std.algorithm;

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
bool isVowelChar(char vowelChar) pure @safe
{
	const string vowels = "aeiou";
	return vowels.canFind!(a => a == vowelChar);
}

/**
	Pluralizes a string.

	Params:
		text = The word to pluralize.
		pluralizeToWord = The word to use when a value needs to be pluralized

	Returns:
		The pluralized string.
*/
string pluralize(const string text, const string pluralizeToWord = string.init) pure @safe
{
	return pluralize(text, 2, pluralizeToWord);
}

/**
	Pluralizes a string if count is greater than one.

	Params:
		text = The word to pluralize.
		count = The number of words.
		pluralizeToWord = The word to use when a value needs to be pluralized

	Returns:
		The pluralized string if more than one of type or singular form otherwise.
*/
string pluralize(const string text, const size_t count, const string pluralizeToWord = string.init) pure @safe
{
	string pluralizedNumber = text[0 .. $ - 1];

	if(count == 1)
	{
		pluralizedNumber = text;
	}
	else
	{
		immutable char lastChar = text[$ - 1];
		immutable char vowelChar = text[$ - 2];

		if(lastChar == 'y' && !isVowelChar(vowelChar))
		{
			if(pluralizeToWord.empty)
			{
				pluralizedNumber = pluralizedNumber ~ "ies";
			}
			else
			{
				pluralizedNumber = pluralizeToWord;
			}
		}
		else
		{
			if(pluralizeToWord.empty)
			{
				pluralizedNumber = text ~ "s";
			}
			else
			{
				pluralizedNumber = pluralizeToWord;
			}
		}
	}

	return pluralizedNumber;
}

///
unittest
{
	assert("fly".pluralize(10) == "flies");
	assert("fly".pluralize(1) == "fly");
	assert("book".pluralize(10) == "books");
	assert("book".pluralize(1) == "book");
	assert("boy".pluralize(2) == "boys");
	assert("key".pluralize(2) == "keys");
	assert("key".pluralize(2, "keyz") == "keyz");
	assert("key".pluralize(1, "keyz") == "key");
	assert("fly".pluralize(2, "fliez") == "fliez");
	assert("cat".pluralize == "cats");
	assert("cat".pluralize("catz") == "catz");
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
		auto c = str.front;

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
		auto c = str.front;

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
string toYesNo(const bool value)
{
	return value ? "Yes" : "No";
}

///
unittest
{
	assert(true.toYesNo == "Yes");
	assert(false.toYesNo == "No");
}
