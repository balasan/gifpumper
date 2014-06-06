'use strict';

var mongoose = require('mongoose'),
	Thing = mongoose.model('Thing');

/**
 * Get awesome things
 */
exports.awesomeThings = function(req, res) {
	return Thing.find(function(err, things) {
		if (!err) {
			return res.json(things);
		} else {
			return res.send(err);
		}
	});
};

exports.getClientConfig = function(req, res, next) {
	return res.json(200, {
		awsConfig: {
			bucket: process.env.bucket
		}
	});
};