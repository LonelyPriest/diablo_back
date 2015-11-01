var purchaserApp = angular.module(
    'purchaserApp',
    ['ui.bootstrap', 'ngRoute', 'ngResource',
     'LocalStorageModule', 'fsm',
     'diabloPattern', 'diabloNormalFilterApp', 'diabloUtils',
     'userApp', 'employApp', 'wgoodApp'])
    .config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('purchaserApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
    })
// .config(diablo_authen)
    .config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
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
	  }]);

purchaserApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
	return userService()}}; 

    var brand = {"filterBrand": function(diabloFilter){
	return diabloFilter.get_brand()}};
    
    var firm = {"filterFirm": function(diabloFilter){
	return diabloFilter.get_firm()}}; 
    
    var type = {"filterType": function(diabloFilter){
	return diabloFilter.get_type()}};

    var employee = {"filterEmployee": function(diabloFilter){
	return diabloFilter.get_employee()}};

    var color = {"filterColor": function(diabloFilter){
	return diabloFilter.get_color()}};
    
    var s_group = {"filterSizeGroup": function(diabloFilter){
	return diabloFilter.get_size_group()}};

    var base = {"base": function(diabloNormalFilter){
	return diabloNormalFilter.get_base_setting()}};
    
    $routeProvider. 
	when('/inventory_new', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_new.html',
            controller: 'purchaserInventoryNewCtrl',
	    resolve: angular.extend({}, user, firm, employee, color, base)
	}).
	when('/update_new_detail/:rsn?/:ppage?', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_new_detail_update.html',
            controller: 'purchaserInventoryNewUpdateCtrl',
	    resolve: angular.extend({}, user, brand, firm, type, employee, s_group, color, base)
	}).
	//
	when('/inventory_reject', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_reject.html',
            controller: 'purchaserInventoryRejectCtrl',
	    resolve: angular.extend({}, user, firm, employee, s_group, color, base)
	}). 
	when('/update_new_detail_reject/:rsn?/:ppage?', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_reject_update.html',
            controller: 'purchaserInventoryRejectUpdateCtrl',
	    resolve: angular.extend({}, user, brand, firm, type, employee, s_group, color, base)
	}).
	//
	when('/inventory_rsn_detail/:rsn?/:ppage?', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_new_rsn_detail.html',
	    controller: 'purchaserInventoryNewRsnDetailCtrl',
	    resolve: angular.extend({}, user, brand, firm, type, employee, s_group, color, base)
	}).
	when('/inventory_new_detail/:page?', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_new_detail.html',
            controller: 'purchaserInventoryNewDetailCtrl',
	    resolve: angular.extend({}, user, firm, employee, base)
	}). 
	when('/inventory_detail/:rsn?', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_detail.html',
            controller: 'purchaserInventoryDetailCtrl' ,
	    resolve: angular.extend({}, user, brand, firm, type, s_group, color, base)
	}).
	// 
	when('/inventory/inventory_fix', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_fix.html',
            controller: 'purchaserInventoryFixCtrl' ,
	    resolve: angular.extend({}, user, employee, s_group, color)
	}).
	when('/inventory/inventory_fix_detail', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_fix_detail.html',
            controller: 'purchaserInventoryFixDetailCtrl' ,
	    resolve: angular.extend({}, user, employee, base) 
	}).
	when('/inventory/inventory_rsn_detail/fix/:rsn?', {
	    templateUrl: '/private/purchaser/html/purchaser_inventory_fix_rsn_detail.html',
            controller: 'purchaserInventoryFixRsnDetailCtrl',
	    resolve: angular.extend({}, user, brand, firm, s_group, color, base)
	}). 
	otherwise({
	    templateUrl: '/private/purchaser/html/purchaser_inventory_new_detail.html',
            controller: 'purchaserInventoryNewDetailCtrl' ,
	    resolve: angular.extend({}, user, firm, employee, base)
        })
}]);


