// Author: Ivan Kazmenko (gassa@mail.ru)
module do_create;
import std.algorithm;
import std.ascii;
import std.conv;
import std.format;
import std.range;
import std.stdio;
import std.string;

void main ()
{
	auto input = File ("alchemy-recipes.csv", "rt").byLineCopy.array;
	string [] [string] recipes;
	foreach (ref line; input)
	{
		auto t = line.strip.split (',');
		auto parts = t[3..7];
		auto result = t[7];
		recipes[result] = parts;
	}

	auto writeTdElement (string str)
	{
		auto event = "";
		auto elementType = "ae-disabled";
		if (str in recipes)
		{
			event = format !(` onclick="constructPre ` ~
			    `(this, '%-(%s,%)')"`) (recipes[str]);
			elementType = "ae-clickable";
		}
		writefln !(`<td class="alchemy-element %s" ` ~
		    `width=18.000%%%s>%s</td>`) (elementType, event, str);
	}

	writefln !(`<!DOCTYPE html>`);
	writefln !(`<html xmlns="http://www.w3.org/1999/xhtml">`);
	writefln !(`<meta http-equiv="content-type" content="text/html;` ~
	    ` charset=UTF-8">`);
	writefln !(`<head>`);
	writefln !(`<title>Element Creation</title>`);
	writefln !(`<link rel="stylesheet" href="./create.css" ` ~
	    `type="text/css">`);
	writefln !(`</head>`);
	writefln !(``);
	writefln !(`<script>`);
	writefln !(`if (location.protocol !== 'https:') {`);
	writefln !(`	location.replace ` ~
	    `("https:${location.href.substring" +`);
	writefln !(`	    "(location.protocol.length)}");`);
	writefln !(`}`);
	writefln !(`</script>`);
	writefln !(`<script src='waxjs.js'></script>`);
	writefln !(``);
	writefln !(`<body>`);
	writefln !(``);
	writefln !(`<div class="left-part">`);
	writefln !(`<h2>Element Creation</h2>`);
	writefln !(``);
	writefln !(`<p>Warning: this third-party tool for the game ` ~
	    `is provided as is, with no warranty of any kind! ` ~
	    `The tool is <a href="https://github.com/GassaFM/alchemy">` ~
	    `open source</a>.</p>`);
	writefln !(`<p>First click selects the element. ` ~
	    `Second click tries to create it.</p>`);
	writefln !(`<p>You can create the next element ` ~
	    `after discover is done for the previous. ` ~
	    `If stuck, click the Discover button.</p>`);
	writefln !(``);
	writefln !(`<p height="5px"></p>`);
	writefln !(``);

	writefln !(`<table class="log" id="recipes-table">`);
	writefln !(`<thead>`);
	writefln !(`<th colspan="6">Recipes</th>`);
	writefln !(`</thead>`);
	foreach (ref line; input)
	{
		auto t = line.strip.split (',');
		auto parts = t[3..7];
		auto result = t[7];
		writefln !(`<tr>`);
		writeTdElement (result);
		writefln !(`<td class="item" width=10.000%%>&xlArr;</td>`);
		foreach (part; parts)
		{
			writeTdElement (part);
		}
		writefln !(`</tr>`);
	}
	writefln !(`</table>`);
	writefln !(`</div>`);
	writefln !(``);

	writefln !(`<div class="right-part">`);
	writefln !(`<p>`);
	writefln !(`<button id="login" onclick="loginSwitch ()">` ~
	    `Login</button>`);
	writefln !(`<button id="discover" onclick="discover ()">` ~
	    `Discover</button>`);
	writefln !(`<button id="updatebank" onclick="updateBank ()">` ~
	    `Update Bank</button>`);
	writefln !(`<button id="updatebalances" onclick="updateBalances ()">` ~
	    `Update Balances</button>`);
	writefln !(`</p>`);
	writefln !(`<p height="5px"></p>`);
	writefln !(`<center><h3>Events Log</h3></center>`);
	writefln !(`<pre id="response" style="height:80vh;` ~
	    `background-color:#EEEEEE;overflow-y:scroll;"></pre>`);
	writefln !(`</div>`);
	writefln !(``);

	writefln !(`<script src='create.js'></script>`);
	writefln !(`</body>`);
	writefln !(`</html>`);
}
