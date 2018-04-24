CREATE TABLE exchanges (
name VARCHAR(10) NOT NULL,
region VARCHAR(10) NOT NULL,
exchange_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);


CREATE TABLE coins (
symbol VARCHAR(5) NOT NULL,
name VARCHAR(30) NOT NULL,
coin_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);


CREATE TABLE price_feed (
coin INT,
price FLOAT NOT NULL,
date DATETIME NOT NULL default CURRENT_TIMESTAMP(),
exchange INT,
priceFeed_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,

FOREIGN KEY (coin) REFERENCES coins(coin_id),
FOREIGN KEY (exchange) REFERENCES exchanges(exchange_id)
);

CREATE TABLE wallets (
exchange INT,
coin INT,
price FLOAT NOT NULL,
amount FLOAT NOT NULL,
wallet_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,

FOREIGN KEY (exchange) REFERENCES exchanges(exchange_id),
FOREIGN KEY (coin) REFERENCES coins(coin_id)
);


CREATE TABLE transactions (
transaction_id int AUTO_INCREMENT PRIMARY KEY,
type ENUM('Buy', 'Sell') NOT NULL,
transactionPrice FLOAT NOT NULL,
transactionQty INT NOT NULL,
transactionTotal INT NOT NULL,
priceFeed_id INT,
originWallet INT,
destinationWallet INT,

FOREIGN KEY (priceFeed_id) REFERENCES price_feed(priceFeed_id),
FOREIGN KEY (originWallet) REFERENCES wallets(wallet_id),
FOREIGN KEY (destinationWallet) REFERENCES wallets(wallet_id)
);


CREATE TABLE coinexchanges (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
coin_id INT,
exchange_id INT,

FOREIGN KEY (coin_id) REFERENCES coins(coin_id),
FOREIGN KEY (exchange_id) REFERENCES exchanges(exchange_id)
);

create view V_coinexchanges
    as select ce.id
    as 'Coin Exchange id', c.name
    as 'Coin Name', c.symbol
    as 'symbol', e.name
    as 'Exchange Name',
    c.coin_id as 'coin_id',
    e.exchange_id as 'exchange_id' from coins c
        inner join coinexchanges ce on ce.coin_id = c.coin_id
        inner join exchanges e on e.exchange_id = ce.exchange_id;


UPDATE wallet
SET wallet.fiat_start = 1;

CREATE FUNCTION Compare_Current_to_Bought (/*no inputs*/) 
RETURNS BOOLEAN
AS
BEGIN
	SET @current_price = (
		SELECT price
		FROM price_feed
		WHERE coin=latest_price.coin 
		AND date = (
			SELECT max(date)
			FROM price_feed
			WHERE exchange = latest_price.exchange
		)
	);

	SET @price_bought = (
		SELECT price
		FROM wallet
		WHERE coin = latest_price.coin
	);

	RETURN @current_price > @price_bought;
END


CREATE TRIGGER
AFTER INSERT ON price_feed
REFERENCING NEW ROW AS latest_price
FOR EACH ROW
WHEN(

	/*You have the latest_price.coin in your wallet and the amount (of coin) is more than zero*/
	EXISTS latest_price.coin IN(
		SELECT * 
		FROM wallet
		WHERE wallet.coin = latest_price.coin 
		AND amount>0
	)

	/*You have coins in some other exchange that you can use to buy discounted coins from the latest_price.exchange*/
	AND EXISTS(
		SELECT *
		FROM wallet
		WHERE wallet.coin = latest_price.coin 
		AND wallet.exchange<>latest_price.exchange
	)
		
	/*The price of coin in your current exchange had to increase or stay the same (so you can make a profit when you sell within the exchange.)*/
	AND Compare_Current_to_Bought() = true

	/*The price of your bitcoin on your exchange had to increase relative to another fund (so you can reinvest your earnings and buy discounted coins from a cheaper exchange.)*/
	AND latest_price.price < (
		SELECT price
		FROM wallet
		WHERE latest_price.coin = wallet.coin
	)
)
BEGIN

	SET @current_exchange_price = (
			SELECT price
			FROM price_feed
			WHERE coin=latest_price.coin 
			AND date = (
				SELECT max(date)
				FROM price_feed
				WHERE exchange = latest_price.exchange
		)
	);

	SET @amount = (
		SELECT amount
		FROM wallet
		WHERE coin = latest_price.coin		
	);

	SET @money_made = (@current_exchange_price * @amount);

	SET @new_amount = (@money_made / latest_price.price);

	UPDATE wallet 
	SET wallet.exchange = latest_price.exchange, wallet.amount = @new_amount, wallet.price = latest_price.price
	WHERE wallet.coin = latest_price.coin;

END
/*
Viewing the wallet table as the relation describing one (and only one) person's holdings, 
the rows correspond to different amount-currency-exchange-price combinations.

personal wallet
------
amount = amount of coin
coin = type of coin
exchange = the exchange the coin was bought on
price = the price the coin was bought at in US Dollars

also we need to output to dollars, so there ought to be two new attributes
fiat_start = the money we started with in the initial state
fiat_now = the amount of money in the account now (should be 0 if there's any BTC in the exchange)
*/