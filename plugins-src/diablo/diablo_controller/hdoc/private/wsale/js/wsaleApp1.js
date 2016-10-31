define(["angular", "angular-router", "angular-resource", "angular-local-storage",
	"angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
	"diablo-authen-right", "diablo-utils", "diablo-filter", "diablo-good"
       ], function(angular) {
    var wsaleApp1 = angular.module(
        'wsaleApp1',
        ['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'wgoodApp',
	 'userApp'
	 //'wretailerApp', 'purchaserApp'
	])
    	.config(function(localStorageServiceProvider){
    	    localStorageServiceProvider
    		.setPrefix('wsaleApp1')
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

    wsaleApp1.config(['$routeProvider', function($routeProvider){
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
    		controller: 'wsaleUpdateRejectCtrl',
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

    wsaleApp1.service("wsaleService", function($http, $resource, dateFilter){
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

    return wsaleApp1;
});
