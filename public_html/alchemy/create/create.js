// Author: Ivan Kazmenko (gassa@mail.ru)
// const urlWax = 'https://wax.greymass.com';
const urlWax = 'https://chain.wax.io';
const wax = new waxjs.WaxJS (urlWax, null, null, true);

const delay = msecs => new Promise ((resolve, reject) => {
	setTimeout (_ => resolve (), msecs)
});

var responseElement = document.getElementById ('response');

function scrollToBottom () {
	responseElement.scrollTop = responseElement.scrollHeight;
}

var scrollingObserver = new MutationObserver (scrollToBottom);
scrollingObserver.observe (responseElement,
    {characterData: true, childList: true});

var bank = 0.0;
var bankUpdate = 0;

var balances = {};

init ();

async function initBalances () {
	balances = {['AIR']: 0, ['EARTH']: 0, ['WATER']: 0, ['FIRE']: 0};
}

async function init () {
	initBalances ();
	updateBank ();
	var loggedIn = await wax.isAutoLoginAvailable ();
	if (loggedIn) {
		updateBalances ();
	}
}

async function doLog (s) {
	responseElement.append (s + '\n');
}

async function loginSwitch () {
	await login ();
/*
	if (wax.userAccount) {
		await logout ();
	} else {
		await login ();
	}
*/
}

async function logout () {
	doLog ('Logging out...');
//	???
	initBalances ();
	updateTable ();
}

async function login () {
	doLog ('Logging in...');
	try {
		const userAccount = await wax.login ();
		doLog ('Logged in as ' + userAccount);
	} catch (e) {
		doLog ('Login error: ' + e.message);
	}
	updateBalances ();
}

async function updateBank () {
	doLog ('Gameinfo: updating...');
	try {
		let data = {limit: 1, code: "a.rplanet",
		    table: "globalc", scope: "a.rplanet", json: true};
		var xhr = new XMLHttpRequest ();
		xhr.open ("POST",
		    urlWax + '/v1/chain/get_table_rows', true);
		xhr.setRequestHeader ('Content-Type', 'application/json');
		xhr.send (JSON.stringify (data));
		xhr.onload = async function () {
			var response = JSON.parse (this.responseText);
			bank = response.rows[0].bank;
			bank = bank.substring (0, bank.length - 4);
			bank = bank * 1.0;
			bankUpdate = Date.now ();
			doLog ('Gameinfo: done, price is ~' +
			    (bank * 1E-7).toFixed (8) + ' WAX');
		}
	} catch (e) {
		doLog ('Gameinfo error: ' + e.message);
	}
}

async function updateBalances () {
	doLog ('Balances: updating...');
	if (!wax.api) {
		doLog ('Balances error: ' + 'login first');
		return;
	}

	try {
		let data = {limit: 100, code: 'simpleassets',
		    table: 'accounts', scope: wax.userAccount, json: true};
		var xhr = new XMLHttpRequest ();
		xhr.open ("POST",
		    urlWax + '/v1/chain/get_table_rows', true);
		xhr.setRequestHeader ('Content-Type', 'application/json');
		xhr.send (JSON.stringify (data));
		xhr.onload = async function () {
			const response = JSON.parse (this.responseText);
			for (row of response.rows) {
				if (row.author == 'a.rplanet') {
					const temp = row.balance.split (' ');
					balances[temp[1]] = temp[0] | 0;
				}
			}
			doLog ('Balances: done');
			updateTable ();
		}
	} catch (e) {
		doLog ('Balances error: ' + e.message);
	}
}

function constructPre (cell, recipe) {
	if (cell.classList.contains ("ae-selected")) {
		cell.classList.remove ("ae-selected");
		cell.classList.add ("ae-clickable");
		construct (recipe);
	} else {
		for (elem of document.getElementsByClassName ('ae-selected')) {
			elem.classList.remove ("ae-selected");
			elem.classList.add ("ae-clickable");
		}
		cell.classList.add ("ae-selected");
		cell.classList.remove ("ae-clickable");
	}
}

async function construct (recipe) {
	doLog ('Constructing: ' + recipe + '...');
	if (!wax.api) {
		doLog ('Construct error: ' + 'login first');
		return;
	}

	try {
		const curMoment = Date.now ();
		if (curMoment - bankUpdate > 15000) {
			await updateBank ();
			await delay (1000);
		} else {
			updateBank ();
		}
		const payment = bank * 0.00000010000025;
		const slack = 0.0001;
		const bonus = 0.00009;
		const payLess = payment - slack;
		const payLessString = payLess.toFixed (8) + ' WAX';
		const bonusString = bonus.toFixed (8) + ' WAX';
		doLog ('Construct: ' + payLessString +
		    ' to game, ' + bonusString + ' to tool');
		const result = await wax.api.transact ({
			actions: [{
				account: 'eosio.token',
				name: 'transfer',
				authorization: [{
					actor: wax.userAccount,
					permission: 'active',
				}],
				data: {
					from: wax.userAccount,
					to: 'a.rplanet',
					quantity: payLessString,
					memo: 'construct:' + recipe
				},
			}, {
				account: 'eosio.token',
				name: 'transfer',
				authorization: [{
					actor: wax.userAccount,
					permission: 'active',
				}],
				data: {
					from: wax.userAccount,
					to: 'reservedness',
					quantity: bonusString,
					memo: 'a.rplanet::construct'
				},
			}]
		}, {
			useLastIrreversible: true,
			blocksBehind: 3,
			expireSeconds: 30
		});
		doLog ('Construct done!');
		await delay (1000);
		await discover ();
	} catch (e) {
		doLog ('Construct error: ' + e.message);
	}
}

async function discover () {
	doLog ('Discovering...');
	try {
		var xhr = new XMLHttpRequest ();
		xhr.open ("POST",
		    "https://prospectors.online/alchemy/create/rplanet-discover.php", true);
		xhr.setRequestHeader ('Content-Type', 'application/json');
		let data = {account: wax.userAccount};
		xhr.send (JSON.stringify (data));
		xhr.onload = async function () {
			var response = JSON.parse (this.responseText);
			doLog ('Discover done! ' + this.responseText);
			await delay (1000);
			updateBalances ();
		}
	} catch (e) {
		doLog ('Discover error: ' + e.message);
	}
}

async function updateTable () {
	var elements = document.getElementsByClassName ('alchemy-element');
	var good = false;
	for (elem in balances) {
		if (balances[elem] > 0) {
			good = true;
		}
	}
	for (elem of elements) {
		var s = elem.innerText;
		s = s.split (' ')[0];
		var num = '';
		if (good) {
			num = ' (' + (balances[s] || 0) + ')';
		}
		elem.innerText = s + num;
	}
}

async function claim () {
	doLog ('Claiming...');
	try {
		const result = await wax.api.transact ({
			actions: [{
				account: 's.rplanet',
				name: 'claim',
				authorization: [{
					actor: wax.userAccount,
					permission: 'active',
				}],
				data: {
					to: wax.userAccount
				},
			}]
		}, {
			blocksBehind: 3,
			expireSeconds: 30
		});
		value = result.processed.action_traces[0].inline_traces[0]
		    .act.data.quantity;
		doLog ('Claim done! ' + value);
	} catch (e) {
		doLog ('Claim error: ' + e.message);
	}
}
