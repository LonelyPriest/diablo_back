// var rightApp = angular.module(
//     "rightApp", ['ngRoute', 'ngResource', 'diabloUtils',
// 		 'ui.bootstrap', 'merchantApp', 'employApp', 'shopApp']).config(diablo_authen);

var rightApp = angular.module("rightApp", []);

// rightApp.config(['$routeProvider', function($routeProvider){
//     //console.log($rootScope);
//     $routeProvider.
// 	when('/account_user/account_detail', {
// 	    templateUrl: '/private/right/html/account_user_detail.html',
// 	    controller: 'accountUserDetailCtrl'
// 	}).
// 	when('/account_user/account_new', {
// 	    templateUrl: '/private/right/html/account_user_new.html',
// 	    controller: 'accountUserNewCtrl'
// 	}).
// 	when('/role_user/role_new', {
// 	    templateUrl: '/private/right/html/role_user_new.html',
// 	    controller: 'roleUserNewCtrl'
// 	}).
// 	when('/role_user/role_detail', {
// 	    templateUrl: '/private/right/html/role_user_detail.html',
// 	    controller: 'roleUserDetailCtrl'
// 	}).
// 	when('/account_merchant/account_new', {
// 	    templateUrl: '/private/right/html/account_merchant_new.html',
// 	    controller: 'accountMerchantNewCtrl'
// 	}).
// 	when('/account_merchant/account_detail', {
// 	    templateUrl: '/private/right/html/account_merchant_detail.html',
// 	    controller: 'accountMerchantDetailCtrl'
// 	}).
// 	when('/role_merchant/role_detail', {
// 	    templateUrl: '/private/right/html/role_merchant_detail.html',
// 	    controller: 'roleMerchantDetailCtrl'
// 	}).
// 	when('/role_merchant/role_new', {
// 	    templateUrl: '/private/right/html/role_merchant_new.html',
// 	    controller: 'roleMerchantNewCtrl'
// 	}).
// 	otherwise({
// 	    templateUrl: function(rd){
// 		console.log(rd);
// 	    }
// 	    // templateUrl: '/private/right/html/account_user_detail.html',
// 	    // controller: 'accountUserDetailCtrl'
// 	})
// 	// otherwise({
// 	//     redirectTo: '/'
// 	// })
// }]);
 //.run( function($rootScope, $location) {
 //    // register listener to watch route changes
 //    $rootScope.$on( "$routeChangeStart", function(event, next, current) {
 // 	console.log(event);
 // 	console.log(next);
 // 	console.log(current);
 // 	console.log($rootScope); 
 //    });
 // })

rightApp.directive("dynaTree", function(){
    return{
	restrict: 'AE',
	// templateUrl: '/private/utils/html/subbmitNotifyDialog.html',
	replace: false,
	transclude: true,
	scope:{
	    checkbox: '@',
	    treeData: '=treeData',
	    selectMode: '@'
	    //onSelect: '&'
	},

	link: function(scope, element, attrs){
	    // console.log(scope);
	    scope.treeData.then(function success(data){
		// console.log(data);
		rights = data[0];
		// console.log(rights);

		element.dynatree({
		    checkbox: true,
		    selectMode: 3,
		    children: [],
		    onSelect: function(select, node){
			scope.$parent.onSelect(select, node)
		    }
		});

		var tree = element.dynatree("getTree")
		var rootNode = tree.getRoot();
		// create catlogs
		var remainCatlogs = [];
		var parentNode = null;
		angular.forEach(rights, function(catlog){
		    if (catlog.parent == 0){
			rootNode.addChild({
			    title: catlog.name,
			    key  : catlog.id,
			    isFolder: false
			})
		    }
		    else {
			//console.log(tree.toDict(false));
			parentNode = tree.getNodeByKey(catlog.parent.toString());
			//console.log(parentNode);
			if (parentNode != null ){
			    // console.log(parentNode);
			    parentNode.data.isFolder = true;
			    parentNode.addChild({
				title: catlog.name,
				key  : catlog.id,
				isFolder: false
			    })}
			else{
			    remainCatlogs.push(angular.copy(catlog))
			}
		    }
		});
	    })

	}
    }
});


