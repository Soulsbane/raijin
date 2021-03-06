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

	/**
		Returns the entire queue array.

		Returns:
			The entire queue array.
	*/
	DList!T all()
	{
		return data_;
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

	foreach(value; stack.all) {}


	assert(stack.length == 3);
	assert(stack.pop() == 3);
	assert(!stack.empty);
	assert(stack.top == 2);

	stack.clear();
	assert(stack.length == 0);
}

/**
	Allows a stack to have a max capacity of elements. Default capacity is 10.

	Examples:
		CapacityStack!(int, 2) stack;
		stack.push(1);
		stack.push(2);
		stack.push(3); // No values will be pushed onto the stack without a push first.
*/
struct CapacityStack(T, alias capacity = 10)
{
	/**
		Pushes a value onto the stack.

		Params:
			value = The value to push onto the stack.
	*/
	void push(const T value) pure @safe
	{
		if(stack_.length < maxCapacity_)
		{
			stack_.push(value);
		}
	}

	SimpleStack!T stack_;
	alias stack_ this;

private:
	size_t maxCapacity_ = capacity;
}

///
unittest
{
	CapacityStack!(int, 3) cap;

	cap.push(22);
	cap.push(342);
	cap.push(858);
	cap.push(1);
	assert(cap.top == 858);
	cap.pop();
	assert(cap.top == 342);
}
