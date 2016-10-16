var wretailerApp = angular.module(
    'wretailerApp',
    ['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
     'wgoodApp', 'diabloAuthenApp', 'diabloFilterApp',
     'diabloNormalFilterApp', 'diabloPattern', 'diabloUtils', 'userApp'])
    .config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('wretailerApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
    })
    .run(['$route', '$rootScope', '$location',
	  function ($route, $rootScope, $location) {
	      var original = $location.path;
	      $location.path = function (path, reload) {
		  if (reload === false) {
		      var lastRoute = $route.current;
		      var un = $rootScope.$on(
			  '$locationChangeSuccess',
			  function () {
			      $route.current = lastRoute;
			      un();
			  });
		  }
		  return original.apply($location, [path]);
	      };
	  }])
    .config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

wretailerApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
    	return userService()}};

    var brand = {"filterBrand": function(diabloFilter){
	return diabloFilter.get_brand()}};

    var firm = {"filterFirm": function(diabloFilter){
	return diabloFilter.get_firm()}};

    var type = {"filterType": function(diabloFilter){
	return diabloFilter.get_type()}};
    
    var s_group = {"filterSizeGroup": function(diabloFilter){
	return diabloFilter.get_size_group()}};

    var color = {"filterColor": function(diabloFilter){
	return diabloFilter.get_color()}};
    
    var retailer = {"filterRetailer": function(diabloNormalFilter){
	return diabloNormalFilter.get_wretailer()}};
    
    var employee = {"filterEmployee": function(diabloNormalFilter){
	return diabloNormalFilter.get_employee()}};
    
    var province = {"filterProvince": function(diabloNormalFilter){
	return diabloNormalFilter.get_province()}};

    var city = {"filterCity": function(diabloNormalFilter){
	return diabloNormalFilter.get_city()}};

    var base = {"base": function(diabloNormalFilter){
	return diabloNormalFilter.get_base_setting()}};
    
    $routeProvider. 
	when('/wretailer_new', {
	    templateUrl: '/private/wretailer/html/wretailer_new.html',
	    controller: 'wretailerNewCtrl',
	    resolve: angular.extend({}, province, city, user) 
	}).
	when('/wretailer_detail', {
	    templateUrl: '/private/wretailer/html/wretailer_detail.html',
	    controller: 'wretailerDetailCtrl',
	    resolve: angular.extend({}, province, city, user)
	}).
	when('/wretailer_trans/:retailer?/:page?', {
	    templateUrl: '/private/wretailer/html/wretailer_trans.html',
	    controller: 'wretailerTransCtrl',
	    resolve: angular.extend({}, retailer, employee, user, base)
	}).
	// when('/wretailer_top', {
	//     templateUrl: '/private/wretailer/html/wretailer_top.html',
	//     controller: 'wretailerTopCtrl',
	//     resolve: angular.extend({}, retailer, province, city)
	// }).
	when('/wretailer_trans_rsn/:retailer?/:rsn?/:ppage?', {
	    templateUrl: '/private/wretailer/html/wretailer_trans_rsn_detail.html',
	    controller: 'wretailerTransRsnDetailCtrl',
	    resolve: angular.extend(
		{}, brand, firm, color, retailer, employee, s_group, type, user, base)
	}).
	// bill check
	when('/wretailer/bill', {
	    templateUrl: '/private/wretailer/html/wretailer_bill_check.html',
	    controller: 'wretailerBillCheckCtrl',
	    resolve: angular.extend({}, employee, user) 
	}).
	when('/wretailer/bill_detail', {
	    templateUrl: '/private/wretailer/html/wretailer_bill_detail.html',
	    controller: 'wretailerBillDetailCtrl',
	    resolve: angular.extend({}, retailer) 
	}).
	otherwise({
	    templateUrl: '/private/wretailer/html/wretailer_detail.html',
	    controller: 'wretailerDetailCtrl',
	    resolve: angular.extend({}, province, city, user)
        })
}]);

