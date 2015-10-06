module raijin.flagconv;

bool flagToBool(T)(T flag)
{
	if(flag == T.yes)
	{
		return true;
	}
	return false;
}

T boolToFlag(T)(bool flag)
{
	if(flag == true)
	{
		return T.yes;
	}
	return T.no;
}
