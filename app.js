try{
  var axios = require("axios");
  var mysql = require("mysql");
  require('dotenv').config(); // Library to allow the importing of  enviromental variables in .env files
}catch(error){
  console.error("ERROR are all the dependencies installed?");
  console.error("Try Running npm start");
  console.log(error);
  process.exit(1);
}

if(process.env.host == undefined || process.env.user == undefined || process.env.password == undefined){
  console.error("Could not find all the required enviromental variables");
  console.error("Did you create the .env file?");
  process.exit(1);
}else{
  var con = mysql.createConnection({
    host: process.env.host,
    user: process.env.user,
    password: process.env.password,
    database: process.env.database
  });
  var coinExchanges = []


  con.connect(function(err){
    if(err){
      console.log('ERROR Connecting to DB');
      console.log(err);
      con.end();
      process.exit(1);
    };
    console.log("Connected To Database");
    var sql = "select * from V_coinexchanges";
    con.query(sql, function(err,result){
      if(err) throw err;
      for (var row in result) {
        var coinExchange = {
          'symbol' : result[row].symbol,
          'exchangeName' : result[row]['Exchange Name'],
          'coin_id' : result[row].coin_id,
          'exchange_id' : result[row].exchange_id
        }
        coinExchanges.push(coinExchange);
      }

      getPrices(coinExchanges);



    })
  })

}
// var dict = []; // create an empty array
//
// dict.push({
//     key:   "coinbase",
//     value: "btc"
// });
// dict.push({
//     key:   "coinbase",
//     value: "eth"
// });
// console.log(JSON.stringify(dict))
function getPrices(coinExchanges){
  var ecount = 0;
  console.log(coinExchanges.length)
  for (let i = 0;i<coinExchanges.length; i++) {
    var url = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=" + coinExchanges[i].symbol + "&tsyms=USD&e="+ coinExchanges[i].exchangeName;
    // console.log(url);
      axios.get(url)
        .then(response => {
          // console.log("Recieved Response");
          // console.log(JSON.stringify(response.data));
          for (var coin in response.data) {
            // console.log("Loop " + i);

            // console.log(
            //   `Exchange: ${coinExchanges[coinExchange].exchangeName} ~`,
            //   `Coin: ${coinExchanges[coinExchange].symbol} -`,
            //   `USD: ${response.data[coinExchanges[coinExchange].symbol].USD} -`,
            //   `TIME: ${new Date()}`
            // );
            // sendPrice
            // console.log(i + " Exchange value")
            // console.log(coinExchanges[i].exchangeName + " " + coin + " " + JSON.stringify(response.data[coin]));
            // console.log();
            // i++;
            // if(response.data[coinExchanges[coinExchange].symbol].USD == undefined){
            //   console.log(response.data)
            //   ecount++;
            // }
            if(coinExchanges[i].coin_id == undefined || response.data[coin].USD  == undefined || coinExchanges[i].exchange_id == undefined){
              console.log("Skipping insert got undefined value");
            }else{
            let sqlInsert = 'insert into price_feed (coin,price,exchange) values (' +  coinExchanges[i].coin_id + ',' + response.data[coin].USD +  ',' + coinExchanges[i].exchange_id + ');';
            con.query(sqlInsert, function(err,result){
              if(err) throw err;
              console.log(sqlInsert);

            })
          }
            }

        })

        .catch(error => {
          console.log("ERROR " + error);
          ecount++;
          console.log(ecount)
        });

      // console.log("Loop " + i);
    }
    console.log("ecount " + ecount)
  }

  function sendPrice(coin){
    var insertSql = "insert into price_feed (coin,exchange,price,date) values ("

  }
