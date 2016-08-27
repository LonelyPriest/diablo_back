var wgoodApp = angular.module(
    "wgoodApp", ['ngRoute', 'ngResource',
		 'diabloUtils', 'diabloFilterApp', 'diabloNormalFilterApp',
		 'diabloPattern', 'diabloAuthenApp', 'ui.bootstrap',
		 'userApp'])
// .config(diablo_authen);
.config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor); 
});

wgoodApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
	return userService()}}; 

    var brand = {"filterBrand": function(diabloFilter){
	return diabloFilter.get_brand()}};
    
    var firm = {"filterFirm": function(diabloFilter){
	return diabloFilter.get_firm()}}; 

    var type = {"filterType": function(diabloFilter){
	return diabloFilter.get_type()}};
    
    var color = {"filterColor": function(diabloFilter){
	return diabloFilter.get_color()}};

    var color_type = {"filterColorType": function(diabloFilter){
	return diabloFilter.get_color_type()}};

    var s_group = {"filterSizeGroup": function(diabloFilter){
	return diabloFilter.get_size_group()}};

    var base = {"base": function(diabloNormalFilter){
	return diabloNormalFilter.get_base_setting()}};
    
    $routeProvider.
	when('/wgood_detail', {
	    templateUrl: '/private/wgood/html/wgood_detail.html',
            controller: 'wgoodDetailCtrl',
	    resolve: angular.extend({}, user, brand, firm, type, color, base) 
	}).
	when('/wgood_update/:id?', {
	    templateUrl: '/private/wgood/html/wgood_update.html',
            controller: 'wgoodUpdateCtrl',
	    resolve: angular.extend({}, brand, firm, type, color, s_group, user, base)
	}).
	when('/wgood_new', {
	    templateUrl: '/private/wgood/html/wgood_new.html',
            controller: 'wgoodNewCtrl',
	    resolve: angular.extend({}, user, brand, firm, type, s_group, base)
	}).
	when('/setting/size', {
	    templateUrl: '/private/wgood/html/wgood_size.html',
            controller: 'wgoodSizeDetailCtrl',
	    resolve: angular.extend({}, s_group)
	}).
	when('/setting/color', {
	    templateUrl: '/private/wgood/html/wgood_color.html',
            controller: 'wgoodColorDetailCtrl',
	    resolve: angular.extend({}, color_type, color)
	}).
	otherwise({
	    templateUrl: '/private/wgood/html/wgood_detail.html',
            controller: 'wgoodDetailCtrl',
	    resolve: angular.extend({}, user, brand, firm, type, color, base) 
        })
}]);


