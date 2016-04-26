module raijin.types.callbacks;

struct Callback(T)
{
	void opCall(Args...)(Args args)
	{
		if(callback_)
		{
			callback_(args);
		}
	}

	void set(T callback)
	{
		callback_ = callback;
	}

	bool isInitialized() const
	{
		if(callback_)
		{
			return true;
		}

		return false;
	}

	T callback_;
}
