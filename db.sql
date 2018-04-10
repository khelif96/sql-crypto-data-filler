CREATE TABLE exchanges (
name VARCHAR(10) NOT NULL,
region VARCHAR(10) NOT NULL,
exchangeID INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);


CREATE TABLE coins (
symbol VARCHAR(5) NOT NULL,
full_name VARCHAR(10) NOT NULL,
coinID INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);


CREATE TABLE price_feed (
coin INT, 
price FLOAT NOT NULL,
date DATETIME NOT NULL,
exchange INT,
price_feedID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,

FOREIGN KEY (coin) REFERENCES coins(coinID),
FOREIGN KEY (exchange) REFERENCES exchanges(exchangeID)
);



CREATE TABLE wallets (
type VARCHAR(5) NOT NULL,
value FLOAT NOT NULL,
walletID INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);


CREATE TABLE transactions (
type ENUM('Buy', 'Sell') NOT NULL,
transactionPrice FLOAT NOT NULL,
transactionQty INT NOT NULL,
transactionTotal INT NOT NULL,
price_feedID INT, 
originWallet INT, 
destinationWallet INT,

FOREIGN KEY (price_feedID) REFERENCES price_feed(price_feedID),
FOREIGN KEY (originWallet) REFERENCES wallets(walletID),
FOREIGN KEY (destinationWallet) REFERENCES wallets(walletID)
);


CREATE TABLE coinexchanges (
id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
coin_id INT,
exchange_id INT,

FOREIGN KEY (coin_id) REFERENCES coins(coinID),
FOREIGN KEY (exchange_id) REFERENCES exchanges(exchangeID)
);
////