wgoodApp.service("wgoodService", function($resource, $http, dateFilter){
    // error
    this.error = {
	2001: "货品资料已存在！！",
	2098: "该货品资料正在使用！！",
	2099: "修改前后数据一致，请重新编辑修改项！！",
	1601: "厂商创建失败，已存在同样的厂商！！",
	1901: "该颜色已存在！！",
	1902: "该尺码组已存在！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    // free color, size
    this.free_color = 0;
    this.free_size  = 0;

    this.format_size_group = function(gids, size_groups){
	var gnames = [];
	gids.split(",").map(function(id){
	    angular.forEach(size_groups, function(g){
		if (parseInt(id) === g.id){
		    angular.forEach(diablo_sizegroup, function(sname){
			if (g[sname] && !in_array(gnames, g[sname])){
			    gnames.push(g[sname]);
			}
		    })
		}
	    })
	}); 

	// // not found, free size
	// if (gnames.length === 0){
	//     gnames.push("0");
	// }
	
	return gnames;
    };


    this.get_size_group = function(gids, size_groups){
	var gnames = [];
	gids.split(",").map(function(id){
	    angular.forEach(size_groups, function(g){
		if (parseInt(id) === g.id){
		    angular.forEach(diablo_sizegroup, function(sname){
			if (g[sname] && !in_array(gnames, g[sname])){
			    gnames.push(g[sname]);
			}
		    })
		}
	    })
	}); 

	// // not found, free size
	// if (gnames.length === 0){
	//     gnames.push("0");
	// }
	
	return gnames;
    };
    
    // =========================================================================    
    var http = $resource("/wgood/:operation/:id",
    			 {operation: '@operation', id: '@id'},
			 {
			     query_by_post: {method: 'POST', isArray:true}
			 });

    this.list_purchaser_brand = function(){
	return http.query({operation: "list_brand"}).$promise
    };
    
    this.list_purchaser_firm = function(){
	return http.query({operation: "list_supplier"}).$promise;
    };

    this.list_purchaser_type = function(){
	return http.query({operation: "list_type"}).$promise;
    };

    /*
     * color
     */
    this.list_color_type = function(){
	return http.query({operation: 'list_color_type'}).$promise;
    };
    
    this.list_purchaser_color = function(){
	return http.query({operation: 'list_w_color'}).$promise;
    };

    this.get_colors = function(colors){
	return http.query_by_post({operation: 'get_colors'}, {color: colors}).$promise;
    };

    this.add_purchaser_color = function(color){
	return http.save(
	    {operation: "new_w_color"},
	    {name: color.name,
	     type: color.type,
	     remark: color.remark}).$promise;
    };

    /*
     * size
     */
    this.list_purchaser_size = function(){
	return http.query({operation: 'list_w_size'}).$promise;
    };

    this.add_purchaser_good = function(good){
	return http.save({operation: "new_w_good"}, good).$promise;
    };

    this.add_purchaser_size = function(group){
	return http.save(
	    {operation: "new_w_size"},
	    {name: group.name,
	     si:     group.si,
	     sii:    group.sii,
	     siii:   group.siii,
	     siv:    group.siv,
	     sv:     group.sv,
	     svi:    group.svi}).$promise;
    };

    /*
     * good
     */
    this.list_purchaser_good = function(){
    	return http.query({operation: "list_w_good"}).$promise;
    };

    this.filter_purchaser_good = function(match, fields, currentPage, itemsPerpage){
	return http.save({operation: "filter_w_good"},
			 {match:  angular.isDefined(match) ? match.op : undefined,
			  fields: fields,
			  page:   currentPage,
			  count:  itemsPerpage}).$promise;
    };

    this.get_purchaser_good = function(good){
    	return http.save({operation: "get_w_good"}, good).$promise;
    };

    this.get_purchaser_good_by_id = function(id){
	return http.get({operation: "get_w_good", id: id}).$promise;
    };

    this.get_used_purchaser_good = function(good){
	return http.save(
	    {operation: "get_used_w_good"},
	    {style_number: good.style_number,
	     brand:        good.brand}).$promise;
    };

    this.match_purchaser_style_number = function(viewValue){
	// return $http.post("/wgood/filter_w_good_style_number",
	// 		  {prompt_value: viewValue});
	return http.query_by_post({operation: "match_w_good_style_number"},
				  {prompt_value: viewValue}).$promise;
    };

    this.match_purchaser_good_with_firm = function(viewValue, firm){
	return http.query_by_post(
	    {operation: "match_w_good"},
	    {prompt_value: viewValue, firm: firm}).$promise;
    };

    this.match_all_purchaser_good = function(start_time, firm){
	return http.query_by_post(
	    {operation: "match_all_w_good"},
	    {start_time: start_time, firm: firm}).$promise;
    };

    this.add_purchaser_good = function(good, image){
	return http.save({operation: "new_w_good"}, {good:good, image:image}).$promise;
    };

    this.delete_purchaser_good = function(good){
	return http.delete({operation:"delete_w_good", id:good.id}).$promise;
    }

    this.update_purchaser_good = function(good, image){
	return http.save({operation: "update_w_good"}, {good:good, image:image}).$promise;
    }; 

    /*
     * firm
     */
    var firm_http = $resource("/firm/:operation", {operation: '@operation'});
    this.new_firm = function(firm){
	var balance = firm.balance;
	return firm_http.save(
	    {operation:"new_firm"},
	    {name:    firm.name,
	     balance: angular.isDefined(balance) ? parseInt(balance) : 0,
	     mobile:  angular.isDefined(firm.mobile) && firm.mobile ? firm.mobile:undefined,
	     address: firm.address}).$promise
    }; 
});


wgoodApp.controller("wgoodCtrl", function(){});

wgoodApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {diablo_login_out($resource)};
});
