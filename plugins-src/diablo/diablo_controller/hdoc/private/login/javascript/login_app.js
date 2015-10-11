var loginApp = angular.module("loginApp", ['ngResource'])
// .config(function(localStorageServiceProvider){
// 	localStorageServiceProvider
// 	    .setPrefix('loginApp')
// 	    .setStorageType('localStorage')
// 	    .setNotify(true, true)
// });

loginApp.controller("loginForceCtrl", function($scope){
    $scope.cancel_login = function(){
	window.location.href= "/"
    }
});


loginApp.controller("loginCtrl", function($scope, $location, $resource){

    // var keys = localStorageService.keys();
    // localStorageService.clearAll();
    // console.log(keys);
    // var deferred = $q.defer();
    // var user = $resource("/right/:operation", {operation: '@operation'});

    // deferred.promise.then(function success(state){
    // 	user.query({operation: 'list_login_user_right'}).$promise.then(function(right){
    // 	    if (Number(state.ecode) === 0){
    // 		console.log(right);
    // 	    }
    // 	});
    // }, function error(reason){
	
    // }, function notify(notify){
	
    // }); 
    
    var error = {
	1105: "该用户已登录系统，是否重新登录？",
	1106: "超过在线最大用户数限制，是否强制登录？注意：系统将踢出未在线时间最长用户！！",
	1107: "没有用户可以踢出！！注意：管理员用户无法踢出，请确认管理员是否在线！！",
	1108: "非法用户！！",
	1101: "用户名或密码错误"
    };

    var set_cookie = function(key, value){
	document.cookie = key + "=" + escape(value);
    }
    
    var http = $resource("/login", [], {'login': {method: 'POST'}});
    var redirect = $resource("/login_redirect", [], {'login_redirect': {method: 'POST'}}); 

    // $scope.loginForm = {};
    $scope.show_error = false;
    $scope.hidden_login = false;
    // login
    $scope.login = function(user, password){
	// request
	// var user = {name:user, password: password};
	http.login($scope.user).$promise.then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		// location.href = state.path
		window.location.replace(state.path);
	    } else{
		// show error
		$scope.show_error = true;

		if ( state.ecode === 1105 || state.ecode === 1106){
		    $scope.hidden_login = true; 
		} else{
		    $scope.hidden_login = false; 
		}
		$scope.login_error = error[state.ecode] ? error[state.ecode] : error[1109]; 
	    }
	});
    };

    $scope.cancel_login = function(){
	$scope.user = {};
	$scope.show_error = false;
	$scope.hidden_login = false;
    };

    $scope.sure_login = function(){
	$scope.user.force = true;
	http.login($scope.user).$promise.then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		// redirect 
		// location.href = state.path;
		window.location.replace(state.path);
	    }
	    else{
		// show error
		$scope.show_error = true;
		$scope.hidden_login = true;
		$scope.login_error = error[state.ecode] ? error[state.ecode] : error[1109]; 
	    }
	})
    }
});


    



