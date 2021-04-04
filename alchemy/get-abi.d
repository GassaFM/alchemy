// Author: Ivan Kazmenko (gassa@mail.ru)
module get_abi;
import std.algorithm;
import std.conv;
import std.datetime;
import std.format;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;

auto getWithData (Conn) (string url, string [string] data, Conn conn)
{
	return get (url ~ "?" ~ data.byKeyValue.map !(line =>
	    line.key ~ "=" ~ line.value).join ("&"), conn);
}

int main (string [] args)
{
//	auto dfuseToken = File ("../dfuse.token").readln.strip;
	auto connection = HTTP ();
//	connection.addRequestHeader ("Authorization", "Bearer " ~ dfuseToken);
//	connection.verbose (true);
	auto raw = getWithData
	    (args[1],
	    ["account": args[2],
	    "json": "true"],
	    connection);
	raw.write;
	return 0;
}
