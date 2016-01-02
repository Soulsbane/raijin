/**
*	This module contains a few additons to handling strings.
*
*	Author: Paul Crane
*/

module raijin.stringutils;

import std.string : indexOf, CaseSensitive;
import std.conv : to;
import std.range.primitives : empty, popFront, front;
import std.algorithm : canFind;

/**
*	Determines if a string has the value specified
*
*	Params:
*		value = The string to search.
*		toFindValue = The value to find.
*		cs = Set whether the search term is case sensitive. CaseSensitive.yes or CaseSensitive.no
*
*	Returns:
*		True if the toFindValue is found false otherwise.
*/
bool find(const string value, const string toFindValue, CaseSensitive cs = CaseSensitive.no) pure @safe
{
	if(value.indexOf(toFindValue, cs) == -1)
	{
		return false;
	}
	return true;
}

/**
*	Determines is a character is a vowel
*
*	Params:
*		vowelChar = The character to check.
*
*	Returns:
*		true if the character is a vowel false otherwise.
*/
bool isVowelChar(char vowelChar)
{
	string vowels = "aeiou";
	return vowels.canFind!(a => a == vowelChar);
}

/**
*	Pluralizes a string if count is greater than one.
*
*	Params:
*		text = The word to pluralize.
*		count = The number of words.
*		pluralizeToWord = The word to use when a value needs to be pluralized
*
*	Returns:
*		The pluralized string if more than one of type or singular form otherwise.
*/
string pluralize(const string text, const uint count, const string pluralizeToWord = string.init)
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

/**
*	Removes the charactor from the beginning of a string.
*
*	Params:
*		str = The string to remove characters from.
*		charToRemove = The character to remove.

*	Returns:
*		The modified string with all characters to be removed are removed.
*/
string removeLeadingChars(string str, const dchar charToRemove) @trusted
{
	// INFO: Surely there is a phobos function to do this but I couldn't find it.
	while (!str.empty)
	{
		auto c = str.front;

		if (c != charToRemove)
		{
			break;
		}

		str.popFront();
	}

	return str;
}

unittest
{
	assert("--help".removeLeadingChars('-') == "help");
	assert("--help-me".removeLeadingChars('-') == "help-me");
	assert("fly".pluralize(10) == "flies");
	assert("fly".pluralize(1) == "fly");
	assert("book".pluralize(10) == "books");
	assert("book".pluralize(1) == "book");
	assert("boy".pluralize(2) == "boys");
	assert("key".pluralize(2) == "keys");
	assert("key".pluralize(2, "keyz") == "keyz");
	assert("key".pluralize(1, "keyz") == "key");
	assert("bank".pluralize(2, "banksys") == "banksys");

	assert("Hello World".find("Hello") == true);
	assert("Hello World".find("hello") == true);
	assert("Hello World".find("hello", CaseSensitive.yes) == false);
}
