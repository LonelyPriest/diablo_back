var sysApp = angular.module('sysApp', ['ui.bootstrap', 'diabloUtils']);


var sysCtrl = function($scope, $resource, diabloUtilsService){
    // console.log($scope);
    $scope.home = function(){
	console.log("home");
	diablo_goto_page("/");
    }
    
    var get_cookie = function(key){
	if (document.cookie.length > 0){
	    var start = document.cookie.indexOf(key + "=");
	    if (start !== -1 ){
		start = start + key.length + 1;
		var end = document.cookie.indexOf(";", start);
		if (end === -1){
		    end = document.cookie.length;
		}

		return unescape(document.cookie.substring(start, end));
	    }
	}

	return undefined;
    }

    $scope.login_user = get_cookie("login_user");

    // console.log($scope.login_user);

    if (angular.isUndefined($scope.login_user)){
	var http = $resource("/right/:operation"); 
	http.get({operation:"get_login_user"}).$promise.then(function(state){
		if (state.ecode === 0){
		    $scope.login_user = state.user; 
		}
	});
    } 

    $scope.about = function(){
    	diabloUtilsService.edit_with_modal(
    	    "about.html", undefined, undefined, $scope, undefined);
    }
}

sysCtrl.$inject = ['$scope', '$resource', 'diabloUtilsService'];
sysApp.controller("sysCtrl", sysCtrl);
