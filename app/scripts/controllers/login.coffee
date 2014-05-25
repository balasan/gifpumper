'use strict'

angular.module('gifpumper')
  .controller 'LoginCtrl', ($scope, Auth, $rootScope) ->
    $scope.user = {}
    $scope.errors = {}

    $scope.login = (form) ->
      $scope.submitted = true
      
      if form.$valid
        Auth.login(
          email: $scope.user.email
          password: $scope.user.password
        )
        .then ->
          $rootScope.loggedIn = true

        .catch (err) ->
          err = err.data;
          $scope.errors.other = err.message;
