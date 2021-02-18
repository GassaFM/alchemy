module a_rplanet_abi;
import transaction;

struct cauldron
{
	Name account;
	CurrencySymbol [] elements;
	uint64 date;
}

struct cleansymbol
{
	string symbol_str;
}

struct deletenft
{
	CurrencySymbol element;
}

struct devfeelog
{
	CurrencyAmount quantity_dev_fee;
}

struct discover
{
	Name user;
}

struct getversion
{
}

struct globalc
{
	CurrencyAmount bank;
	uint64 opened_elements_count;
	CurrencySymbol last_open_element;
	uint64 total_retries;
	uint64 dev_fee_percent;
	uint64 referral_fee_percent;
	uint64 win_percent;
	uint64 spare2;
	uint64 spare3;
}

struct gmelement
{
	CurrencySymbol element;
	uint64 dateopen;
	Name useropen;
	uint32 burncount;
}

struct nftelement
{
	CurrencySymbol element;
	Name opener;
	uint64 dateopen;
	string idata;
	string mdata;
	Name category;
	uint32 minted;
	uint32 max_supply;
}

struct setbank
{
	CurrencyAmount quantity;
}

struct setdevfee
{
	uint64 dev_fee;
}

struct setreffee
{
	uint64 referral_fee;
}

struct setwinperc
{
	uint64 win_percent;
}

struct upsertnft
{
	CurrencySymbol element;
	string idata;
	string mdata;
	Name category;
	uint32 max_supply;
}

alias cauldronsElement = cauldron;
alias globalcElement = globalc;
alias gmelementsElement = gmelement;
alias nftelementsElement = nftelement;
