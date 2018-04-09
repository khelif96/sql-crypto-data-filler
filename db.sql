create TABLE coins (coin_id int AUTO_INCREMENT PRIMARY KEY, symbol varchar(10), name varchar(255));
create TABLE exchanges (id int auto_increment primary key, name varchar(255),region varchar(255));
create TABLE coinexchanges (id int auto_increment primary key, coin_id int, exchange_id int);
