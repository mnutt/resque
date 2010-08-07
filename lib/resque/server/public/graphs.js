if(typeof(Resque) == "undefined") { Resque = {} }

Resque.graphAllQueues = function() {
  var timeUnit = Resque.GraphData.getTimeUnitCookie();

  $.getJSON('/stats/all_queues/' + timeUnit + '.json', function(data) {
    var complete = {};
    for(var queue in data) {
      complete[queue] = data[queue].enqueued;
    }

    Resque.drawGraph(complete);
  });
};

Resque.graphQueue = function(queue) {
  var timeUnit = Resque.GraphData.getTimeUnitCookie();

  $.getJSON('/stats/queue/' + queue + '/' + timeUnit + '.json', function(data) {
    Resque.drawGraph(data);
  });
};

Resque.drawGraph = function(data, timeUnit) {
  var width = 800;
  var numberOfBars = width / 30;

  var graphData = new Resque.GraphData(data, {timeUnit: timeUnit, numberOfBars: numberOfBars});

  var r = Raphael("graph", width, 200);
  var fin = function () {
    this.flag = r.g.popup(this.bar.x, this.bar.y, this.bar.value || "0").insertBefore(this);
  };
  var fout = function () {
    this.flag.animate({opacity: 0}, 300, function () {this.remove();});
  };

  r.g.txtattr = {
    'font': "10px 'Fontin Sans', Fontin-Sans, sans-serif",
    'font-weight': "bold",
    'fill': "#666"
  };

  r.g.colors = graphData.colors;

  var chart = r.g.barchart(0, 10, width, 190, graphData.sets, {stacked: true, stretch: false, gutter: "20%"})
  chart.hover(fin, fout);
  chart.label(graphData.axes, true);

  for(var i = 0; i < graphData.colors.length && i < graphData.setNames.length; i++) {
    var color = graphData.colors[i];
    var setName = graphData.setNames[i];

    var colorBox = $("<div class='color_box' style='background-color: " + color + ";'></div>");
    var set = $("<div class='set'></div>");
    set.append(colorBox);
    set.append(setName);
    $("#legend").append(set);
  }

  var timeUnits = ["day", "hour", "minute"];

  for(var i = 0; i < timeUnits.length; i++) {

    var timeUnit = timeUnits[i];
    if(graphData.timeUnit == timeUnit) {
      $("#time_units").append("<span>" + timeUnit + "</span>");
    } else {
      $("#time_units").append("<a href='#" + timeUnit + "'>" + timeUnit + "</a>");
    }
  }

  $("#time_units a").click(function(e) {
    e.preventDefault();
    document.cookie = "tu=" + $(this).text() + "; path=/";
    window.location.reload();
  });
};

Resque.GraphData = function(data, options) {
    this.data = data;
    this.options = options || {};
    this.timeUnit = this.options.timeUnit || Resque.GraphData.getTimeUnitCookie();

    this.currentTime = this.beginningOfIncrement(new Date());
    this.axes = [];
    this.sets = [];
    this.setNames = [];
    this.colors = ["#D3D8BF", "#CE1212", "#70AFC4", "#777777", "#BBBBBB", "#EEEEEE"];

    var dataTypes = {};

    for(var type in this.data) {
      dataTypes[type] = [];
    }


    for(var i = 0; i < this.options.numberOfBars; i++) {
        var time = new Date(this.currentTime - (this.timeIncrement() * i));
        var label = time.timeLabel(this.timeUnit);

        this.axes.unshift(label);
        for(var type in this.data) {
          dataTypes[type].unshift(this.data[type][time.resqueKey()] || 0);
        }
    }

    for(var dataType in dataTypes) {
      this.sets.push(dataTypes[dataType])
      this.setNames.push(dataType);
    }

    return this;
};

Resque.GraphData.prototype.timeIncrement = function() {
  switch(this.timeUnit) {
    case 'day':
      return 1000*60*60*24;
    case 'hour':
      return 1000*60*60;
    case 'minute':
      return 1000*60;
    default:
      return 1000;
  }
};

Resque.GraphData.prototype.beginningOfIncrement = function(time) {
  switch(this.timeUnit) {
    case 'day':
      return time.beginningOfDay();
    case 'hour':
      return time.beginningOfHour();
    case 'minute':
      return time.beginningOfMinute();
    case 'second':
      return time.beginningOfSecond();
  };
};

Resque.GraphData.getTimeUnitCookie = function() {
  function readCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
      var c = ca[i];
      while (c.charAt(0)==' ') c = c.substring(1,c.length);
      if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
  }

  var timeUnit = readCookie('tu') || '';
  if(!timeUnit.match(/^(day|hour|minute|second)$/)) { timeUnit = 'day'; }

  return timeUnit;
};
