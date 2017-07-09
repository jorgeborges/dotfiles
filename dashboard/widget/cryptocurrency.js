const path = require('path');
const Widget = require(path.resolve(__dirname, 'widget.js'));
const contrib = require('blessed-contrib');
const autobahn = require('autobahn');

/**
 * Cryptocurrency widget, get all the latest price updates from Poloniex, a crypto currency exchange.
 */
class Cryptocurrency extends Widget {
  constructor(config) {
    super(config, contrib.table, {
      keys: false,
      interactive: false,
      fg: 'gray90',
      label: '.crypto-currencies',
      width: '40%',
      height: '40%',
      border: { type: 'line', fg: 'cyan' },
      columnSpacing: 6, // in chars
      columnWidth: [5, 15, 6], // in chars
    });

    this._coinDiminutives = config.cryptocurrency.coins;

    this._coinsData = new Map();
    this._coinDiminutives.forEach(coin => this._coinsData.set(coin, { price: '', change: ''}));

    this._subscribeToLiveCoinUpdates();

    this._headers = ['Coin', 'Price (USD)', 'Change'];
    this._setData([['Preparing some mojitos...', '', '']]);
  }

  /**
   * Gets the latest data for all configured coins from the Map that updates constantly.
   *
   * @private
   */
  _getData() {
    const market = this._coinDiminutives.map(
      coin => [coin, this._coinsData.get(coin).price, this._coinsData.get(coin).change]
    );

    this._setData(market);
  }

  /**
   * Updates the data to be displayed by the widget.
   *
   * @param items
   * @private
   */
  _setData(items) {
    this._data = {
      headers: this._headers,
      data: items,
    };
  }

  /**
   * Executed when a new push is received with coin data.
   *
   * Change % formula: (((lastPrice / ((24hrHigh + 24hrLow) / 2) ) * 100) - 100)
   *
   * @param args
   * @private
   */
  _tickerExchange(args) {
    if (args[0].startsWith('USDT_')) {
      const coin = args[0].replace('USDT_', '');

      const change =
        (((parseFloat(args[1]) / ((parseFloat(args[8]) + parseFloat(args[9])) / 2)) * 100) - 100).toFixed(2).toString();

      let colorSuffix = '\x1B[0;1;5;32m+';
      if (change.startsWith('-')) {
        colorSuffix = '\x1B[0;1;5;31m';
      }

      this._coinsData.set(coin, { price: args[1].toString(), change: colorSuffix + change });
    }
  }

  /**
   * Setups the whole real time updates connection by subscribing to the service and awaiting push notifications.
   *
   * @private
   */
  _subscribeToLiveCoinUpdates() {
    const wsuri = 'wss://api.poloniex.com';
    this._connection = new autobahn.Connection({
      url: wsuri,
      realm: 'realm1',
    });

    this._connection.onopen = session => session.subscribe('ticker', this._tickerExchange.bind(this));

    this._connection.onclose = () => {
      console.log('Websocket connection closed');
    };

    this._connection.open();
  }
}

module.exports = Cryptocurrency;
