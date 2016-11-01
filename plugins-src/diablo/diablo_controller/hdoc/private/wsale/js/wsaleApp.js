"use strict";

define(["angular", "angular-router", "angular-resource", "angular-local-storage",
	"angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
	"diablo-authen-right", "diablo-utils", "diablo-filter", "diablo-good",
	"diablo-employee", "diablo-stock", "diablo-retailer"], wsaleConfg);

function wsaleConfg (angular) {
    var wsaleApp = angular.module(
        'wsaleApp',
        ['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'wgoodApp',
	 'userApp', 'purchaserApp', 'wretailerApp'
	])
    	.config(function(localStorageServiceProvider){
    	    localStorageServiceProvider
    		.setPrefix('wsaleApp')
    		.setStorageType('localStorage')
    		.setNotify(true, true)
    	}) 
    	.config(function($httpProvider, authenProvider){
    	    // console.log(authenProvider);
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

    wsaleApp.config(['$routeProvider', function($routeProvider){
    	// $locationProvider.html5Mode(true);
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

    	var retailer = {"filterRetailer": function(diabloFilter){
    	    return diabloFilter.get_wretailer()}};

    	var color = {"filterColor": function(diabloFilter){
    	    return diabloFilter.get_color()}};

    	var color_type = {"filterColorType": function(diabloFilter){
    	    return diabloFilter.get_color_type()}};
	
    	var s_group = {"filterSizeGroup": function(diabloFilter){
    	    return diabloFilter.get_size_group()}};

    	var base = {"base": function(diabloNormalFilter){
    	    return diabloNormalFilter.get_base_setting()}};
	
    	$routeProvider. 
    	    when('/new_wsale', {
    		templateUrl: '/private/wsale/html/new_wsale.html',
    		controller: 'wsaleNewCtrl',
    		resolve: angular.extend(
    	    	    {}, user, firm, retailer, employee, s_group, brand, type, color, color_type, base)
    	    }).
    	    when('/new_ssale', {
    		templateUrl: '/private/wsale/html/new_ssale.html',
    		controller: 'ssaleNewCtrl',
    		resolve: angular.extend(
    	    	    {}, user, firm, retailer, employee, s_group, brand, type, color, base)
    	    }).
    	    when('/new_wsale_detail/:page?', {
    		templateUrl: '/private/wsale/html/new_wsale_detail.html',
    		controller: 'wsaleNewDetailCtrl',
    		resolve: angular.extend({}, user, retailer, employee, base) 
    	    }).
    	    when('/update_wsale_detail/:rsn?/:ppage?', {
    		templateUrl: '/private/wsale/html/update_wsale_detail.html',
    		controller: 'wsaleUpdateDetailCtrl',
    		resolve: angular.extend({}, user, retailer, employee, s_group, brand, color, type, base)
    	    }). 
    	    when('/wsale_rsn_detail/:rsn?/:ppage?', {
    		templateUrl: '/private/wsale/html/wsale_rsn_detail.html',
    		controller: 'wsaleRsnDetailCtrl',
    		resolve: angular.extend(
    		    {}, user, brand, retailer, employee, firm, s_group, type, color, base)
    	    }).
    	    when('/reject_wsale', {
    		templateUrl: '/private/wsale/html/reject_wsale.html',
    		controller: 'wsaleRejectCtrl',
    		resolve: angular.extend({}, user, retailer, employee, s_group, color, base) 
    	    }).
    	    when('/update_wsale_reject/:rsn?/:ppage?', {
    		templateUrl: '/private/wsale/html/update_wsale_reject.html',
    		controller: 'wsaleRejectUpdateCtrl',
    		resolve: angular.extend({}, user, retailer, employee, s_group, brand, color, type, base)
    	    }). 
    	    when('/wsale_print_preview/:rsn?', {
    		templateUrl: '/private/wsale/html/wsale_print_preview.html',
    		controller: 'wsalePrintPreviewCtrl',
    		resolve: angular.extend({}, retailer, s_group, base) 
    	    }).
    	    // when('/wsale/reject_wsale_detail', {
    	    //     templateUrl: '/private/wsale/html/reject_wsale_detail.html',
    	    //     controller: 'wsaleRejectDetailCtrl',
    	    //     resolve: angular.extend({}, user, retailer, employee) 
    	    // }).
    	    // otherwise({
    	    //     templateUrl: '/private/wsale/html/wsale_guide.html',
    	    //     controller: 'wsaleGuideCtrl'
	    // }) 
    	    otherwise({
    		templateUrl: '/private/wsale/html/new_wsale_detail.html',
    		controller: 'wsaleNewDetailCtrl',
    		resolve: angular.extend({}, user, retailer, employee, base)
	    })
    }]);

    wsaleApp.service("wsaleService", function($http, $resource, dateFilter){
    	this.error = {
    	    2190: "该款号库存不存在！！请确认本店是否进货该款号！！",
    	    2191: "该货号已存在，请选择新的货号！！",
    	    2192: "客户或营业员不存在，请建立客户或营业员资料！！",
    	    2193: "款号未知，请检查后重新保存！！",
    	    2401: "店铺打印机不存在或打印处理暂停状态！！",
	    
    	    2411: "打印机编号错误！！",
    	    2412: "服务器处理订单失败！！", 
    	    2413: "打印内容太长！！",
    	    2414: "打印请求参数错误！！",
    	    2415: "打印请求超时，请稍后再试或联系服务人员！！",
    	    2416: "未知原因，请系统服务人员！！",
	    
    	    2417: "发送打印请求失败，请确保网络通畅！！",
	    
    	    2418: "打印机打印失败，请联系服务人员查找原因！！",
    	    2419: "打印机未连接！！",
    	    2420: "打印机缺纸！！",
    	    2421: "打印状态未知，请联系服务人员！！",
    	    2422: "打印机连接设备不存在，请检查设备编号是否正确！！",
    	    2423: "打印格式缺少尺码，请在打印格式设置中选中尺码！！",
    	    2601: "获取零售商历史记录失败！！",
    	    2701: "文件导出失败，请重试或联系服务人员查找原因！！",
    	    2702: "文件导出失败，没有任何数据需要导出，请重新设置查询条件！！",
    	    2703: "明细未知，请删除后重新添加！！",
    	    2704: "应付款项与开单项计算有不符！！", 
    	    2699: "修改前后信息一致，请重新编辑修改项！！",
    	    2799: "该款号为补单，无法退货，请重新选择款号！！",
    	    9001: "数据库操作失败，请联系服务人员！！",
    	    2424: "销售总数与销售明细数不符，请检查该单据后再打印！！",
    	    2425: "销售总数应付款项与实际明细应付款项不符，请检查该单据后再打印！！"};

    	this.rsn_title = ["开单明细", "退货明细", "销售明细"];

    	this.direct = {wsale: 0, wreject: 1};

    	this.wsale_mode = [
    	    {title: "普通模式"},
    	    {title: "图片模式"},
    	    {title: "新增货品"}
    	];

    	this.extra_pay_types = [
    	    {id:0, name: "代付运费"}, 
    	    {id:1, name: "样衣"},
    	    {id:2, name: "少配饰"},
    	    {id:3, name: "代付现金"},
    	    {id:4, name: "初期欠款"}
	    
    	];

    	this.export_type = {trans:0, trans_note:1};
	
    	// =========================================================================
    	var http = $resource("/wsale/:operation/:id",
    			     {operation: '@operation', id: '@id'},
    			     {
    				 query_by_post: {method: 'POST', isArray: true}
    			     });

    	this.new_w_sale = function(inventory){
    	    return http.save({operation: "new_w_sale"}, inventory).$promise;
    	};

    	this.update_w_sale_new = function(inventory){
    	    return http.save({operation: "update_w_sale"}, inventory).$promise;
    	};

    	this.check_w_sale_new = function(rsn){
    	    return http.save({operation: "check_w_sale"},
    			     {rsn: rsn}).$promise;
    	};

    	this.new_w_sale_draft = function(inventory){
    	    return http.save({operation: "new_w_sale_draft"}, inventory).$promise;
    	};

    	this.print_w_sale = function(rsn){
    	    return http.save({operation: "print_w_sale"}, {rsn:rsn}).$promise;
    	};
	

    	this.filter_w_sale_image = function(match, fields, currentPage, itemsPerpage){
    	    return http.save({operation: "filter_w_sale_image"},
    			     {match:  angular.isDefined(match) ? match.op : undefined,
    			      fields: fields,
    			      page:   currentPage,
    			      count:  itemsPerpage}).$promise;
    	};
	
    	// this.list_w_sale_new = function(condition){
    	// 	return http.query_by_post({operation: "list_w_sale_new"}, condition).$promise;
    	// }

    	this.filter_w_sale_new = function(match, fields, currentPage, itemsPerpage){
    	    return http.save({operation: "filter_w_sale_new"},
    			     {match:  angular.isDefined(match) ? match.op : undefined,
    			      fields: fields,
    			      page:   currentPage,
    			      count:  itemsPerpage}).$promise;
    	};

    	this.filter_w_sale_rsn_group = function(match, fields, currentPage, itemsPerpage){
    	    return http.save({operation: "filter_w_sale_rsn_group"},
    			     {match:  angular.isDefined(match) ? match.op : undefined,
    			      fields: fields,
    			      page:   currentPage,
    			      count:  itemsPerpage}).$promise;
    	};

    	this.get_w_sale_new = function(rsn){
    	    return http.get({operation: "get_w_sale_new", id:rsn}).$promise;
    	};

    	this.get_w_print_content = function(rsn){
    	    return http.get({operation: "get_w_print_content", id:rsn}).$promise;
    	};

    	this.list_w_sale_draft = function(shop){
    	    return http.query_by_post({operation: "list_w_sale_draft"}, shop).$promise;
    	};

    	this.get_w_sale_draft = function(draft_sn){
    	    return http.save({operation: "get_w_sale_draft"}, draft_sn).$promise;
    	}; 

    	this.reject_w_sale = function(inventory){
    	    return http.save({operation: "reject_w_sale"}, inventory).$promise;
    	};

    	this.filter_w_sale_reject = function(match, fields, currentPage, itemsPerpage){
    	    return http.save({operation: "filter_w_sale_reject"},
    			     {match:  angular.isDefined(match) ? match.op : undefined,
    			      fields: fields,
    			      page:   currentPage,
    			      count:  itemsPerpage}).$promise;
    	};

    	this.get_last_sale = function(inv){
    	    return http.query_by_post({operation: "get_last_sale"},
    				      {style_number: inv.style_number,
    				       brand:        inv.brand,
    				       shop:         inv.shop,
    				       retailer:     inv.retailer,
    				       r_pgood:      inv.r_pgood
    				      }).$promise;
    	};

    	this.w_sale_rsn_detail = function(inv){
    	    return http.save(
    		{operation: "w_sale_rsn_detail"},
    		{rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
    	};

    	this.csv_export = function(e_type, condition){
    	    return http.save({operation: "w_sale_export"},
    			     {condition: condition, e_type:e_type}).$promise;
    	};
	
    });

    wsaleApp.controller("wsaleCtrl", function(localStorageService){
	diablo_remove_local_storage(localStorageService);
    });
    
    wsaleApp.controller("wsaleNewDetailCtrl", wsaleNewDetailProvide);

    wsaleApp.controller("loginOutCtrl", function($scope, $resource){
    	$scope.home = function () {diablo_login_out($resource)};
    }); 
    
    return wsaleApp;
};

// var wsaleApp = angular.module(
//     'wsaleApp',
//     ['ui.bootstrap', 'ngRoute', 'ngResource',
//      'diabloAuthenApp', 'diabloPattern', 'diabloUtils',
//      'userApp', 'employApp', 'wretailerApp', 'purchaserApp'])
//     .config(function(localStorageServiceProvider){
// 	localStorageServiceProvider
// 	    .setPrefix('wsaleApp')
// 	    .setStorageType('localStorage')
// 	    .setNotify(true, true)
//     }) 
//     .config(function($httpProvider, authenProvider){
// 	// console.log(authenProvider);
// 	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
// 	$httpProvider.interceptors.push(authenProvider.interceptor); 
//     })
//     .run(['$route', '$rootScope', '$location',
// 	  function ($route, $rootScope, $location) {
// 	      var original = $location.path;
// 	      $location.path = function (path, reload) {
// 		  if (reload === false) {
// 		      var lastRoute = $route.current;
// 		      var un = $rootScope.$on(
// 			  '$locationChangeSuccess',
// 			  function () {
// 			      $route.current = lastRoute;
// 			      un();
// 			  });
// 		  }
// 		  return original.apply($location, [path]);
// 	      };
// 	  }]);

// wsaleApp.config(['$routeProvider', function($routeProvider){
//     // $locationProvider.html5Mode(true);
//     var user = {"user": function(userService){
// 	return userService()}}; 

//     var brand = {"filterBrand": function(diabloFilter){
// 	return diabloFilter.get_brand()}};
    
//     var firm = {"filterFirm": function(diabloFilter){
// 	return diabloFilter.get_firm()}}; 
    
//     var type = {"filterType": function(diabloFilter){
// 	return diabloFilter.get_type()}};

//     var employee = {"filterEmployee": function(diabloFilter){
// 	return diabloFilter.get_employee()}};

//     var retailer = {"filterRetailer": function(diabloFilter){
// 	return diabloFilter.get_wretailer()}};

//     var color = {"filterColor": function(diabloFilter){
// 	return diabloFilter.get_color()}};

//     var color_type = {"filterColorType": function(diabloFilter){
// 	return diabloFilter.get_color_type()}};
    
//     var s_group = {"filterSizeGroup": function(diabloFilter){
// 	return diabloFilter.get_size_group()}};

//     var base = {"base": function(diabloNormalFilter){
// 	return diabloNormalFilter.get_base_setting()}};
    
//     $routeProvider. 
// 	when('/new_wsale', {
// 	    templateUrl: '/private/wsale/html/new_wsale.html',
// 	    controller: 'wsaleNewCtrl',
// 	    resolve: angular.extend(
// 	    	{}, user, firm, retailer, employee, s_group, brand, type, color, color_type, base)
// 	}).
// 	when('/new_ssale', {
// 	    templateUrl: '/private/wsale/html/new_ssale.html',
// 	    controller: 'ssaleNewCtrl',
// 	    resolve: angular.extend(
// 	    	{}, user, firm, retailer, employee, s_group, brand, type, color, base)
// 	}).
// 	when('/new_wsale_detail/:page?', {
// 	    templateUrl: '/private/wsale/html/new_wsale_detail.html',
// 	    controller: 'wsaleNewDetailCtrl',
// 	    resolve: angular.extend({}, user, retailer, employee, base) 
// 	}).
// 	when('/update_wsale_detail/:rsn?/:ppage?', {
// 	    templateUrl: '/private/wsale/html/update_wsale_detail.html',
// 	    controller: 'wsaleUpdateDetailCtrl',
// 	    resolve: angular.extend({}, user, retailer, employee, s_group, brand, color, type, base)
// 	}). 
// 	when('/wsale_rsn_detail/:rsn?/:ppage?', {
// 	    templateUrl: '/private/wsale/html/wsale_rsn_detail.html',
// 	    controller: 'wsaleRsnDetailCtrl',
// 	    resolve: angular.extend(
// 		{}, user, brand, retailer, employee, firm, s_group, type, color, base)
// 	}).
// 	when('/reject_wsale', {
// 	    templateUrl: '/private/wsale/html/reject_wsale.html',
// 	    controller: 'wsaleRejectCtrl',
// 	    resolve: angular.extend({}, user, retailer, employee, s_group, color, base) 
// 	}).
// 	when('/update_wsale_reject/:rsn?/:ppage?', {
// 	    templateUrl: '/private/wsale/html/update_wsale_reject.html',
// 	    controller: 'wsaleUpdateRejectCtrl',
// 	    resolve: angular.extend({}, user, retailer, employee, s_group, brand, color, type, base)
// 	}). 
// 	when('/wsale_print_preview/:rsn?', {
// 	    templateUrl: '/private/wsale/html/wsale_print_preview.html',
// 	    controller: 'wsalePrintPreviewCtrl',
// 	    resolve: angular.extend({}, retailer, s_group, base) 
// 	}).
// 	// when('/wsale/reject_wsale_detail', {
// 	//     templateUrl: '/private/wsale/html/reject_wsale_detail.html',
// 	//     controller: 'wsaleRejectDetailCtrl',
// 	//     resolve: angular.extend({}, user, retailer, employee) 
// 	// }).
// 	// otherwise({
// 	//     templateUrl: '/private/wsale/html/wsale_guide.html',
// 	//     controller: 'wsaleGuideCtrl'
//         // }) 
// 	otherwise({
// 	    templateUrl: '/private/wsale/html/new_wsale_detail.html',
// 	    controller: 'wsaleNewDetailCtrl',
// 	    resolve: angular.extend({}, user, retailer, employee, base)
//         })
// }]);

// wsaleApp.service("wsaleService", function($http, $resource, dateFilter){
//     this.error = {
// 	2190: "该款号库存不存在！！请确认本店是否进货该款号！！",
// 	2191: "该货号已存在，请选择新的货号！！",
// 	2192: "客户或营业员不存在，请建立客户或营业员资料！！",
// 	2193: "款号未知，请检查后重新保存！！",
// 	2401: "店铺打印机不存在或打印处理暂停状态！！",
	
// 	2411: "打印机编号错误！！",
// 	2412: "服务器处理订单失败！！", 
// 	2413: "打印内容太长！！",
//     	2414: "打印请求参数错误！！",
// 	2415: "打印请求超时，请稍后再试或联系服务人员！！",
// 	2416: "未知原因，请系统服务人员！！",
	
// 	2417: "发送打印请求失败，请确保网络通畅！！",
	
// 	2418: "打印机打印失败，请联系服务人员查找原因！！",
// 	2419: "打印机未连接！！",
// 	2420: "打印机缺纸！！",
// 	2421: "打印状态未知，请联系服务人员！！",
// 	2422: "打印机连接设备不存在，请检查设备编号是否正确！！",
// 	2423: "打印格式缺少尺码，请在打印格式设置中选中尺码！！",
// 	2601: "获取零售商历史记录失败！！",
// 	2701: "文件导出失败，请重试或联系服务人员查找原因！！",
// 	2702: "文件导出失败，没有任何数据需要导出，请重新设置查询条件！！",
// 	2703: "明细未知，请删除后重新添加！！",
// 	2704: "应付款项与开单项计算有不符！！", 
// 	2699: "修改前后信息一致，请重新编辑修改项！！",
// 	2799: "该款号为补单，无法退货，请重新选择款号！！",
// 	9001: "数据库操作失败，请联系服务人员！！",
// 	2424: "销售总数与销售明细数不符，请检查该单据后再打印！！",
// 	2425: "销售总数应付款项与实际明细应付款项不符，请检查该单据后再打印！！"};

//     this.rsn_title = ["开单明细", "退货明细", "销售明细"];

//     this.direct = {wsale: 0, wreject: 1};

//     this.wsale_mode = [
// 	{title: "普通模式"},
// 	{title: "图片模式"},
// 	{title: "新增货品"}
//     ];

//     this.extra_pay_types = [
// 	{id:0, name: "代付运费"}, 
// 	{id:1, name: "样衣"},
// 	{id:2, name: "少配饰"},
// 	{id:3, name: "代付现金"},
// 	{id:4, name: "初期欠款"}
	
//     ];

//     this.export_type = {trans:0, trans_note:1};
    
//     // =========================================================================
//     var http = $resource("/wsale/:operation/:id",
//     			 {operation: '@operation', id: '@id'},
// 			 {
// 			     query_by_post: {method: 'POST', isArray: true}
// 			 });

//     this.new_w_sale = function(inventory){
// 	return http.save({operation: "new_w_sale"}, inventory).$promise;
//     };

//     this.update_w_sale_new = function(inventory){
// 	return http.save({operation: "update_w_sale"}, inventory).$promise;
//     };

//     this.check_w_sale_new = function(rsn){
// 	return http.save({operation: "check_w_sale"},
// 			 {rsn: rsn}).$promise;
//     };

//     this.new_w_sale_draft = function(inventory){
// 	return http.save({operation: "new_w_sale_draft"}, inventory).$promise;
//     };

//     this.print_w_sale = function(rsn){
// 	return http.save({operation: "print_w_sale"}, {rsn:rsn}).$promise;
//     };
    

//     this.filter_w_sale_image = function(match, fields, currentPage, itemsPerpage){
// 	return http.save({operation: "filter_w_sale_image"},
// 			 {match:  angular.isDefined(match) ? match.op : undefined,
// 			  fields: fields,
// 			  page:   currentPage,
// 			  count:  itemsPerpage}).$promise;
//     };
    
//     // this.list_w_sale_new = function(condition){
//     // 	return http.query_by_post({operation: "list_w_sale_new"}, condition).$promise;
//     // }

//     this.filter_w_sale_new = function(match, fields, currentPage, itemsPerpage){
// 	return http.save({operation: "filter_w_sale_new"},
// 			 {match:  angular.isDefined(match) ? match.op : undefined,
// 			  fields: fields,
// 			  page:   currentPage,
// 			  count:  itemsPerpage}).$promise;
//     };

//     this.filter_w_sale_rsn_group = function(match, fields, currentPage, itemsPerpage){
// 	return http.save({operation: "filter_w_sale_rsn_group"},
// 			 {match:  angular.isDefined(match) ? match.op : undefined,
// 			  fields: fields,
// 			  page:   currentPage,
// 			  count:  itemsPerpage}).$promise;
//     };

//     this.get_w_sale_new = function(rsn){
// 	return http.get({operation: "get_w_sale_new", id:rsn}).$promise;
//     };

//     this.get_w_print_content = function(rsn){
// 	return http.get({operation: "get_w_print_content", id:rsn}).$promise;
//     };

//     this.list_w_sale_draft = function(shop){
// 	return http.query_by_post({operation: "list_w_sale_draft"}, shop).$promise;
//     };

//     this.get_w_sale_draft = function(draft_sn){
// 	return http.save({operation: "get_w_sale_draft"}, draft_sn).$promise;
//     }; 

//     this.reject_w_sale = function(inventory){
// 	return http.save({operation: "reject_w_sale"}, inventory).$promise;
//     };

//     this.filter_w_sale_reject = function(match, fields, currentPage, itemsPerpage){
// 	return http.save({operation: "filter_w_sale_reject"},
// 			 {match:  angular.isDefined(match) ? match.op : undefined,
// 			  fields: fields,
// 			  page:   currentPage,
// 			  count:  itemsPerpage}).$promise;
//     };

//     this.get_last_sale = function(inv){
// 	return http.query_by_post({operation: "get_last_sale"},
// 				  {style_number: inv.style_number,
// 				   brand:        inv.brand,
// 				   shop:         inv.shop,
// 				   retailer:     inv.retailer,
// 				   r_pgood:      inv.r_pgood
// 				  }).$promise;
//     };

//     this.w_sale_rsn_detail = function(inv){
// 	return http.save(
// 	    {operation: "w_sale_rsn_detail"},
// 	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
//     };

//     this.csv_export = function(e_type, condition){
// 	return http.save({operation: "w_sale_export"},
// 			 {condition: condition, e_type:e_type}).$promise;
//     };
    
// });

// define(['wsaleApp'], function(wsaleApp){
//     wsaleApp.controller("wsaleNewDetailCtrl", wsaleNewDetailProvidee);
// });

// wsaleApp.controller("wsaleNewDetailCtrl", function(
//     $scope, $routeParams, $location, dateFilter, diabloUtilsService,
//     localStorageService, diabloFilter, wsaleService,
//     user, filterRetailer, filterEmployee, base){

function wsaleNewDetailProvide(
        $scope, $routeParams, $location, dateFilter, diabloUtilsService,
        localStorageService, diabloFilter, wsaleService,
        user, filterRetailer, filterEmployee, base){
    $scope.shops     = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.records   = [];
    
    $scope.goto_page = diablo_goto_page;
    $scope.f_add     = diablo_float_add;
    $scope.f_sub     = diablo_float_sub;
    $scope.f_mul     = diablo_float_mul;
    $scope.round     = diablo_round;
    
    // $scope.disable_print = false;
    $scope.allowed_slide = true;

    /*
     * hidden
     */
    $scope.show = {base:false, balance:false, action:true, comment:false};

    
    $scope.toggle_balance = function(){
	// console.log("toggle left");
	$scope.show.balance = !$scope.show.balance;
    };

    $scope.toggle_base = function(){
	$scope.show.base = !$scope.show.base;
    };

    // $scope.toggle_check = function(){
    // 	$scope.show.check = !$scope.show.check;
    // };

    $scope.toggle_action = function(){
	$scope.show.action = !$scope.show.action;
    };

    $scope.toggle_comment = function(){
	$scope.show.comment = !$scope.show.comment;
    }; 

    
    /* 
     * filter operation
     */
    // 0: >0 1: <0
    var has_pay =  [{name:">0", id:0, py:diablo_pinyin("大于0")},
    		    {name:"=0", id:1, py:diablo_pinyin("等于0")}];
    
    // initial 
    diabloFilter.reset_field();
    diabloFilter.add_field("retailer", filterRetailer);
    diabloFilter.add_field("has_pay",  has_pay);
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     $scope.shops);
    diabloFilter.add_field("employee", filterEmployee);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // console.log($scope.filter);
    // console.log($scope.prompt);

    var now = $.now();

    var storage = localStorageService.get(diablo_key_wsale_trans);
    // console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
    	$scope.filters        = storage.filter;
    	$scope.qtime_start    = storage.start_time;
    } else{
	$scope.filters = [];
	
	$scope.qtime_start = function(){
	    var shop = -1;
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
    };

    $scope.time   = diabloFilter.default_time($scope.qtime_start);

    //
    $scope.sequence_pagination = function(){
	return diablo_sequence_page() === diablo_yes
	    ? diablo_yes
	    : diablo_base_setting(
		"se_pagination", -1, base, parseInt, diablo_no)
    }();

    // console.log($scope.time);

    /*
     * pagination 
     */
    $scope.colspan = 19;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_page_size();

    // console.log($routeParams);
    $scope.default_page = 1;

    // console.log($routeParams);
    var back_page = diablo_set_integer($routeParams.page);
    // console.log(back_page);
    
    if (angular.isDefined(back_page)){
	$scope.current_page = back_page;
    } else{
	$scope.current_page = $scope.default_page; 
    };
    
    // console.log($scope.current_page);

    $scope.do_search = function(page){
	// console.log(page);

	$scope.current_page = page;

	// save condition of query 
	localStorageService.set(
	    diablo_key_wsale_trans,
	    {filter:$scope.filters,
	     start_time: diablo_get_time($scope.time.start_time),
	     page:page, t:now});
	

	// console.log($scope.time); 
	if (angular.isDefined(back_page)){
	    var stastic = localStorageService.get("wsale-trans-stastic");
	    // console.log(stastic);
	    $scope.total_items      = stastic.total_items;
	    $scope.total_amounts    = stastic.total_amounts;
	    $scope.total_spay       = stastic.total_spay;
	    $scope.total_hpay       = stastic.total_hpay;
	    $scope.total_cash       = stastic.total_cash;
	    $scope.total_card       = stastic.total_card;
	    $scope.total_wire       = stastic.total_wire;
	    $scope.total_verificate = stastic.total_verificate;
	    $scope.total_epay       = stastic.total_epay;

	    // recover 
	    $location.path("/new_wsale_detail", false);
	    $routeParams.page = undefined;
	    if ($scope.sequence_pagination === diablo_no){
		back_page = undefined; 
	    }
	    localStorageService.remove("wsale-trans-stastic");
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }

	    var items    = $scope.items_perpage;
	    var page_num = page;
	    if (angular.isDefined(back_page)
		&& $scope.sequence_pagination === diablo_yes){
		items = page * $scope.items_perpage;
		$scope.records = []; 
		page_num = 1;
		back_page = undefined;
	    }
	    
	    wsaleService.filter_w_sale_new(
		$scope.match, search, page_num, items
	    ).then(function(result){
		// console.log(result);
		if (page === 1 && angular.isUndefined(back_page)){
		    $scope.total_items      = result.total;
		    $scope.total_amounts    = result.t_amount;
		    $scope.total_spay       = $scope.round(result.t_spay);
		    $scope.total_hpay       = $scope.round(result.t_hpay);
		    $scope.total_cash       = result.t_cash;
		    $scope.total_card       = result.t_card;
		    $scope.total_wire       = result.t_wire;
		    $scope.total_verificate = result.t_verificate;
		    $scope.total_epay       = result.t_epay; 
		    $scope.records = [];
		}
		
		angular.forEach(result.data, function(d){
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.retailer = diablo_get_object(d.retailer_id, filterRetailer); 
		});

		if ($scope.sequence_pagination === diablo_no){
		    $scope.records = result.data; 
		    diablo_order_page(
			page, $scope.items_perpage, $scope.records);
		} else {
		    diablo_order(
			result.data, (page_num - 1) * $scope.items_perpage + 1);
		    $scope.records = $scope.records.concat(result.data); 
		}
		
	    })
	})
    };
    
    $scope.page_changed = function(){
	// console.log($scope.num_pages);
	// console.log($scope.current_page);
    	$scope.do_search($scope.current_page);
    };

    $scope.auto_pagination = function(){
	if ($scope.sequence_pagination === diablo_no){
	    return;
	} else {
	    $scope.current_page += 1;
	    $scope.do_search($scope.current_page);
	} 
    };

    if (angular.isDefined(back_page)){
	$scope.do_search($scope.current_page); 
    }

    $scope.save_stastic = function(){
	localStorageService.set(
	    "wsale-trans-stastic",
	    {total_items:      $scope.total_items,
	     total_amounts:    $scope.total_amounts,
	     total_spay:       $scope.total_spay,
	     total_hpay:       $scope.total_hpay,
	     total_cash:       $scope.total_cash,
	     total_card:       $scope.total_card,
	     total_wire:       $scope.total_wire,
	     total_verificate: $scope.total_verificate,
	     total_epay:       $scope.total_epay,
	     t:                now});
    };
    
    $scope.rsn_detail = function(r){
	// console.log(r);
	// console.log($scope.current_page);
	$scope.save_stastic();	
	diablo_goto_page(
	    "#/wsale_rsn_detail/"
		+ r.rsn + "/" + $scope.current_page.toString()); 
    };

    $scope.f_print = function(r){
	diablo_goto_page("#/wsale_print_preview/" + r.rsn); 
    };

    var dialog = diabloUtilsService;
    $scope.print = function(r){
	// $scope.disable_print = true;
	wsaleService.print_w_sale(r.rsn).then(function(result){
	    console.log(result);
	    // $scope.disable_print = false; 
	    if (result.ecode == 0){
		var msg = "";
		if (result.pcode == 0){
		    msg = "销售单打印成功！！单号：" + result.rsn + "，请等待服务器打印";
		    dialog.response(true, "销售单打印", msg, $scope); 
		} else {
		    if (result.pinfo.length === 0){
			msg += wsaleService.error[result.pcode]
		    } else {
			angular.forEach(result.pinfo, function(p){
			    msg += "[" + p.device + "] " + wsaleService.error[p.ecode]
			})
		    };
		    msg = "销售单打印失败！！单号：" + result.rsn + "，打印失败：" + msg;
		    dialog.response(false, "销售单打印", msg, $scope); 
		}
		
	    } else{
	    	dialog.response(
	    	    false, "销售单打印",
		    "销售单打印失败：" + wsaleService.error[result.ecode]);
	    }
	})
    };

    $scope.update_detail = function(r){
	$scope.save_stastic();
	if (r.type === 0 || r.type == 9){
	    diablo_goto_page(
		'#/update_wsale_detail/'
		    + r.rsn + "/" + $scope.current_page.toString()); 
	} else {
	    diablo_goto_page(
		'#/update_wsale_reject/'
		    + r.rsn + "/" + $scope.current_page.toString()); 
	}
    };

    $scope.check_detail = function(r){
	// console.log(r);
	var callback = function(){
	    wsaleService.check_w_sale_new(r.rsn).then(function(state){
		// console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "销售单审核", "销售单审核成功！！单号：" + state.rsn,
			$scope, function(){r.state = 1})
	    	    return;
		} else{
	    	    dialog.response(
	    		false, "销售单审核",
	    		"销售单审核失败：" + wsaleService.error[state.ecode]);
		}
	    })
	};

	diabloUtilsService.request(
	    "销售单审核", "审核完成后，销售单将无法修改，确定要审核吗？",
	    callback, undefined, $scope);
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    // console.log(search);
	    
	    wsaleService.csv_export(wsaleService.export_type.trans, search).then(function(result){
	    	// console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    dialog.response(
			false, "文件导出失败", "创建文件失败：" + wsaleService.error[result.ecode]);
		} 
	    }); 
	}) 
    };
};


