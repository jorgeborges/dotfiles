/**
 * An abstract widget, exposes the interface for a widget.
 */
class Widget {
  constructor(config, widgetType, widgetOptions) {
    this._config = config;
    this._widgetType = widgetType;
    this._widgetOptions = widgetOptions;
  }

  get widgetType() {
    return this._widgetType;
  }

  get widgetOptions() {
    return this._widgetOptions;
  }

  /**
   * Triggers an update for the widget displayed data.
   *
   * @returns {*}
   */
  tick() {
    this._getData();

    return this._data;
  }

  _getData() {
    throw new TypeError('Must override method');
  }

  _setData() {
    throw new TypeError('Must override method');
  }
}

module.exports = Widget;
