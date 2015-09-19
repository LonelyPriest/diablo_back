var wprintApp = angular.module(
    'wprintApp', ['ui.bootstrap', 'ngRoute', 'ngResource', 'diabloAuthenApp',
		  'diabloPattern', 'diabloUtils', 'merchantApp'])
// .config(diablo_authen);
.config(function($httpProvider, authenProvider){
    // $httpProvider.responseInterceptors.push(authenProvider.interceptor);
    $httpProvider.interceptors.push(authenProvider.interceptor);
});

wprintApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
	when('/server/new', {
	    templateUrl: '/private/wprint/html/wprint_server_new.html',
            controller: 'serverNewCtrl'
	}). 
	when('/server/detail', {
	    templateUrl: '/private/wprint/html/wprint_server_detail.html',
            controller: 'serverDetailCtrl'
	}).
	when('/printer/new', {
	    templateUrl: '/private/wprint/html/wprint_printer_new.html',
            controller: 'printerNewCtrl'
	}). 
	when('/printer/detail', {
	    templateUrl: '/private/wprint/html/wprint_printer_detail.html',
            controller: 'printerDetailCtrl'
	}). 
	when('/printer/connect_new', {
	    templateUrl: '/private/wprint/html/wprint_printer_connect_new.html',
            controller: 'printerConnectNewCtrl'
	}). 
	when('/printer/connect_detail', {
	    templateUrl: '/private/wprint/html/wprint_printer_connect_detail.html',
            controller: 'printerConnectDetailCtrl'
	}). 
	otherwise({
	    templateUrl: '/private/wprint/html/wprint_printer_connect_detail.html',
	    controller: 'printerConnectDetailCtrl'
        })
}]);


wprintApp.service("wprintService", function($resource, dateFilter){    
    // error information
    this.error = {
	2301: "该打印机已存在！！",
	2302: "该打印机正在使用！！",
	2417: "发送打印请求失败，请确保网络通畅！！",

	2401: "店铺打印机不存在或打印处理暂停状态！！",
	2411: "打印机编号错误！！",
	2412: "服务器处理订单失败！！", 
	2413: "打印内容太长！！",
    	2414: "打印机请求参数错误！！",
	2416: "未知原因，请系统服务人员！！",
	
	2418: "打印失败，请联系服务人员查找原因！！",
	2419: "打印机未连接！！",
	2420: "打印机缺纸！！",
	2421: "打印状态未知，请联系服务人员！！",
	2422: "打印机连接设备不存在，请检查设备编号是否正确！！",
	2423: "打印格式缺少尺码，请在打印格式设置中选中尺码！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    this.printer_brands = [{chinese:"爱普生", name:"epson"},
			   {chinese:"富士通", name:"fujitsu"},
			   {chinese:"映美",   name:"jolimark"},
			   {chinese:"飞鹅",   name:"feie"}];

    this.paper_columns  = [33, 50, 80, 106];
    this.paper_heights  = [0, 14, 28];
    
    this.print_status = [{cname:"启动", value: 0},
			 {cname:"暂停", value: 1}];

    this.print_actions = [{value:0, name:"不打印"},
			  {value:1, name:"打印"}];
    
    this.get_chinese_brand = function(name){
	for (var i=0, l=this.printer_brands.length; i<l; i++){
	    if (name === this.printer_brands[i].name){
		return this.printer_brands[i].chinese;
		break;
	    }
	}
    };

    // =========================================================================    
    var http = $resource("/wprint/:operation/:id",
    			 {operation: '@operation', id: '@id'},
			 {
			     query_by_post: {method: 'POST', isArray: true}
			 });

    this.new_wprint_server = function(server){
	return http.save(
	    {operation:"new_w_print_server"},
	    {name:    server.name,
	     path:    server.url}).$promise
    };

    this.list_wprint_server = function(){
	return http.query({operation: "list_w_print_server"}).$promise
    };

    this.new_wprinter = function(p){
	return http.save({operation: "new_w_printer"},
			 {brand:  p.brand.name,
			  model:  p.model,
			  column: p.column}).$promise
    };

    this.list_wprinter = function(){
	return http.query({operation: "list_w_printer"}).$promise
    };

    this.list_shop_by_merchant = function(merchant){
	return http.query_by_post({operation: "list_shop_by_merchant"},
			 {merchant: merchant}).$promise
    };
    
    this.new_wprinter_conn = function(printer){
	return http.save(
	    {operation:"new_w_printer_conn"},
	    {sn:       printer.sn,
	     key:      printer.key,
	     printer:  printer.brand.id,
	     column:   printer.column,
	     height:   printer.height,
	     pserver:  printer.server.id, 
	     merchant: angular.isDefined(printer.merchant) ? printer.merchant.id:undefined,
	     shop:     angular.isDefined(printer.shop)? printer.shop.id : undefined}).$promise
    };

    this.delete_wprinter_conn = function(pId){
	return http.delete({operation: "del_w_printer_conn", id:pId}).$promise;
    };
    
    this.update_wprinter_conn = function(printer){
	return http.save(
	    {operation:"update_w_printer_conn"},
	    {id:      printer.id,
	     sn:      printer.sn,
	     key:     printer.key,
	     column:  printer.column,
	     height:  printer.height,
	     printer: angular.isDefined(printer.brand)?printer.brand.id:undefined,
	     pserver: angular.isDefined(printer.server)?printer.server.id:undefined,
	     // merchant:angular.isDefined(printer.merchant) ? printer.merchant.id:undefined,
	     shop:    angular.isDefined(printer.shop)? printer.shop.id : undefined,
	     status:  angular.isDefined(printer.status)?printer.status.value:undefined}).$promise
    };

    this.list_wprinter_conn = function(){
	return http.query({operation: "list_w_printer_conn"}).$promise
    };

    // format
    this.list_printer_format = function(){
	return http.query({operation: 'list_w_printer_format'}).$promise;
    };

    this.update_printer_format = function(format){
	return http.save({operation: "update_w_printer_format"}, format).$promise;
    };

    this.add_shop_format = function(shop){
	return http.save({operation: "add_w_printer_format_to_shop"},
			 {shop: shop}).$promise;
    };

    this.test_printer = function(p){
	return http.save({operation: "test_w_printer"},
			 {id:       p.id,
			  merchant: p.merchant_id,
			  shop    : p.shop_id}).$promise;
    };
    
});

wprintApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
