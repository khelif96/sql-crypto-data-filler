const axios = require("axios");
const url = "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=BTC,USD,EUR";
axios
  .get(url)
  .then(response => {
    console.log(
      `BTC: ${response.data.BTC} -`,
      `USD: ${response.data.USD} -`,
      `EUR: ${response.data.EUR}`
    );
  })
  .catch(error => {
    console.log(error);
  });
