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

  con.connect(function(err){
    if(err){
      console.log('ERROR Connecting to DB');
      con.end();
      process.exit(1);
    };
    console.log("Connected To Database");
    var sql = "show tables";
    con.query(sql, function(err,result){
      if(err) throw err;
      console.log("Tables in DB");
      for (var table in result) {
        console.log(result[table].Tables_in_cryptotrading)
      }
      con.end();

    })
  })

}
// const coinList = 'BTC'
// const url = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=" + coinList + "&tsyms=USD&e=";
// const exchangeList = ['Bitfinex','Kraken', 'HitBTC', 'coinone','Bithumb']
// for (var i = 0 ; i<exchangeList.length; i++) {
//   axios
//     .get(url + exchangeList[i])
//     .then(response => {
//       console.log(JSON.stringify(response.data));
//       for (var coin in response.data) {
//         console.log(
//           `Exchange: ${exchangeList[i]} ~`,
//           `Coin: ${coin} -`,
//           `USD: ${response.data[coin].USD} -`,
//           `TIME: ${new Date()}`
//         );    }
//
//     })
//
//     .catch(error => {
//       console.log("ERROR " + error);
//     });
//
// }
