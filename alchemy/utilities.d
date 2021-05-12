// Author: Ivan Kazmenko (gassa@mail.ru)
module utilities;
import std.algorithm;
import std.conv;
import std.datetime;
import std.digest.sha;
import std.format;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import transaction;

auto getWithData (Conn) (string url, string [string] data, Conn conn)
{
	return get (url ~ "?" ~ data.byKeyValue.map !(line =>
	    line.key ~ "=" ~ line.value).join ("&"), conn);
}

string maybeStr () (const auto ref JSONValue value)
{
	if (value.isNull)
	{
		return "";
	}
	return value.str;
}

auto parseBinary (T) (ref ubyte [] buffer)
{
//	debug {writeln (T.stringof);}
	static if (is (Unqual !(T) == E [], E))
	{
		size_t len = 0;
		size_t shift = 0;
		while (true)
		{
			auto cur = parseBinary !(byte) (buffer);
//			len = (len << 7) | (cur & 127);
			len |= (cur & 127) << shift;
			if (!(cur & 128))
			{
				break;
			}
			shift += 7;
		}
//		debug {writeln ("length = ", len);}
		E [] res;
		res.reserve (len);
		foreach (i; 0..len)
		{
			res ~= parseBinary !(E) (buffer);
		}
		return res;
	}
	else static if (is (T == struct))
	{
		T res;
		alias fieldNames = FieldNameTuple !(T);
		alias fieldTypes = FieldTypeTuple !(T);
		static foreach (i; 0..fieldNames.length)
		{
			mixin ("res." ~ fieldNames[i]) =
			    parseBinary !(fieldTypes[i]) (buffer);
		}
		return res;
	}
	else
	{
		enum len = T.sizeof;
		T res = *(cast (T *) (buffer.ptr));
		buffer = buffer[len..$];
		return res;
	}
}

alias hexStringToBinary = str => str.chunks (2).map !(value =>
    to !(ubyte) (value, 16)).array;

int allowedSeconds;
long nowUnix;

shared static this ()
{
	nowUnix = Clock.currTime (UTC ()).toUnixTime ();
	try
	{
		auto f = File ("utilities_config.txt", "rt");
		allowedSeconds = f.readln.strip.to !(int);
	}
	catch (Exception e)
	{
		allowedSeconds = 86400;
	}
}

shared static this ()
{
	try
	{
		auto f = File ("error.txt", "rt");
	}
	catch (Exception e)
	{
		return;
	}
	throw new Exception ("error.txt is present");
}

void updateLogGeneric (alias doSpecific)
    (string endPoint, string queryForm, string query)
{
	string dfuseToken;
	try
	{
		dfuseToken = File ("./dfuse.token").readln.strip;
	}
	catch (Exception e)
	{
		dfuseToken = "";
	}
	auto sha256 = query.sha256Of.format !("%(%02x%)");

	immutable string cursorFileName = sha256 ~ ".cursor";
	string wideCursor;
	try
	{
		wideCursor = File (cursorFileName).readln.strip;
	}
	catch (Exception e)
	{
		wideCursor = "";
	}

	auto connection = HTTP ();
//	connection.verbose (true);
	connection.addRequestHeader ("content-type", "text/plain");
	stderr.writeln ("dfuse: ", dfuseToken);
	if (dfuseToken != "")
	{
		connection.addRequestHeader ("Authorization",
		    "Bearer " ~ dfuseToken);
	}
	auto logFile = File (sha256 ~ ".log", "ab");
	while (true)
	{
		auto filledQuery = format (queryForm, query, wideCursor);
		writeln ("updating ", query, ", cursor = ", wideCursor);
		debug {writeln (filledQuery);}
		auto raw = post (endPoint, filledQuery, connection);
		debug {writeln (raw);}
		auto cur = raw.parseJSON["data"]["searchTransactionsForward"];
		auto newCursor = cur["cursor"].maybeStr;
		if (newCursor == "")
		{
			writeln (query, " update complete");
			break;
		}
		auto oldCursor = wideCursor;
		wideCursor = newCursor;

		string [] res;
		foreach (const ref result; cur["results"].array)
		{
			auto curCursor = result["cursor"].maybeStr;
			if (result["trace"]["receipt"]["status"].maybeStr !=
			    "EXECUTED")
			{
				assert (false);
			}

			auto ts1 = result["trace"]["block"]["timestamp"]
			    .maybeStr;
			auto ts2 = SysTime.fromISOExtString (ts1, UTC ());
			auto ts3 = ts2.toSimpleString;
			auto timestamp = ts3[0..20];
			auto curUnix = ts2.toUnixTime ();
			if (nowUnix - curUnix > allowedSeconds)
			{
				auto f = File ("error.txt", "wt");
				f.writeln (nowUnix);
				f.writeln (curUnix);
				f.writeln (oldCursor);
				f.writeln (curCursor);
				throw new Exception ("error.txt generated");
			}

			doSpecific (res, result["trace"],
			    timestamp, curCursor);
		}

		foreach (const ref line; res)
		{
			logFile.writeln (line);
			logFile.flush ();
		}
		File (cursorFileName, "wb").writeln (wideCursor);
	}
}
