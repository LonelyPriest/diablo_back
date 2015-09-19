
var diabloAuthenApp = angular.module('diabloAuthenApp', [], function($provide){
    $provide.provider('authen', function(){
	this.interceptor = ['$q', function($q){
	    
	    // function success(response) {
	    // 	return response;
	    // }

	    // function request(config){
	    // 	return config;
	    // }

	    // function requestError(rejection){
	    // 	return $q.reject(rejection);
	    // }

	    // function response (response){
	    // 	return response;
	    // }
	    
	    function responseError(response) {
		// console.log(response);
		// 599 is the customer code of HTTP, means invalid session,
		// so redirect to login
		if(response.status === 401
		   || response.status === 599) {
		    // console.log(response);
		    diablo_goto_page("/");
		    return $q.reject(response);
		}

		// else if (response.status === 599){
		//     var injector = angular.element(document).injector();
		//     var dialog = injector.get('diabloUtilsService');
		//     dialog.response(
		// 	false, "无效会话：", "无效的系统会话，请重新登录！！", undefined);
		//     return $q.reject(response);
		// }
		
		// 598 is the customer code of HTTP, means no right to the operation
		else if (response.status === 598){
		    var injector = angular.element(document).injector();
		    var dialog = injector.get('diabloUtilsService');
		    dialog.response(
			false, "操作鉴权失败：", response.data.action + " 操作鉴权失败！！", undefined);
		    return $q.reject(response);
		}
		else if (response.status === 597){
		    var injector = angular.element(document).injector();
		    var dialog = injector.get('diabloUtilsService');
		    dialog.response(
			false, "用户操作不支持：",
			"普通用户不支持权限分配！！请用管理员用户登陆！！", undefined);
		    return $q.reject(response);
		}
		else if(response.status === 500){
		    var injector = angular.element(document).injector();
		    var dialog = injector.get('diabloUtilsService');
		    dialog.response(
			false, "系统内部错误：", "系统内部错误，请联系维护人员！！", undefined);
		    return $q.reject(response);
		}
		else {
		    return $q.reject(response);
		}
	    }

	    return ({responseError: responseError});

	    // return function(promise) {
	    // 	return promise.then(success, error);
	    // }
	}];
	
	this.$get = function(){
    	    return {};
	}
    });
});
