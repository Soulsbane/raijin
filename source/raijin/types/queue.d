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
		Pushes a value onto the queue.

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
		Retrieves the value at the front of the queue(the first value pushed).

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

	/**
		Retries the number of items in the queue;

		Returns:
			The number of items in the queue;
	*/
	size_t length() pure @safe
	{
		import std.algorithm : count;
		return count(data_[]);
	}

	/**
		Clears the queue.
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

	foreach(value; queue.all) {}

	assert(queue.length == 3);
	assert(queue.pop() == 1);
	assert(!queue.empty);
	assert(queue.front == 2);

	queue.clear();
	assert(queue.length == 0);
}

/**
	Allows a queue to have a max capacity of elements. Default capacity is 10.

	Examples:
		CapacityQueue!(int, 2) queue;
		queue.push(1);
		queue.push(2);
		queue.push(3); // No values will be pushed onto the queue without a push first.
*/
struct CapacityQueue(T, alias capacity = 10)
{
	/**
		Pushes a value onto the queue.

		Params:
			value = The value to push onto the queue.
	*/
	void push(const T value) pure @safe
	{
		if(queue_.length < maxCapacity_)
		{
			queue_.push(value);
		}
	}

	SimpleQueue!T queue_;
	alias queue_ this;

private:

	size_t maxCapacity_ = capacity;
}

///
unittest
{
	CapacityQueue!(int, 3) cap;
	
	cap.push(22);
	cap.push(342);
	cap.push(858);
	cap.push(1);
	assert(cap.front == 22);
	cap.pop();
	assert(cap.front == 342);
}
