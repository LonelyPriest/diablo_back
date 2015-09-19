var rightMerchantApp = angular.module(
    "rightMerchantApp", ['ngRoute', 'ngResource', 'diabloUtils', 'diabloAuthenApp',
			 'ui.bootstrap', 'rightApp', 'merchantApp',
			 'employApp'])
// .config(diablo_authen);
.config(function($httpProvider, authenProvider){
    // $httpProvider.responseInterceptors.push(authenProvider.interceptor);
    $httpProvider.interceptors.push(authenProvider.interceptor); 
});

rightMerchantApp.config(['$routeProvider', function($routeProvider){
    //console.log($rootScope);
    $routeProvider. 
	when('/account_merchant/account_new', {
	    templateUrl: '/private/right/html/account_merchant_new.html',
	    controller: 'accountMerchantNewCtrl'
	}).
	when('/account_merchant/account_detail', {
	    templateUrl: '/private/right/html/account_merchant_detail.html',
	    controller: 'accountMerchantDetailCtrl'
	}).
	when('/role_merchant/role_detail', {
	    templateUrl: '/private/right/html/role_merchant_detail.html',
	    controller: 'roleMerchantDetailCtrl'
	}).
	when('/role_merchant/role_new', {
	    templateUrl: '/private/right/html/role_merchant_new.html',
	    controller: 'roleMerchantNewCtrl'
	}).
	otherwise({
	    templateUrl: '/private/right/html/account_merchant_detail.html',
	    controller: 'accountMerchantDetailCtrl' 
	}) 
}]);

// rightMechantApp.controller("roleTreeModalCtrl", function(
//     $scope, $modalInstance, params, rightService){
//     console.log($scope);
//     console.log(params);

//     // console.log($scope.rightTree);
//     $scope.$watch("rightTree", function(newValue, oldValue){
// 	if (angular.isUndefined(newValue)){
// 	    return;
// 	} else{
// 	    if (angular.isDefined(params.tree_callback)){
// 		params.tree_callback($scope.rightTree);
// 	    }
// 	}
//     });

//     $scope.cancel = function(){
// 	$modalInstance.dismiss('cancel');
//     };

//     $scope.ok = function() {
// 	$modalInstance.dismiss('ok');
// 	if (angular.isDefined(params.tree_update)
// 	    && typeof(params.tree_update) === 'function'){
// 	    params.tree_update();
// 	}
//     };
// });

rightMerchantApp.controller("rightMechantCtrl", function($scope, $location){
    // $location.path("/account_merchant/account_detail");
});

rightMerchantApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	console.log('home');
	diablo_login_out($resource)
    };
});
