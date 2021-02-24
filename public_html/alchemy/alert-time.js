// Author: Ivan Kazmenko (gassa@mail.ru)
let updatedAt = document.getElementById ('updated-at');
fun ();
setInterval (fun, 15000);

function fun () {
	now = Math.floor ((new Date ()).getTime () / 1000);
	delta = Math.floor (Math.max (0, now - genTime) / 60);
	updatedAt.innerText = "(updated " + delta + " minutes ago)";
	if (delta < 10) {
		updatedAt.style["color"] = "#7F7F7F";
	} else {
		updatedAt.style["color"] = "#FF0000";
	}
}
