Date.prototype.beginningOfDay = function() {
    var newDate = (new Date(this));
    newDate.setMilliseconds(0);
    newDate.setSeconds(0);
    newDate.setMinutes(0);
    newDate.setHours(0);

    return newDate;
};

Date.prototype.beginningOfHour = function() {
    var newDate = (new Date(this));
    newDate.setMilliseconds(0);
    newDate.setSeconds(0);
    newDate.setMinutes(0);

    return newDate;
};

Date.prototype.beginningOfMinute = function() {
    var newDate = (new Date(this));
    newDate.setMilliseconds(0);
    newDate.setSeconds(0);

    return newDate;
};


Date.prototype.beginningOfSecond = function() {
  var newDate = (new Date(this));
  newDate.setMilliseconds(0);

  return newDate;
};

Date.prototype.timeLabel = function(timeUnit) {
  switch(timeUnit) {
    case 'day':
      if(this.getDate() == 1) {
        return (this.getMonth() + 1) + "/" + this.getDate();
      } else {
        return "" + this.getDate();
      }
    case 'hour':
      var hour = this.getHours();
      if(hour == 0) { return "12am" }
      if(hour < 12) { return hour + "" }
      if(hour > 12) { return hour % 12 + "" }
      if(hour == 12) { return "12pm" }
    case 'minute':
      if(this.getMinutes() == 0) {
        var hour = this.getHours();
        if(hour == 0) { return "12am" }
        if(hour < 12) { return hour + "am" }
        if(hour > 12) { return hour % 12 + "pm" }
        if(hour == 12) { return "12pm" }
      } else {
        return this.getMinutes();
      }
    case 'second':
      if(this.getSeconds() == 0) {
        return this.getMinutes() + ':' + this.getSeconds();
      } else {
        return this.getSeconds();
      }
  }
};

Date.prototype.resqueKey = function() {
  function pad(number) {
    if(number < 10) { return "0" + number; } else { return number; }
  }

    return this.getFullYear() + "-" + pad(this.getMonth() + 1) + "-" +
        pad(this.getDate()) + "_" + pad(this.getHours()) + ":" +
        pad(this.getMinutes()) + ":" + pad(this.getSeconds());
};
