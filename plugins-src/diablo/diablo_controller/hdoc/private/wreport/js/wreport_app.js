var wreportApp = angular.module(
    "wreportApp", ['ngRoute', 'ngResource', 'diabloPattern',
		   'diabloUtils', 'userApp', 'diabloFilterApp',
		   'diabloNormalFilterApp', 'diabloAuthenApp', 'fsm',
		   'ui.bootstrap', 'wgoodApp'])
    .config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor);
    });

wreportApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
    	return userService()}};

    var retailer = {"filterRetailer": function(diabloFilter){
	return diabloFilter.get_wretailer()}};
    
    var employee = {"filterEmployee": function(diabloNormalFilter){
	return diabloNormalFilter.get_employee()}}; 
    
    $routeProvider.
    	when('/wreport_daily', {
    	    templateUrl: '/private/wreport/html/wreport_daily.html',
            controller: 'wreportDailyCtrl',
    	    resolve: angular.extend({}, employee, retailer, user)
    	}). 
    	otherwise({
	    templateUrl: '/private/wreport/html/wreport_daily.html',
            controller: 'wreportDailyCtrl',
    	    resolve: angular.extend({}, employee, retailer, user) 
        })
}]);

wreportApp.service("wreportService", function($resource, dateFilter){
    this.error = {};

    var http = $resource("/wreport/:operation/:type",
    			 {operation: '@operation', type: '@type'});
    
    /*
     * restful
     */
    this.daily_report = function(type, condition, itemsPerpage, currentPage){
	console.log(itemsPerpage, currentPage);
	return http.save({operation: "daily_wreport", type: type},
			 {condition: condition,
			  page:      currentPage,
			  count:     itemsPerpage}).$promise;
    };
    
});

wreportApp.controller("wreportCtrl", function($scope){
});

wreportApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
