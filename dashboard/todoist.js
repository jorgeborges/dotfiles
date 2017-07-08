const request = require('request');
const contrib = require('blessed-contrib');
const NodeCache = require('node-cache');

class Todoist {
  constructor(config) {
    this._config = config;

    this._cacheKey = 'todoist';
    this._cache = new NodeCache({ stdTTL: this._config.todoist.cache_in_seconds, checkperiod: 120 });

    this._headers = ['Description', 'Labels'];
    this._setData([['Awaiting data...', '']]);

    this._widgetType = contrib.table;
    this._widgetOptions = {
      keys: false,
      interactive: false,
      label: '.tasks for today',
      width: '40%',
      height: '40%',
      border: { type: 'line', fg: 'cyan' },
      columnSpacing: 6, // in chars
      columnWidth: [40, 17], // in chars
    };
  }

  get widgetType() {
    return this._widgetType;
  }

  get widgetOptions() {
    return this._widgetOptions;
  }

  tick() {
    this._getData();

    return this._data;
  }

  /**
   * Gets the Todoist data from either cache or the API.
   *
   * @private
   */
  _getData() {
    const todoistData = this._cache.get(this._cacheKey);

    if (todoistData === undefined) {
      const formData = {
        token: this._config.todoist.api_token,
        sync_token: '*',
        resource_types: '["items", "labels"]',
      };

      request
        .post({url: 'https://todoist.com/API/v7/sync', formData }, (err, httpResponse, body) => {
          if (err) {
            this._setData([['ERROR!', '']]);

            return;
          }

          if (httpResponse.statusCode === 200) {
            this._cache.set(this._cacheKey, JSON.parse(body));
          }
        });
    } else {
      const items = this._parseTodoistData(todoistData);
      this._setData(items);
    }
  }

  /**
   * Arranges the Todoist data in items to be displayed.
   *
   * @param data
   * @returns {Array|*}
   * @private
   */
  _parseTodoistData(data) {
    const labels = new Map();
    data.labels.forEach(label => labels.set(label.id, label.name));

    let items = data.items
      .filter(item => Todoist._isToday(item.due_date_utc))
      .map(item =>
        [
          `◘ ${item.content}`,
          item.labels.sort().reduce((allLabels, labelId) => `${allLabels} ${labels.get(labelId)}`, ''),
        ]
      );

    if (items.length === 0) {
      items = [['No more items for today!', '']];
    }

    return items;
  }

  /**
   * Indicates if the due date is today.
   *
   * @param dueDateUtc
   * @returns {boolean}
   * @private
   */
  static _isToday(dueDateUtc) {
    return Date.parse(dueDateUtc) >= (new Date()).setHours(0, 0, 0, 0)
      && Date.parse(dueDateUtc) < (new Date()).setHours(23, 59, 59, 999);
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
}

module.exports = Todoist;
