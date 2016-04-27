module raijin.types.queue;

import std.container : DList;

struct SimpleQueue(T)
{
	void push(const T value) pure @safe
	{
		data_.insertFront(value);
	}

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

	T back() pure const @safe
	{
		return data_.back;
	}

	bool empty() pure const @safe
	{
		return data_.empty;
	}
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
	assert(queue.back == 2);
}
