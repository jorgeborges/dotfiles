const request = require('request');
const contrib = require('blessed-contrib');

class Todoist {
  constructor(config) {
    this._config = config;

    this._headers = ['Description', 'Labels'];

    this._data = {
      headers: this._headers,
      data: [
        ['Awaiting data...', ''],
      ],
    };

    this._widgetType = contrib.table;

    this._widgetOptions = {
      keys: false,
      interactive: false,
      label: '.today tasks',
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

  _getData() {
    const formData = {
      token: this._config.todoist.api_token,
      sync_token: '*',
      resource_types: '["all"]',
    };

    request
      .post({url: 'https://todoist.com/API/v7/sync', formData }, (err, httpResponse, body) => {
        if (err) {
          this._data = {
            headers: this._headers,
            data: [
              ['ERROR!', ''],
            ],
          };

          return;
        }

        const data = JSON.parse(body);

        let items = [['No more items for today!', '']];

        if (httpResponse.statusCode === 200) {
          const labels = new Map();
          data.labels.forEach(label => labels.set(label.id, label.name));

          items = data.items
            .filter(item =>
              Date.parse(item.due_date_utc) >= (new Date()).setHours(0, 0, 0, 0)
              && Date.parse(item.due_date_utc) < (new Date()).setHours(23, 59, 59))
            .map(item =>
              [
                item.content,
                item.labels.sort().reduce((allLabels, labelId) => `${allLabels} ${labels.get(labelId)}`, ''),
              ]
            );
        }

        this._data = {
          headers: this._headers,
          data: items,
        };
      });
  }
}

module.exports = Todoist;
