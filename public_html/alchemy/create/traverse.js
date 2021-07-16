// Author: Ivan Kazmenko (gassa@mail.ru)
function recurRecipesAll (elem, fun) {
	if (elem in recipes) {
		for (part of recipes[elem]) {
			recurRecipesAll (part, fun);
		}
	}
	fun (elem);
}

function recurRecipesReuse (elem, funPre, funPost) {
	funPre (elem);
	if (elem in recipes) {
		for (part of recipes[elem]) {
			var num = balances[part] || 0;
			num += queueBuilds[part] || 0;
			num -= queueUses[part] || 0;
			num += preBuilds[part] || 0;
			num -= preUses[part] || 0;
//			alert (part + ' ' + num);
			if (num < 0) {
				recurRecipesReuse (part, funPre, funPost);
			}
		}
	}
	funPost (elem);
}
