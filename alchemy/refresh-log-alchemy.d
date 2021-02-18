// Author: Ivan Kazmenko (gassa@mail.ru)
module refresh_log_alchemy;
import std.algorithm;
import std.conv;
import std.format;
import std.json;
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
		auto actor = actionJSON["authorization"]
		    .array.map !(line => line["actor"].maybeStr)
		    .front;

		auto name = actionJSON["name"].maybeStr;

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
          authorization {
            actor
          }
          name
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
