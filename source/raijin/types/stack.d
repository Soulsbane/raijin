/**
	Simple module for dealing with stacks.

	Authors:
		Paul Crane
*/
module raijin.types.stack;

import std.container : DList;

/**
	A simple implementation of a stack.
*/
struct SimpleStack(T)
{
	/**
		Pushes a value onto the stack.

		Params:
			value = The value to push onto the stack.
	*/
	void push(const T value) pure @safe
	{
		data_.insertBack(value);
	}

	/**
		Pops the value off the stack.

		Returns:
			The value that was popped.
	*/
	T pop() pure @safe
	{
		T value;

		if(!data_.empty)
		{
		 	value = data_.back;
			data_.removeBack;
		}

		return value;
	}

	/**
		Retrieves the last value pushed without popping.

		Returns:
			The value at the top of the stack.
	*/
	T top() pure const @safe
	{
		return data_.back;
	}

	/**
		Determines if the stack is empty.

		Returns:
			true if the stack is empty false otherwise.
	*/
	bool empty() pure const @safe
	{
		return data_.empty;
	}

	/**
		Retries the number of items in the stack;

		Returns:
			The number of items in the stack;
	*/
	size_t length() pure @safe
	{
		import std.algorithm : count;
		return count(data_[]);
	}

	/**
		Clears the stack.
	*/
	void clear() pure @safe
	{
		data_.clear();
	}

private:
	DList!T data_;
}

///
unittest
{
	SimpleStack!int stack;

	stack.push(1);
	stack.push(2);
	stack.push(3);

	assert(stack.length == 3);
	assert(stack.pop() == 3);
	assert(!stack.empty);
	assert(stack.top == 2);

	stack.clear();
	assert(stack.length == 0);
}
