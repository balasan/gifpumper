'use strict';
require('./../../../env');

module.exports = {
  env: 'development',
  mongo: {
    uri: process.env.MONGOLAB_URI ||
         process.env.MONGOHQ_URL ||
         'mongodb://localhost/fullstack'
  }
};