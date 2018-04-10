create TABLE coins(
    coin_id int AUTO_INCREMENT PRIMARY KEY, 
    symbol varchar(10), 
    name varchar(255));

create TABLE exchanges(
    id int auto_increment primary key, 
    name varchar(255),
    region varchar(255));

create TABLE coinexchanges(
    id int auto_increment primary key, 
    coin_id int, 
    exchange_id int);

create TABLE wallets(
    walletID varchar(255) primary key, 
    balance_type varchar(225), 
    value int) ENGINE = InnoDB;

create TABLE priceFeed(
    price_feedID int auto_increment primary key,
    price int,
    coins int,
    exchangev int, 
    time_date DATETIME ) ENGINE = InnoDB;

create TABLE transactions(
    transactionID int auto_increment primary key,
    coin_type varchar(255), coin int, 
    transactionPrice int, 
    transactionQty int, 
    transactionTotal int,
    price_feedID int,
    originWallet int, 
    destinationWallet int) ENGINE = InnoDB;

