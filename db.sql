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
fiat_now FLOAT NOT NULL,
fiat_start FLOAT NOT NULL,
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

/*This function uses the intial amount of money. Necessary step before initiating the trading algorithm.*/

/*ERROR 1064 (42000) at line 78 in file: '/media/david/Drive/Binder/Csc_336/Assignments/Group Project/Code/sql-crypto-data-filler/db.sql': You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near 'SET @amount = cash/@current_price;
END' at line 9
ERROR 1064 (42000) at line 97 in file: '/media/david/Drive/Binder/Csc_336/Assignments/Group Project/Code/sql-crypto-data-filler/db.sql': You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near 'DELIMITER;

UPDATE wallets
SET wallets.fiat_start = 5, wallets.fiat_now = 5;
*/

/*todo
have a look at the templates on blackbord
try running this procedure on the lab database
try running it as individual commands
email nikita@cs.cuny.edu
send barnett the schema for the database and the code for the storedprocedure
*/
DELIMITER //

CREATE PROCEDURE Buy_First_Coin (
	IN cash FLOAT, 
	IN coin_type INT, 
	INOUT amount FLOAT
)
BEGIN
	SET @current_price = (
		SELECT price
		FROM price_feed
		WHERE price_feed.coin = coin_type
		AND price = (
			SELECT min(price)
			FROM price_feed
			WHERE price_feed.coin = coin_type
		);
	);

	SET amount = cash / @current_price;
END

//

DELIMITER;

/*Add $5 to each coin-row of the wallets (total amount of cash in wallets = the number of coins * $5)*/
--UPDATE wallets SET wallets.fiat_start = 5, wallets.fiat_now = 5;
SET @coin_count = (
	SELECT DISTINCT count(coin_id)
	FROM coins
	ORDER BY coin_id;	
);

DECLARE @i INT = 0
WHILE @i <= @coin_count
BEGIN
    SET @i = @i + 1
    INSERT INTO wallets (fiat_start, fiat_now) VALUES (5,5);
END

/*The coin value in each row should correspond to a different coin from the coins table*/
UPDATE wallets 
SET wallets.coin = (
	SELECT DISTINCT coin_id
	FROM coins
	ORDER BY coin_id;
);

/*Subtract from the fiat_now to begin transaction & buy first coin. fiat_start is a record of our initial state,
while fiat_now is how many dollars are held in account for a particular coin.*/
CALL Buy_First_Coin (wallets.fiat_now, wallets.coin, wallets.amount);

UPDATE wallets SET wallets.fiat_now = 0;


/*Utility Function for the trigger Finds if price of coin in your current exchange had to increase or stay the same 
(so you can make a profit when you sell within the exchange.)*/
CREATE FUNCTION Compare_Current_to_Bought (@latest_price_coin INT, @latest_price_exchange INT) 
RETURNS BOOLEAN
AS
BEGIN
	SET @current_price = (
		SELECT price
		FROM price_feed
		WHERE coin = @latest_price_coin 
		AND date = (
			SELECT max(price_feed.date)
			FROM price_feed, wallets
			WHERE price_feed.exchange = wallets.exchange
			AND price_feed.coin = wallets.coin 
		)
	);

	SET @price_bought = (
		SELECT price
		FROM wallets
		WHERE coin = @latest_price_coin
	);

	RETURN (@current_price > @price_bought);
END


CREATE TRIGGER
AFTER INSERT ON price_feed
REFERENCING NEW ROW AS latest_price
FOR EACH ROW
WHEN(

	/*You have the latest_price.coin in your wallets and the amount (of coin) is more than zero*/
	EXISTS latest_price.coin IN(
		SELECT * 
		FROM wallets
		WHERE wallets.coin = latest_price.coin 
		AND amount>0
	)

	/*You have coins in some other exchange that you can use to buy discounted coins from the latest_price.exchange*/
	AND EXISTS(
		SELECT *
		FROM wallets
		WHERE wallets.coin = latest_price.coin 
		AND wallets.exchange<>latest_price.exchange
	)
		
	/*The price of coin in your current exchange had to increase or stay the same (so you can make a profit when you sell within the exchange.)*/
	AND Compare_Current_to_Bought(latest_price.coin, latest_price.exchange) = true

	/*The price of your bitcoin on your exchange had to increase relative to another fund (so you can reinvest your earnings and buy discounted coins from a cheaper exchange.)*/
	AND latest_price.price < (
		SELECT price
		FROM wallets
		WHERE latest_price.coin = wallets.coin
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
		FROM wallets
		WHERE coin = latest_price.coin		
	);

	/*Temporary variable for fiat_now*/
	SET @money_made = (@current_exchange_price * @amount);

	SET @new_amount = (@money_made / latest_price.price);

	UPDATE wallets 
	SET wallets.exchange = latest_price.exchange, wallets.amount = @new_amount, wallets.price = latest_price.price
	WHERE wallets.coin = latest_price.coin;

END

/*
Viewing the wallets table as the relation describing one (and only one) person's holdings, 
the rows correspond to different amount-currency-exchange-price combinations.

personal wallets
------
amount = amount of coin
coin = type of coin
exchange = the exchange the coin was bought on
price = the price the coin was bought at in US Dollars

also we need to output to dollars, so there ought to be two new attributes
fiat_start = the money we started with in the initial state
fiat_now = the amount of money in the account now (should be 0 if there's any BTC in the exchange)
*/