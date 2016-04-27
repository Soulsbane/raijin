module raijin.types.queue;

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
