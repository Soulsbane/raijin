/**
*	Various functions for working with arrays.
*
*	Author: Paul Crane
*/
module raijin.arrayutils;

import std.algorithm;

/**
* Removes the specified element from the array (once).
*
*	Params:
*		array = The array to remove value from.
*		value = The value to remove.
*/
void remove(T)(ref T[] array, T value)
{
	long index = array.countUntil(value);

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
}
