/**
	Simple module for dealing with queues.

	Authors:
		Paul Crane
*/
module raijin.types.queue;

import std.container : DList;

/**
	A simple implementation of a queue.
*/
struct SimpleQueue(T)
{
	/**
		Pushes a value into the queue.

		Params:
			value = The value to push onto the queue.
	*/
	void push(const T value) pure @safe
	{
		data_.insertFront(value);
	}

	/**
		Pops the value at the queues back off the queue.

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
		Retrieves the value at the back of the queue(the first value pushed).

		Returns:
			The value at the front of the queue.
	*/
	T front() pure const @safe
	{
		return data_.back;
	}

	/**
		Determines if the queue is empty.

		Returns:
			true if the queue is empty false otherwise.
	*/
	bool empty() pure const @safe
	{
		return data_.empty;
	}

	alias enqueue = push;
	alias dequeue = pop;
private:
	DList!T data_;
}

///
unittest
{
	SimpleQueue!int queue;

	queue.push(1);
	queue.push(2);
	queue.push(3);
	assert(queue.pop() == 1);
	assert(!queue.empty);
	assert(queue.front == 2);
}