// wsaleApp.controller("wsaleGuideCtrl", function($scope){
//     $scope.goto_page = diablo_goto_page;

//     $scope.new_wsale = function(){
// 	$scope.goto_page("#/wsale/new_wsale");
//     }

//     $scope.reject_wsale = function(){
// 	$scope.goto_page("#/wsale/reject_wsale");
//     }
    
//     $scope.wsale_rsn_detail = function(){
// 	$scope.goto_page("#/wsale_rsn_detail");
//     }
// })


// require(["wsaleApp", "wsale-good", "wsale-new", "wsale-update", "wsale-reject",
// 	 "wsale-update-reject", "wsale-rsn", "diablo-login-out"],
// 	function(app, wg, wn, wu, wr, wur, ws, loginout){
// 	    app.factory("wsaleGoodService", wg.wsaleGoodServiceProvide);
// 	    app.controller("wsaleGoodNewCtrl", wg.wsaleGoodNewCtrlProvide);
// 	    app.controller("wsaleNewCtrl", wn.wsaleNewProvide);
// 	    app.controller("wsaleNewDetailCtrl", wsaleNewDetailProvide);

// 	    app.controller("loginOutCtrl", function($scope, $resource){
// 		$scope.home = function () {loginout($resource)};
// 	    });

// 	    app.controller("wsaleUpdateDetailCtrl", wu.wsaleUpdateDetailProvide);
// 	    app.controller("wsaleRejectCtrl", wr.wsaleRejectCtrlProvide); 
// 	    app.controller("wsaleRejectUpdateCtrl", wur.wsaleRejectUpdateCtrlProvide); 
// 	    app.controller("wsaleRsnDetailCtrl", ws.wsaleRsnDetailCtrlProvide);
// 	});
