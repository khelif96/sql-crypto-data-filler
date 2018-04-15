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
          'exchangeName' : result[row]['Exchange Name']
        }
        coinExchanges.push(coinExchange);
      }
      getPrices(coinExchanges);

      con.end// const url = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=" + coinList + "&tsyms=USD&e=";
();

    })
  })

}

function getPrices(coinExchanges){
  var ecount = 0;
  for (var coinExchange in coinExchanges) {
    var url = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=" + coinExchanges[coinExchange].symbol + "&tsyms=USD&e="+ coinExchanges[coinExchange].exchangeName;
      axios
        .get(url)
        .then(response => {
          // console.log(JSON.stringify(response.data));
          for (var coin in response.data) {
            // console.log(
            //   `Exchange: ${coinExchanges[coinExchange].exchangeName} ~`,
            //   `Coin: ${coinExchanges[coinExchange].symbol} -`,
            //   `USD: ${response.data[coinExchanges[coinExchange].symbol].USD} -`,
            //   `TIME: ${new Date()}`
            // );
            console.log(coin + " " + JSON.stringify(response.data[coin]))
            // if(response.data[coinExchanges[coinExchange].symbol].USD == undefined){
            //   console.log(response.data)
            //   ecount++;
            // }
            }

        })

        .catch(error => {
          console.log("ERROR " + error);
          ecount++;
          console.log(ecount)
        });

    }
    console.log("ecount " + ecount)
  }