purchaserApp.service("purchaserService", function($resource, dateFilter){
    // error information
    this.error = {
	2001: "货品资料已存在！！",
	2094: "修改前后信息一致，请重新编辑修改项！！", 
	2095: "请先选择厂商！！",
	2096: "客户，营业员或店铺为空，请先建立客户，营业员或店铺资料！！",
	2097: "该货品在店铺中不存在，请选择另外的货品或店铺！！",
	2098: "该货品库存为0，无法退货，请选择另外的货品！！",
	2099: "该货号已存在，请选择新的货号！！",
	2701: "文件导出失败，请重试或联系服务人员查找原因！！",
	2702: "文件导出失败，没有任何数据需要导出，请重新设置查询条件！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    this.purchaser_type =  [{name:"采购开单", id:0, py:diablo_pinyin("采购开单")},
    			  {name:"采购退货", id:1, py:diablo_pinyin("采购退货")}];

    this.extra_pay_types = [
	{id:0, name: "代付运费"},
	{id:1, name: "样衣"},
	{id:2, name: "少配饰"},
    ];

    this.export_type = {trans:0, trans_note:1, stock:2};

    this.get_inventory_from_sort = function(cid, size, sorts){
	for(var i=0, l=sorts.length; i<l; i++){
	    if (sorts[i].cid === cid && sorts[i].size === size){
		return sorts[i];
	    }
	}
	return undefined;
    };
    
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

	    // console.log(inv.color_id);
	    // console.log(allColors);
	    // console.log(colors);
	    
	    var color = diablo_find_color(inv.color_id, allColors); 
	    
	    if (!diablo_in_colors(color, colors)){
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

    this.promise = function(callback, params){
	return function(){
	    var deferred = $q.defer();
	    callback(params).$promise.then(function(data){
		// console.log(data);
		deferred.resolve(data);
	    });
	    return deferred.promise;
	}
    };
    
    // =========================================================================
    var http = $resource("/purchaser/:operation/:id",
    			 {operation: '@operation', id: '@id'},
			 {
			     get_inventory_group: {method: 'POST', isArray: true},
			     get_inventory: {method: 'POST', isArray: true}
			 }); 
    
    /*
     * new
     */
    this.add_purchaser_inventory = function(inventory, base){
	return http.save({operation: "new_w_inventory"}, inventory).$promise;
    };

    this.update_w_inventory_new = function(inventory, base){
	return http.save({operation: "update_w_inventory"}, inventory).$promise;
    };

    this.check_w_inventory_new = function(rsn){
	return http.save({operation: "check_w_inventory"},
			 {rsn: rsn}).$promise;
    };
    
    this.filter_purchaser_inventory_group = function(
	mode, match, fields, currentPage, itemsPerpage
    ){
	return http.save(
	    {operation: "filter_w_inventory_group"},
	    {
		mode:   mode,
		match:  angular.isDefined(match) ? match.op : undefined,
		fields: fields,
		page:   currentPage,
		count:  itemsPerpage}).$promise;
    };

    this.list_purchaser_inventory = function(condition){
    	return http.get_inventory(
    	    {operation: "list_w_inventory"}, condition).$promise;
    };

    this.get_w_invnetory_new = function(RSN){
    	return http.get({operation: "get_w_inventory_new", id: RSN}).$promise;
    };

    this.get_w_invnetory_new_amount = function(condition){
    	return http.save({operation: "get_w_inventory_new_amount"}, condition).$promise;
    };

    this.filter_w_inventory_new = function(match, fields, currentPage, itemsPerpage){
	return http.save(
	    {operation: "filter_w_inventory_new"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.filter_w_inventory_new_rsn_group = function(match, fields, currentPage, itemsPerpage){
	return http.save(
	    {operation: "filter_w_inventory_new_rsn_group"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.w_inventory_new_rsn_detail = function(inv){
	return http.save(
	    {operation: "w_inventory_new_rsn_detail"},
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
    }

    /*
     * reject
     */
    this.reject_purchaser_inventory = function(inventory){
	return http.save({operation: "reject_w_inventory"}, inventory).$promise;
    }
    
    this.filter_w_inventory_reject = function(match, fields, currentPage, itemsPerpage){
	return http.save(
	    {operation: "filter_w_inventory_reject"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.filter_w_inventory_reject_rsn_group = function(match, fields, currentPage, itemsPerpage){
	return http.save(
	    {operation: "filter_w_inventory_reject_rsn_group"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.w_invnetory_reject_rsn_detail = function(inv){
	return http.save(
	    {operation: "w_inventory_reject_rsn_detail"},
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
    }

    /*
     * fix
     */
    this.fix_purchaser_inventory = function(inventory){
	return http.save({operation: "fix_w_inventory"}, inventory).$promise;
    }

    this.filter_fix_w_inventory = function(match, fields, currentPage, itemsPerpage){
	return http.save(
	    {operation: "filter_fix_w_inventory"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.filter_w_inventory_fix_rsn_group = function(match, fields, currentPage, itemsPerpage){
	return http.save(
	    {operation: "filter_w_inventory_fix_rsn_group"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.w_invnetory_fix_rsn_detail = function(inv){
	return http.save(
	    {operation: "w_inventory_fix_rsn_detail"},
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
    };

    this.csv_export = function(e_type, condition){
	return http.save({operation: "w_inventory_export"},
			 {condition: condition, e_type:e_type}).$promise;
    };
    
});

// purchaserApp.controller(
//     "purchaserOrderNewCtrl",
//     function($scope){
// 	console.log("purchaserNewCtrl");
//     }
// );


// purchaserApp.controller(
//     "purchaserOrderDetailCtrl",
//     function($scope){
// 	console.log("purchaserDetailCtrl");
//     }
// );

purchaserApp.controller("purchaserCtrl", function($scope, localStorageService){
    diablo_remove_local_storage(localStorageService);
});

purchaserApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
