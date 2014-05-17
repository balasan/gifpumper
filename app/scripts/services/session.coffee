'use strict'

angular.module('gifpumper')
  .factory 'Session', ($resource) ->
    $resource '/api/session/'
