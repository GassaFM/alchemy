// Author: Ivan Kazmenko (gassa@mail.ru)
module contract_abi_to_d;
import std.algorithm;
import std.conv;
import std.datetime;
import std.format;
import std.json;
import std.net.curl;
import std.range;
import std.stdio;
import std.string;

auto strPlus (const ref JSONValue s)
{
	if (s.str.startsWith ("name"))
	{
		return s.str.replace ("name", "Name");
	}
	if (s.str.startsWith ("symbol"))
	{
		return s.str.replace ("symbol", "CurrencySymbol");
	}
	if (s.str.startsWith ("asset"))
	{
		return s.str.replace ("asset", "CurrencyAmount");
	}
	return s.str;
}

int main (string [] args)
{
	auto name = args[1];
	auto a = File (name ~ ".json", "rb").readln.parseJSON ();
	auto file = File (name ~ "_abi.d", "wb");

	file.writefln !("module %s;") (name ~ "_abi");
	file.writefln !("import transaction;") ();

	if ("types" in a["abi"])
	{
		if (!a["abi"]["types"].array.empty)
		{
			file.writefln !("") ();
		}
		writeln (a["abi"]["types"].array);
		foreach (const ref type; a["abi"]["types"].array)
		{
			file.writefln !("alias %s = %s;")
			    (type["new_type_name"].str, type["type"].strPlus);
		}
	}

//	file.writefln !("") ();
//	file.writefln !("align (1):") ();

	foreach (const ref schema; a["abi"]["structs"].array)
	{
		file.writefln !("") ();
		file.writefln !("struct %s") (schema["name"].str);
		if (schema["base"].str != "")
		{
			assert (false, "inheritance is not supported yet");
		}
		file.writefln !("{") ();
//		file.writefln !("align (1):") ();
		if ("fields" in schema)
		{
			foreach (const ref field; schema["fields"].array)
			{
				file.writefln !("\t%s %s;")
				    (field["type"].strPlus, field["name"].str);
			}
		}
		file.writefln !("}") ();
	}

	if (!a["abi"]["tables"].array.empty)
	{
		file.writefln !("") ();
	}
	foreach (const ref table; a["abi"]["tables"].array)
	{
		file.writefln !("alias %s = %s;")
		    (table["name"].str ~ "Element", table["type"].str);
	}

	return 0;
}
