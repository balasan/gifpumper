'use strict';

require('coffee-script/register');


var api = require('./controllers/api'),
	index = require('./controllers'),
	users = require('./controllers/users'),
	session = require('./controllers/session'),
	aws = require('./controllers/aws');

var middleware = require('./middleware');


/**
 * Application routes
 */
module.exports = function(app, now, sessionStore) {

	var db = {};
	var like = require("./controllers/like")(now.everyone, now.nowjs);
	var permissions = require("./controllers/permissions")(now.everyone, now.nowjs),
		pages = require("./controllers/pages")(now.everyone, now.nowjs),
		inits = require("./controllers/inits")(now.everyone, now.nowjs, sessionStore)
		var elements = require("./controllers/elements")(now.everyone, now.nowjs);


	// Server API Routes
	app.get('/api/awesomeThings', api.awesomeThings);

	app.post('/api/users', users.create);
	app.put('/api/users', users.changePassword);
	app.get('/api/users/me', users.me);
	app.get('/api/users/:id', users.show);

	app.post('/api/session', session.login);
	app.del('/api/session', session.logout);

	app.get('/api/config', api.getClientConfig);
	app.get('/api/s3Policy', aws.getS3Policy);


	// All undefined api routes should return a 404
	app.get('/api/*', function(req, res) {
		res.send(404);
	});

	// All other routes to use Angular routing in app/scripts/app.js
	app.get('/partials/:name', index.partials);
	app.get('/partials/elements/:name', index.partialsElements);
	// app.get('/profile/:user', middleware.setUserCookie, index.index);

	app.get('/*', middleware.setUserCookie, index.index);
};