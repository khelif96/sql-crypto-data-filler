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

var refreshInterval = 1000 // 1000 ms = 1 second  default: 1000*60*5 = 5 minutes

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
    var loopable = true;

      // setInterval(function(){
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
      // },refreshInterval);

  })
}

function getPrices(coinExchanges){
  var ecount = 0;
  console.log("Found " + coinExchanges.length + " coinExchange pairs");
  for (let i = 0;i<coinExchanges.length; i++) {
    var url = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=" + coinExchanges[i].symbol + "&tsyms=USD&e="+ coinExchanges[i].exchangeName;
    // console.log(url);
    axios.get(url)
    .then(response => {
      // console.log("Recieved Response");
      // console.log(JSON.stringify(response.data));
      for (var coin in response.data) {

        if(coinExchanges[i].coin_id == undefined || response.data[coin].USD  == undefined || coinExchanges[i].exchange_id == undefined){
          console.log("Skipping insert got undefined value on coin_id "+ coinExchanges[i].coin_id  + " USD " + response.data[coin].USD + " exchange id " + coinExchanges[i].exchange_id );
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
  console.log("Completed Insertions");
  console.log("ecount " + ecount)
}
