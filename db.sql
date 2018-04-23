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
type VARCHAR(5) NOT NULL,
value FLOAT NOT NULL,
wallet_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
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
