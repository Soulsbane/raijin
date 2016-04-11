/**
	Various functions for working with arrays.

	Authors:
		Paul Crane
*/
module raijin.utils.array;

import std.algorithm : countUntil;

/**
	Removes the specified element from the array in place.

	Params:
		array = The array to remove value from.
		value = The value to remove.
*/
void remove(T)(ref T[] array, T value)
{
	import std.algorithm : remove;
	size_t index = array.countUntil(value);

	if(index >= 0)
	{
		array = remove(array, index);
	}
}

unittest
{
	int[] test1 = [1, 2, 3];
	string[] test2 = ["one", "two", "three"];
	double[] test3 = [1.1, 2.2, 3.3];

	test1.remove(2);
	assert(test1 == [1, 3]);

	test2.remove("two");
	assert(test2 == ["one", "three"]);

	test3.remove(2.2);
	assert(test3 == [1.1, 3.3]);
}

/**
	Inserts a value into an array after a given value in place.

	Params:
		array = The array to insert value into.
		insertAfterValue = The value to insert after.
		valueToInsert = The value to insert.
*/
void insertValueInPlace(T)(ref T[] array, T insertAfterValue, T valueToInsert)
{
	import std.array : insertInPlace;
	size_t index = array.countUntil(insertAfterValue);

	if(index >= 0)
	{
		array.insertInPlace(++index, valueToInsert);
	}
}

unittest
{
	int[] test1 = [1, 2, 3, 4, 5, 6, 7];
	string[] test2 = ["one", "two", "three"];
	double[] test3 = [1.1, 2.2, 3.3];

	test1.insertValueInPlace(5, 88);
	assert(test1 == [1, 2, 3, 4, 5, 88, 6, 7]);

	test2.insertValueInPlace("two", "fifteen");
	assert(test2 == ["one", "two", "fifteen", "three"]);

	test3.insertValueInPlace(3.3, 8.8);
	assert(test3 == [1.1, 2.2, 3.3, 8.8]);
}