rightApp.directive("roleTree", function(){
    return{
	restrict: 'AE',
	replace: false,
	transclude: true,
	require: "ngModel",
	scope: {},

	link: function(scope, element, attrs, ngModel){
	    // console.log(ngModel);
	    element.dynatree({
		checkbox: true,
		selectMode: 3,
		children: [],
		onSelect: function(select, node){
		    scope.$parent.onSelect(select, node)
		}
	    });

	    var tree = element.dynatree("getTree");
	    // console.log(scope);
	    ngModel.$setViewValue(tree);
	    // scope.$apply();

	    // console.log(ngModel);
	}
    }

});


rightApp.directive("roleEditTree", function(){
    return{
	restrict: 'AE',
	replace: false,
	transclude: true,
	require: "ngModel",
	scope: {},
	
	link: function(scope, element, attrs, ngModel){
	    // console.log(ngModel);
	    element.dynatree({
		checkbox: true,
		selectMode: 3,
		children: [],
		onSelect: function(select, node){
		    scope.$parent.onSelect(select, node)
		}
	    });

	    var tree = element.dynatree("getTree")
	    ngModel.$setViewValue(tree);
	    //scope.$apply();

	    console.log(ngModel);
	}
    }

});


rightApp.service("rightService", function($resource, $q, $modal, dateFilter){
    // right description
    this.roleType = {
	merchant: 1,
	user: 2
    };

    this.roleTypeDesc = {
	1: "超级管理员创建",
	2: "商家自己创建"
    };

    this.accountDesc = {
	1: "商户帐户",
	2: "用户帐户"
    };

    // error information
    this.error = {
	1501: "系统不支持创建该类型的帐户！！",
	1502: "帐户创建失败，已存在同样的帐户名称！！",
	1503: "该商家账户已存在！！",
	1504: "角色创建失败，已存在同样的角色名称！！",
	1507: "帐户超过用户购买量限制！！",
	6001: "权限修改失败，权限相同，不需要修改！！",
	7001: "系统暂不支持该操作！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    this.tree_modal = function(template, scope, tree_callback, tree_update){
	$modal.open({
            templateUrl: template,
            controller: 'roleTreeModalCtrl',
            backdrop: 'static',
            scope: scope,
            resolve:{
		params: function(){return {
		    tree_callback: tree_callback,
		    tree_update: tree_update
		}}
            }
	})
    };

    // =========================================================================
    var right = $resource("/right/:operation/:id",
			  {operation: '@operation', id: '@id'},
			  {
			      destroy:       {method: 'POST'},
			      list:            {method: 'GET'}
			  });
    
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
    
    // =============================================================================
    // role
    // =============================================================================
    this.list_right_catlog = function(){
	return right.query({operation: "list_right_catlog"})
    };

    // ====================================================
    // type: role type, 1--merchant, 2-- user
    // ====================================================
    this.add_role = function(role, type, one){
	//console.log(data);
	var  info = {
	    name:    role.name,
	    desc:    role.desc,
	    type:    type,
	    fun_id:  one.fun_id
	};

	if (angular.isDefined(one.shops) && one.shops.length > 0){
	    info.shops = one.shops
	};

	return right.save({operation: "new_role"}, info);
    };

    this.update_role = function(role, added, deleted){
	var payload = {};
	if (angular.isArray(added) && added.length !== 0){
	    payload.added = added
	};
	if (angular.isArray(deleted) && deleted.length !== 0){
	    payload.deleted = deleted
	};

	payload.role_id = role.id;
	payload.role_type = role.type;
	
	return right.save({operation: "update_role"}, payload);
    };


    this.update_user_role = function(role, addRight, deleteRight, addShops, deleteShops){
	var payload = {};
	if (angular.isArray(addRight) && addRight.length !== 0){
	    payload.add_right = addRight;
	};
	if (angular.isArray(deleteRight) && deleteRight.length !== 0){
	    payload.delete_right = deleteRight;
	};
	if (angular.isArray(addShops) && addShops.length !== 0){
	    payload.add_shops = addShops;
	};
	if (angular.isArray(deleteShops) && deleteShops.length !== 0){
	    payload.delete_shops = deleteShops;
	};

	payload.role_id = role.id;
	payload.role_type = role.type;
	
	return right.save({operation: "update_role"}, payload);
    };

    

    this.list_role = function(){
	return right.query({operation: "list_role"})
    };

    this.get_right_by_role_id = function(roleId){
	return right.query({operation:"get_right_by_role_id", id:roleId})
    };

    this.get_shop_by_role= function(roleId){
	return right.query({operation:"get_shop_by_role", id:roleId})
    };

    // this.user_role_right_of_all = function(){
    // 	var catlogs = promise(this.list_right_catlog);	
    // 	return $q.all([catlogs()]);
    // };

    this.user_role_right = function(roleId){
	var obj = this;
	var get_role_catlogs = function(){
	    var deferred = $q.defer();
	    obj.get_right_by_role_id(roleId).$promise.then(function(catlogs){
		//console.log(catlogs);
		deferred.resolve(catlogs);
	    });
	    return deferred.promise;
	};

	var get_role_shops = function(){
	    var deferred = $q.defer();
	    obj.get_shop_by_role(roleId).$promise.then(function(shops){
		//console.log(catlogs);
		deferred.resolve(shops);
	    });
	    return deferred.promise;
	};

	return $q.all([get_role_catlogs(), get_role_shops()]);
    }


    // =============================================================================
    // account
    // =============================================================================
    this.add_account = function(one){
	var account =
	    {name:         one.name,
	     password:     one.password,
	     type:         one.type,
	     role:         one.role.id,
	    };
	// a common user does not to select the special merchant
	if (angular.isDefined(one.merchant)){
	    account.merchant = one.merchant.id;
	    account.max_create = one.max_create;
	}
	
	return right.save(
	    {operation: "new_account"}, account)
    };

    this.list_account = function(){
	return right.query({operation: "list_account"})
    };

    this.list_account_right = function(account){
	return right.query({operation: "list_account_right", id: account.id})
    };

    this.delete_account = function(account){
	return right.destroy(
	    {operation: "del_account"},
	    {account: account.id, type: account.type})
    };

    this.update_account_role = function(account, role){
	return right.save(
	    {operation: "update_account"},
	    {account: account.id, role: role.id})
    };

    // /////////////////////////////////////////////////////////////////////////////

    this.list = function(){
	return right.list({operation: "list_right"})
    };

    this.get_inventory_children = function(){
	return right.query({operation: "list_inventory_children"})
    };

    this.get_sales_children = function(){
	return right.query({operation: "list_sales_children"})
    };

    // shop
    var HttpShop = $resource("/shop/:operation/:id",
    			 {operation: '@operation', id: '@id'});
    // var members = $resource("/member/:operation/:number");

    this.list_shop = function(){
	return HttpShop.query({operation: "list_shop"})};

});


rightApp.controller("roleTreeModalCtrl", function(
    $scope, $modalInstance, params, rightService){
    console.log($scope);
    console.log(params);
    
    $scope.$watch("rightTree", function(newValue, oldValue){
	if (angular.isUndefined(newValue)){
	    return;
	} else{
	    if (angular.isDefined(params.tree_callback)){
		params.tree_callback($scope.rightTree);
	    }
	}
    });

    $scope.cancel = function(){
	$modalInstance.dismiss('cancel');
    };

    $scope.ok = function() {
	$modalInstance.dismiss('ok');
	if (angular.isDefined(params.tree_update)
	   && typeof(params.tree_update) === 'function'){
	    params.tree_update();
	}
    };
});

rightApp.controller("rightUserCtrl", function($scope, $location){
    // // $location.path("/account_user/account_detail");
    // console.log($location);
    
});
