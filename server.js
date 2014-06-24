'use strict';

var express = require('express'),
	path = require('path'),
	fs = require('fs'),
	mongoose = require('mongoose');


require('coffee-script/register');

/**
 * Main application file
 */

// Set default node environment to development
process.env.NODE_ENV = process.env.NODE_ENV || 'development';

// Application Config
var config = require('./lib/config/config');

// Connect to database
var db = mongoose.connect(config.mongo.uri, config.mongo.options);

// Bootstrap models
var modelsPath = path.join(__dirname, 'lib/models');
fs.readdirSync(modelsPath).forEach(function(file) {
	if (/(.*)\.(js$|coffee$)/.test(file)) {
		require(modelsPath + '/' + file);
	}
});

// Populate empty DB with sample data
// require('./lib/config/dummydata');

// Passport Configuration
var passport = require('./lib/config/passport');

var app = express();

// Express settings
var mongoStore = require('connect-mongo')(express);

var sessionStore = new mongoStore({
	url: config.mongo.uri,
	collection: 'sessions'
}, function() {
	console.log("db connection open");
})

require('./lib/config/express')(app, sessionStore);


// Start server

var http = require('http'),
	server = http.createServer(app)


	server.listen(config.port, function() {
		console.log('Express server listening on port %d in %s mode', config.port, app.get('env'));
	});

var now = require('./lib/config/now')(server)
// Routing
require('./lib/routes')(app, now, sessionStore);


// Expose app
exports = module.exports = app;