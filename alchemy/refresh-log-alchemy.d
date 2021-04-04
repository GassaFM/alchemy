// Author: Ivan Kazmenko (gassa@mail.ru)
module refresh_log_alchemy;
import core.thread;
import std.algorithm;
import std.conv;
import std.datetime;
import std.exception;
import std.format;
import std.json;
import std.meta;
import std.range;
import std.stdio;
import std.string;
import std.traits;

import a_rplanet_abi;
import transaction;
import utilities;

alias thisToolName = moduleName !({});

void updateLogAlchemy (ref string [] res, const ref JSONValue resultTrace,
    const string timeStamp, const string curCursor)
{
	foreach (const ref actionJSON; resultTrace["matchingActions"].array)
	{
/*

		auto actor = actionJSON["authorization"]
		    .array.map !(line => line["actor"].maybeStr)
		    .front;
*/

		auto name = actionJSON["name"].maybeStr;
		if (name != "discover")
		{
			assert (false);
		}

		auto dataBuf = actionJSON["hexData"].str.hexStringToBinary;
		dataBuf = dataBuf[0..Name.sizeof];
		auto actor = dataBuf.parseBinary !(Name).text;
/*
		string actor;
		static foreach (theDiscover; AliasSeq !(discover1, discover2))
		{
			try
			{
				auto actionData = dataBuf.parseBinary
				    !(theDiscover);
				actor = actionData.user.text;
				enforce (dataBuf.empty);
			}
			catch (Exception e)
			{
			}
		}
		assert (actor != "");
*/

		auto recipe = "-";
		foreach (const ref op; actionJSON["cauldrons"].array)
		{
			recipe = op["oldData"].maybeStr;
		}
		auto element = "-";
		foreach (const ref op; actionJSON["gmelements"].array)
		{
			element = op["newData"].maybeStr;
		}

		res ~= format !("%s\t%s\t%s\t%s\t%s")
		    (timeStamp, name, actor, recipe, element);
	}
//	Thread.sleep (500.msecs);
}

int main (string [] args)
{
	stdout.setvbuf (16384, _IOLBF);
	immutable string queryForm = (`{"query": "{
  searchTransactionsForward(query: \"%s\",
                            irreversibleOnly: false,
                            limit: 100,
                            cursor: \"%s\") {
    cursor
    results {
      cursor
      trace {
        receipt {
          status
        }
        block {
          timestamp
        }
        matchingActions {
          name
          hexData
          account
          cauldrons: dbOps (table: \"cauldrons\") {
            oldData
          }
          gmelements: dbOps (table: \"gmelements\") {
            newData
          }
        }
      }
    }
  }
}"}`).splitter ('\n').map !(strip).join (' ');

	updateLogGeneric !(updateLogAlchemy) (args[1],
	    queryForm, "account:a.rplanet action:discover");
	return 0;
}
