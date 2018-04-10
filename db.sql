create TABLE coins(
    coin_id int AUTO_INCREMENT PRIMARY KEY, 
    symbol varchar(10), 
    name varchar(255));

create TABLE exchanges(
    id int AUTO_INCREMENT PRIMARY KEY, 
    name varchar(255),
    region varchar(255));

create TABLE coinexchanges(
    id int AUTO_INCREMENT PRIMARY KEY, 
    coin_id int, 
    exchange_id int);

create TABLE wallets(
    walletID varchar(255) PRIMARY KEY,  
    balance_type varchar(225), 
    value int) ENGINE = InnoDB;

create TABLE priceFeed(
    price_feedID INT,
    price int,
    coins int,
    exchange int, 
    time_date DATETIME,
    FOREIGN KEY (price_feedID) REFERENCES coins(coin_id),
    FOREIGN KEY (exchange) REFERENCES exchanges(id)
) ENGINE = InnoDB;

create TABLE transactions(
    transactionID int AUTO_INCREMENT PRIMARY KEY,
    coin_type varchar(255), coin int,   
    transactionPrice int, 
    transactionQty int, 
    transactionTotal int,
    price_feedID int,
    originWallet varchar(255), 
    destinationWallet varchar(255),
    FOREIGN KEY (originWallet) REFERENCES wallets(walletID),
    FOREIGN KEY (destinationWallet) REFERENCES wallets(walletID)
) ENGINE = InnoDB;

