/*Add $5 to each coin-row of the wallets (total amount of cash in wallets = the number of coins * $5)*/
--UPDATE wallets SET wallets.fiat_start = 5, wallets.fiat_now = 5;
DELIMITER //

CREATE PROCEDURE Init_Wallets()
BEGIN
	SET @i = 1;

	SET @coin_count = (
		SELECT DISTINCT count(coin_id)
		FROM coinexchanges
		ORDER BY coin_id
	);

  	WHILE @i <= @coin_count DO
  		SET @i = @i + 1;
    	INSERT INTO wallets (amount, price, fiat_start, fiat_now) VALUES (0,0,5,5);
	END WHILE;
END;
//

DELIMITER ;

CALL Init_Wallets();

/*The coin value in each row should correspond to a different coin from the coins table*/
UPDATE wallets 
SET wallets.coin = (
	SELECT DISTINCT coin_id
	FROM coinexchanges
	ORDER BY coin_id
);

/*This procedure uses the intial amount of money to purchase coin. Necessary step before initiating the trading algorithm.*/
DELIMITER //

CREATE PROCEDURE Row_Buy_First_Coin (
	IN cash FLOAT, 
	IN coin_type INT 
)
BEGIN
	SET @buy_price = (
		SELECT price
		FROM price_feed
		WHERE price_feed.coin = coin_type
		AND price = (
			SELECT min(price)
			FROM price_feed
			WHERE price_feed.coin = coin_type
		)
	);

	SET @amount = cash / @buy_price;

	UPDATE wallets 
		SET wallets.amount = @amount
		WHERE wallets.coin = coin_type;
END;
//

DELIMITER ;


DELIMITER //

CREATE PROCEDURE Table_Buy_First_Coin()
BEGIN
	SET coin_id = 0;
	SET cash = 5;

	SET @row_count = (
		SELECT DISTINCT count(coin)
		FROM wallets
		ORDER BY coin
	);

	/*using while loop because cursors are read-only in mariadb*/
  	WHILE @coin_id <= @row_count DO
		Row_Buy_First_Coin(cash, coin_id); /*Problem Line Right Here*/
  		SET @coin_id = @coin_id + 1;
	END WHILE;

	UPDATE wallets SET wallets.fiat_now = 0;
END;
//

DELIMITER ;

CALL Table_Buy_First_Coin();


/*Utility procedure for the trigger Finds whether price of coin in your current exchange increased
(so you can make a profit when you sell within the exchange.)*/
DELIMITER //

CREATE PROCEDURE Compare_Current_to_Bought (
	IN coin_name INT, 
	OUT truth_value BOOLEAN
)
BEGIN
	SET @current_price = (
		SELECT price
		FROM price_feed
		WHERE coin = coin_name 
		AND date = (
			SELECT max(price_feed.date)
			FROM price_feed, wallets
			WHERE price_feed.exchange = wallets.exchange
			AND price_feed.coin = coin_name
		)
	);

	SET @price_bought = (
		SELECT price
		FROM wallets
		WHERE coin = coin_name
	);

	SET truth_value = @current_price > @price_bought;
END;
//

DELIMITER ; -- watch out. you need a space between the delimter and the semi-colon. No idea why. It's on the maraidb documentation though.



/*The Trading Algoritm*/
DELIMITER //
CREATE TRIGGER trading_alg
AFTER INSERT ON price_feed
FOR EACH ROW
BEGIN
	SET @current_price_on_my_exchange = (
		SELECT price
		FROM price_feed
		WHERE coin = NEW.coin 
		AND date = (
			SELECT max(price_feed.date)
			FROM price_feed, wallets
			WHERE price_feed.exchange = wallets.exchange /*exchange already present in wallet*/
			AND price_feed.coin = NEW.coin
		)
	);

	CALL Compare_Current_to_Bought(NEW.coin, @truth_value);

	IF
		/*1 You have the NEW.coin in your wallets and the amount (of coin) is more than zero*/
		NEW.coin IN (
			SELECT * 
			FROM wallets
			WHERE wallets.coin = NEW.coin 
			AND amount>0
		)

		/*2 You have coins in some other exchange that you can use to buy discounted coins from the NEW.exchange*/
		AND EXISTS (
			SELECT *
			FROM wallets
			WHERE wallets.coin = NEW.coin 
			AND wallets.exchange<>NEW.exchange
		)
			
		/*3 The price of coin in your current exchange had to increase or stay the same (so you can make a profit when you sell within the exchange.)*/
		AND @truth_value = true

		/*4 The price of your bitcoin on your exchange had to increase relative to another fund (so you can reinvest your earnings and buy discounted coins from a cheaper exchange.)*/
		AND NEW.price < @current_price_on_my_exchange

		THEN
			SET @current_exchange_price = (
					SELECT price
					FROM price_feed
					WHERE coin=NEW.coin 
					AND date = (
						SELECT max(date)
						FROM price_feed
						WHERE exchange = NEW.exchange
				)
			);

			SET @amount = (
				SELECT amount
				FROM wallets
				WHERE coin = NEW.coin
			);

			/*Temporary variable for fiat_now*/
			SET @money_made = (@current_exchange_price * @amount);

			SET @new_amount = (@money_made / NEW.price);

			UPDATE wallets 
			SET wallets.exchange = NEW.exchange, wallets.amount = @new_amount, wallets.price = NEW.price
			WHERE wallets.coin = NEW.coin;
	END IF;
END;
//

DELIMITER ;


/*
## PERSONAL NOTES
	Viewing the wallets table as the relation describing one (and only one) person's holdings, 
	the rows correspond to different amount-currency-exchange-price combinations.

	REFERENCING NEW ROW AS new_feed 
	not allowed to do this in for triggers in Mariadb 10.2 instead have to reference new rows as 
	NEW and old rows as OLD in the body of the trigger.
*/

/*
## TODO
	-also we need to output to dollars
	-need to calculate profit from fiat_now and fiat_start
	-address the errors below
		- replace the statement on line 27 with some kind of join
		- see if that addresses downstream problems
*/

/*

ERROR 1452 (23000) at line 124 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 125 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 126 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 127 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 128 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 129 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 130 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 132 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1452 (23000) at line 134 in file: 'populateDB.sql': Cannot add or update a child row: a foreign key constraint fails (`crypto`.`coinexchanges`, CONSTRAINT `coinexchanges_ibfk_2` FOREIGN KEY (`exchange_id`) REFERENCES `exchanges` (`exchange_id`))
ERROR 1054 (42S22) at line 156 in file: 'populateDB.sql': Unknown column 'type' in 'field list'
Query OK, 0 rows affected (0.01 sec)

Query OK, 1 row affected (0.33 sec)

ERROR 1242 (21000) at line 27 in file: 'storedProc.sql': Subquery returns more than 1 row
Query OK, 0 rows affected (0.01 sec)

ERROR 1193 (HY000) at line 66 in file: 'storedProc.sql': Unknown system variable 'coin_id'
ERROR 1305 (42000) at line 89 in file: 'storedProc.sql': PROCEDURE crypto.Table_Buy_First_Coin does not exist

*/