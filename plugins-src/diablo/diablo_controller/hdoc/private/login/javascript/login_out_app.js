// var loginOutApp = angular.module("loginOutApp", ['ngResource', 'diabloUtils']);

// console.log(loginOutApp);

function diablo_login_out($resource){
    // console.log($scope);

    var http = $resource("/wbase/:operation/:id", {operation: '@operation'}); 
    var destroy_user = function(){
	return http.save({operation: "destroy_login_user"}).$promise;
    };
    
    // console.log("home");
    // delete login session
    destroy_user().then(function(result){
	console.log(result);
	/*
         * clear all local storage
         */
        // login user
        var re_login  = /^login-.*$/;
        var re_filter = /^filter-.*$/;
        for (var key in localStorage){
            console.log(key);
            if (re_login.test(key)) localStorage.removeItem(key);
            if (re_filter.test(key)) localStorage.removeItem(key);
        }
	
	diablo_goto_page("/");
    })

};

// loginOutCtrl.$inject = ['$scope', '$resource'];
// angular.module('loginOutApp', ['ngResource', 'diabloUtils'])
//     .controller('loginOutCtrl', loginOutCtrl);

// loginOutApp.controller("loginOutCtrl", ['$scope', '$resource', function($scope, $resource){
//     var http = $resource("/wbase/:operation/:id", {operation: '@operation'});
    
//     var destroy_user = function(){
// 	return http.save({operation: "destroy_login_user"}).$promise;
//     };
    
//     $scope.home = function(){
// 	// console.log("home");
// 	// delete login session
// 	destroy_user().then(function(result){
// 	    console.log(result);
// 	    diablo_goto_page("/");
// 	})
//     }
// }]);

// angular.element(document).ready(function() {
//     angular.bootstrap(document.getElementById('loginOutApp'), ['loginOutApp']);
// });
