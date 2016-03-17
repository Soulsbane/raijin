/**
	Various functions for working with arrays.

	Authors:
		Paul Crane
*/
module raijin.utils.array;

import std.algorithm;

/**
	Removes the specified element from the array in place.

	Params:
		array = The array to remove value from.
		value = The value to remove.
*/
void remove(T)(ref T[] array, T value)
{
	size_t index = array.countUntil(value);

	if(index >= 0)
	{
		array = std.algorithm.remove(array, index);
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