wretailerApp.service("wretailerService", function($resource, dateFilter){
    // error information
    // this._retailers = undefined;

    // this.set_retailer = function(retailers){
    // 	this._retailers = retailers;
    // };

    // this.get_retailer = function(){
    // 	return this._retailers;
    // };
    
    this.error = {
     	2101: "已存在同样的零售商！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    this.sort_inventory = function(invs, orderSizes, allColors){
	// console.log(invs);
	// console.log(orderSizes);
	var in_sort = function(sorts, inv){
	    for(var i=0, l=sorts.length; i<l; i++){
		if(sorts[i].cid === inv.color_id
		   && sorts[i].size === inv.size){
		    sorts[i].count += parseInt(inv.amount);
		    return true;
		}
	    }
	    return false;
	};

	var total = 0;
	var used_sizes  = [];
	var colors = [];
	var sorts = [];
	angular.forEach(invs, function(inv){
	    if (angular.isDefined(inv.amount)){
		total += inv.amount; 
	    };
	    
	    if (!in_array(used_sizes, inv.size)){
		used_sizes.push(inv.size);
	    };

	    var color_obj = diablo_get_object(inv.color_id, allColors);
	    var color = {cid:inv.color_id,
			 cname: angular.isDefined(color_obj) ? color_obj.name : undefined};
	    
	    if (!in_array(colors, color)){
		colors.push(color)
	    };

	    if (!in_sort(sorts, inv)){
		sorts.push({cid:inv.color_id, size:inv.size, count:inv.amount})
	    }; 
	});

	// format size
	var order_used_sizes = [];
	if (angular.isArray(orderSizes) && orderSizes.length !== 0){
	    order_used_sizes = orderSizes.filter(function(s){
		return in_array(used_sizes, s); 
	    });
	} else{
	    order_used_sizes = used_sizes;
	};
	

	// console.log(order_used_sizes);
	// console.log(colors);
	// console.log(sorts);
	
	return {total: total, size: order_used_sizes, color:colors, sort:sorts};
    };

    
    
    var http = $resource("/wretailer/:operation/:id",
    			 {operation: '@operation', id: '@id'});

    this.new_wretailer = function(r){
	var balance = diablo_set_integer(r.balance);
	var province = angular.isDefined(r.province) && r.province ? r.province.id : undefined;
	var city = angular.isDefined(r.city) && r.city ? r.city : undefined; 
	return http.save(
	    {operation:"new_w_retailer"},
	    {name:     r.name,
	     balance:  balance,
	     mobile:   r.mobile,
	     address:  r.address,
	     province: province,
	     city:     angular.isDefined(city) ? (typeof(city) === 'object' ? city.name : city)
	     : undefined
	    }).$promise;
    };

    this.delete_retailer = function(wretailerId){
	return http.delete({operation: "del_w_retailer", id:wretailerId}).$promise;
    }

    this.update_retailer = function(r){
	return http.save(
	    {operation: "update_w_retailer"},
	    {id:       r.id,
	     name:     r.name,
	     balance:  r.balance,
	     mobile:   r.mobile,
	     address:  r.address,
	     province: angular.isDefined(r.province) && r.province ? r.province.id : undefined,
	     city:     angular.isDefined(r.city) && r.city
	     ? (typeof(r.city) === 'object' ? r.city.name : r.city) : undefined
	    }).$promise;
    };

    this.list_retailer = function(){
	return http.query({operation: "list_w_retailer"}).$promise
    };

    this.bill_w_retailer = function(check){
	return http.save({operation: "bill_w_retailer"}, check).$promise
    };

    var http_wsale = $resource(
	"/wsale/:operation/:id", {operation: '@operation', id: '@id'});
    this.filter_w_sale_new = function(match, fields, currentPage, itemsPerpage){
	return http_wsale.save(
	    {operation: "filter_w_sale_new"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.filter_w_sale_rsn_group = function(match, fields, currentPage, itemsPerpage){
	return http_wsale.save(
	    {operation: "filter_w_sale_rsn_group"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.w_sale_rsn_detail = function(inv){
	return http_wsale.save(
	    {operation: "w_sale_rsn_detail"},
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
    };

    this.check_w_sale_new = function(rsn){
	return http_wsale.save({operation: "check_w_sale"},
			       {rsn: rsn}).$promise;
    };

    this.print_trans = function(condition){
	return http.save(
	    {operation: "print_w_retailer_trans"}, condition).$promise;
    }
});

// wretailerApp.controller("wretailerTopCtrl", function(
//     $scope, wretailerService, filterRetailer, filterProvince, filterCity){
//     $scope.retailers  = filterRetailer;
//     $scope.provinces  = filterProvince;
//     $scope.cities     = filterCity;

//     angular.forEach($scope.retailers, function(r){
// 	r.province = diablo_get_object(r.pid, $scope.provinces);
// 	r.city     = diablo_get_object(r.cid, $scope.cities);
//     });
   
// });

wretailerApp.controller("wretailerCtrl", function($scope, localStorageService){
    diablo_remove_local_storage(localStorageService);
});

wretailerApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
