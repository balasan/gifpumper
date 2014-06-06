'use strict'

angular.module('gifpumper')
  .controller 'SignupCtrl', ($scope, Auth, $location,nowService,$rootScope) ->
    $scope.user = {}
    $scope.errors = {}
    
    $scope.register = (form) ->
      $scope.submitted = true

      if form.$valid
        Auth.createUser(
          username: $scope.user.name
          email: $scope.user.email
          pass: $scope.user.password
        ).then( ->
          # Account created, redirect to home
          $location.path '/profile/'+$rootScope.currentUser.name
        ).catch( (err) ->
          err = err.data
          $scope.errors = {}
          
          # Update validity of form fields that match the mongoose errors
          angular.forEach err.errors, (error, field) ->
            form[field].$setValidity 'mongoose', false
            $scope.errors[field] = error.type
        )