'use strict';

var mongoose = require('mongoose'),
	Schema = mongoose.Schema,
	crypto = require('crypto');

var authTypes = ['github', 'twitter', 'facebook', 'google'];

/**
 * User Schema
 */
var notifySchema, textSchema;

notifySchema = new Schema({
	user: String,
	page: String,
	action: String,
	version: Number,
	time: {
		type: Date,
		"default": Date.now
	},
	img: String
});



textSchema = new Schema({
	user: String,
	text: String,
	time: {
		type: Date,
		"default": Date.now
	},
	at: [],
	hash: []
});



var UserSchema = new Schema({
	username: {
		type: String,
		index: {
			unique: true
		}
	},
	salt: {
		type: String
	},
	password: String,
	email: String,
	pages: [],
	contributedTo: [],
	favoritePages: [],
	favoriteUsers: [],
	text: [textSchema],
	likes: [],
	userImage: {
		type: String,
		default: ""
	},

	backgroundImage: String,
	background: String,
	bgDisplay: String,
	info: String,
	notify: [notifySchema],
	newNotify: Number,
	nowId: String,
	clicks: {
		type: Number,
		default: 0,
		min: 0,
	},


	role: {
		type: String,
		default: 'user'
	},
	provider: String,

	facebook: {},
	twitter: {},
	github: {},
	google: {}
});

/**
 * Virtuals
 */
UserSchema
	.virtual('pass')
	.set(function(password) {
		this._password = password;
		this.salt = this.makeSalt();
		this.password = this.encryptPassword(password);
	})
	.get(function() {
		return this._password;
	});

// Basic info to identify the current authenticated user in the app
UserSchema
	.virtual('userInfo')
	.get(function() {
		return {
			'name': this.username,
			'role': this.role,
			'provider': this.provider
		};
	});

// Public profile information
UserSchema
	.virtual('profile')
	.get(function() {
		return {
			'name': this.username,
			'role': this.role
		};
	});

/**
 * Validations
 */

// Validate empty email
UserSchema
	.path('email')
	.validate(function(email) {
		// if you are authenticating by any of the oauth strategies, don't validate
		if (authTypes.indexOf(this.provider) !== -1) return true;
		return email.length;
	}, 'Email cannot be blank');

// Validate empty name
UserSchema
	.path('username')
	.validate(function(username) {
		// if you are authenticating by any of the oauth strategies, don't validate
		if (authTypes.indexOf(this.provider) !== -1) return true;
		return username.length;
	}, 'Username cannot be blank');

// Validate empty password
UserSchema
	.path('password')
	.validate(function(password) {
		// if you are authenticating by any of the oauth strategies, don't validate
		if (authTypes.indexOf(this.provider) !== -1) return true;
		return password.length;
	}, 'Password cannot be blank');

// Validate username is not taken
UserSchema
	.path('username')
	.validate(function(value, respond) {
		var self = this;
		this.constructor.findOne({
			username: value
		}, function(err, user) {
			if (err) throw err;
			if (user) {
				if (self.id === user.id) return respond(true);
				return respond(false);
			}
			respond(true);
		});
	}, 'The specified username address is already in use.');

var validatePresenceOf = function(value) {
	return value && value.length;
};

/**
 * Pre-save hook
 */
UserSchema
	.pre('save', function(next) {
		if (!this.isNew) return next();

		if (!validatePresenceOf(this.password) && authTypes.indexOf(this.provider) === -1)
			next(new Error('Invalid password'));
		else
			next();
	});

/**
 * Methods
 */
UserSchema.methods = {
	/**
	 * Authenticate - check if the passwords are the same
	 *
	 * @param {String} plainText
	 * @return {Boolean}
	 * @api public
	 */
	authenticate: function(plainText) {
		return this.encryptPassword(plainText) === this.password;
	},

	/**
	 * Make salt
	 *
	 * @return {String}
	 * @api public
	 */
	makeSalt: function() {
		return crypto.randomBytes(16).toString('base64');
	},

	/**
	 * Encrypt password
	 *
	 * @param {String} password
	 * @return {String}
	 * @api public
	 */
	encryptPassword: function(password) {
		if (!password || !this.salt) return '';
		// var salt = new Buffer(this.salt, 'base64');
		// return crypto.pbkdf2Sync(password, salt, 10000, 64).toString('base64');
		return crypto.createHmac("sha256", this.salt).update(password).digest("hex")
	}
};

module.exports = mongoose.model('userModel', UserSchema);