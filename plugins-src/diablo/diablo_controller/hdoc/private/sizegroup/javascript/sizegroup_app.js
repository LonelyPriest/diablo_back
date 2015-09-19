
var shopApp = angular.module(
    "shopApp",
    ['ngRoute', 'ngResource', 'ngTable',
     'subbmitNotify', 'ngTableUtils',
     'employApp', 'shopApp', 'ui.bootstrap']);

shopApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
	when('/shop/shop_detail', {
	    templateUrl: '/private/shop/html/shop_detail.html',
            controller: 'shopDetailCtrl'
	}).
	when('/shop/shop_new', {
	    templateUrl: '/private/shop/html/shop_new.html',
            controller: 'newShopCtrl'
	}).
	otherwise({
	    templateUrl: '/private/shop/html/shop_detail.html',
            controller: 'shopDetailCtrl'
            // templateUrl: '/private/member/html/member_index.html',
            // controller: 'memberCtrl'
        })
}]);


shopApp.service("shopService", function($resource, dateFilter){
    // error
    this.error = {1301: "店铺创建失败，已存在同样的店铺名称"}
    
    // =========================================================================    
    var shop = $resource("/shop/:operation/:id",
    			 {operation: '@operation', id: '@id'});
    // var members = $resource("/member/:operation/:number");

    this.list = function(){
	return shop.query({operation: "list_shop"})};

    this.query = function(shop_id){
	return shop.get(
	    {operation: "get_shop", id: shop_id}
	)};

    this.add = function(ashop){
	return shop.save(
	    {operation: "new_shop"},
	    {name:      ashop.name,
	     address:   ashop.address,
	     shopowner: ashop.shopowner,
	     open_date: dateFilter(ashop.openDate, "yyyy-MM-dd")
	    }
	)};

    this.destroy = function(ashop){
	return shop.delete(
	    {operation: "delete_shop", id: ashop.id}
	)} ;

    this.edit = function(ashop){
	return shop.save(
	    {operation: "update_shop", id: ashop.id},
	    {shopowner:      ashop.shopowner}
	)};
    
});

shopApp.controller(
    "newShopCtrl",
    function($scope, shopService, employService){
	// employees
	employService.list().$promise.then(function(employees){
	    // console.log(employees);
	    $scope.employees = employees
	})
	
	// canlender
	$scope.open_calendar = function(event){
	    event.preventDefault();
	    event.stopPropagation();
	    $scope.isOpened = true; 
	}

	$scope.shop = {};
	$scope.new_shop = function(){
	    if ($scope.hasOwnProperty('selectedEmploy')) {
		$scope.shop.shopowner = $scope.selectedEmploy.id;
	    }
	    console.log($scope.shop);
	    shopService.add($scope.shop).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    $scope.newShopResponse = function(){
			$scope.response_success_info = "恭喜你，店铺 " + $scope.shop.name + " 成功创建";
			return true
		    };
		    
		    $scope.afterResponse = function(){
    			location.href = "#/shop/shop_detail";
    		    };
		    
		} else{
		    $scope.newShopResponse = function(){
			$scope.response_error_info = shopService.error[state.ecode];
			return false
		    };
		}
	    })};
	
	$scope.cancel_new_shop = function(){
	    location.href = "#/shop/shop_detail";
	};	
    });


shopApp.controller(
    "shopDetailCtrl",
    function($scope, $routeParams, ngTableUtils, shopService, employService){
	// employees
	employService.list().$promise.then(function(employees){
	    // console.log(employees);
	    $scope.employees = employees
	})
	
	
	// filter
	$scope.filter = {name: '',  owner: ''};

	// list
	shopService.list().$promise.then(function(shops){
	    console.log(shops);
            $scope.shopTable =
		ngTableUtils.tbl_of_filter_and_sort(shops, $scope.filter, {id: 'desc'});
	});
	
	
	$scope.goto_page = function(path){
	    window.location = path;
	};

	// edit
	$scope.edit_shop = function(shop){
	    // console.log(shop);
	    $scope.selectedEditShop = shop;
	};

	$scope.edit_shop_request = function(shop){
	    shop.shopowner = $scope.employ.id;
    	    // console.log(member);
    	    shopService.edit(shop).$promise.then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
    		    $scope.editShopResponse = function(){
    			$scope.response_success_info = "恭喜你，店铺 " + shop.name + " 信息修改成功";
    			return true
    		    };
		    $scope.afterEditResponse = function(){
    			location.reload();
    		    };
    		    // window.location = '#/vmOpList';
    		} else{
    		    $scope.editShopResponse = function(){
    			$scope.response_error_info = shopService.error[state.ecode];
    			return false
    		    }
    		}
    	    })};

	// delete shop
	$scope.set_delete_shop = function(shop){
	    $scope.selectedDeleteShop = shop;
	};
	$scope.shop_delete_submit = function(){
	    console.log($scope.selectedDeleteShop);
	    shopService.destroy($scope.selectedDeleteShop).$promise
		.then(function(state){
    		    console.log(state);
    		    if (state.ecode == 0){
    			$scope.delete_response = function(){
    			    $scope.response_success_delete_info = "恭喜你，店铺 "
				+ $scope.selectedDeleteShop.name + " 删除成功";
    			    return true;
    			};
			$scope.after_delete_response = function(){
    			    location.reload();
    			};
    		    } else{
    			$scope.delete_response = function(){
    			    $scope.response_error_delete_info = shopService.error[state.ecode];
    			    return false;
    			}
    		    }
    		})
	};
	
    });



shopApp.controller(
    "shopCtrl",
    function($scope){
	
    });



