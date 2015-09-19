var supplierApp = angular.module(
    'supplierApp', ['ui.bootstrap', 'ngRoute',
		    'ngResource', 'ngTable', 'diabloAuthenApp',
		    'diabloPattern', 'diabloUtils'])
    .config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

supplierApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
	when('/supplier/supplier_detail', {
	    templateUrl: '/private/supplier/html/supplier_detail.html',
            controller: 'supplierDetailCtrl'
	}).
	when('/supplier/supplier_new', {
	    templateUrl: '/private/supplier/html/supplier_new.html',
            controller: 'supplierNewCtrl'
	}). 
	when('/brand/brand_detail', {
	    templateUrl: '/private/supplier/html/brand_detail.html',
            controller: 'brandDetailCtrl'
	}).
	when('/brand/brand_new', {
	    templateUrl: '/private/supplier/html/brand_new.html',
            controller: 'brandNewCtrl'
	}).
	otherwise({
	    templateUrl: '/private/supplier/html/supplier_detail.html',
            controller: 'supplierDetailCtrl'
            // templateUrl: '/private/member/html/member_index.html',
            // controller: 'memberCtrl'
        })
}]);


supplierApp.service("supplierService", function($resource, dateFilter){    
    // error information
    this.error = {
	1602: "供应商创建失败，已存在同样的供应商"};

    // =========================================================================    
    var supplier = $resource("/supplier/:operation/:id",
    			     {operation: '@operation', id: '@id'});
    
    this.list = function(){
	return supplier.query({operation: "list_supplier"})};

    this.query = function(supplierId){
	return supplier.get(
	    {operation: "get_supplier", id: supplierId}
	)};

    this.add = function(one){
	console.log(one);
	return supplier.save(
	    {operation: "new_supplier"},
	    {name:      one.name,
	     mobile:    one.mobile,
	     address:   one.address
	    }
	)};

    this.destroy = function(one){
	return supplier.delete(
	    {operation: "delete_supplier", id: one.id}
	)};

    this.edit = function(one){
	return supplier.save(
	    {operation: "update_supplier", id: one.id},
	    {mobile:    one.mobile}
	)};

    this.new_brand = function(brand){
	return supplier.save(
	    {operation: "new_brand"},
	    {name:     brand.name,
	     supplier: brand.supplier})
    };

    this.connect_brand = function(brand){
	return supplier.save(
	    {operation: "connect_brand"},
	    {brand:     brand.brand,
	     supplier:  brand.supplier})
    };

    this.list_brand = function(){
	return supplier.query({operation: "list_brand"})
    };

    this.list_unconnect_brand = function(){
	return supplier.query({operation: "list_unconnect_brand"})
    };
});


supplierApp.controller(
    "supplierDetailCtrl",
    function($scope, $routeParams, ngTableUtils, supplierService){
	// filters segment
	$scope.filter = {name: '', mobile: ''};

	// list
	supplierService.list().$promise.then(function(supplierees){
            $scope.supplierTable =
		ngTableUtils.tbl_of_filter_and_sort(supplierees, $scope.filter, {id: 'desc'});
	});
	
	
	$scope.goto_page = function(path){
	    window.location = path;
	};
	

	// edit
	$scope.supplier = {};
	$scope.edit_supplier = function(supplier){
	    console.log(supplier);
	    $scope.supplier = supplier;
	};

	$scope.edit_supplier_request = function(supplier){
    	    // console.log(supplier);
    	    supplierService.edit(supplier).$promise.then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
    		    $scope.editSupplierResponse = function(){
    			$scope.response_success_info =
			    "恭喜你，供应商 " + supplier.name + " 信息修改成功";
    			return true
    		    };
		    $scope.afterEditResponse = function(){
    			location.reload();
    		    };
    		} else{
    		    $scope.editSupplierResponse = function(){
    			$scope.response_error_info = supplierService.error[state.ecode];
    			return false
    		    }
    		}
    	    })};

	// delete
	$scope.set_delete_supplier = function(supplier){
	    console.log(supplier);
	    $scope.selectedDeleteSupplier = supplier;
	};
	$scope.supplier_delete_submit = function(){
	    // console.log($scope.selectedDeleteSupplier);
	    supplierService.destroy($scope.selectedDeleteSupplier).$promise
		.then(function(state){
    		    console.log(state);
    		    if (state.ecode == 0){
    			$scope.delete_response = function(){
    			    $scope.response_success_delete_info = "恭喜你，供应商 "
				+ $scope.selectedDeleteSupplier.name + " 删除成功";
    			    return true;
    			};
			$scope.after_delete_response = function(){
    			    location.reload();
    			};
    		    } else{
    			$scope.delete_response = function(){
    			    $scope.response_error_delete_info = supplierService.error[state.ecode];
    			    return false;
    			}
    		    }
    		})
	};	
    });

supplierApp.controller(
    "supplierNewCtrl",
    function($scope, supplierService, diabloPattern){
	$scope.supplier = {};
	$scope.telOrMobilePattern = diabloPattern.telOrMobile;
	// console.log($scope.telOrMobilePattern);
	// new merchant
	$scope.new_supplier = function(){
	    supplierService.add($scope.supplier).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    $scope.newSupplierResponse = function(){
			$scope.response_success_info
			    = "恭喜你，供应商 " + $scope.supplier.name + " 成功创建";
			return true
		    };
		    
		    $scope.afterResponse = function(){
    			location.href = "#/supplier/supplier_detail";
    		    };
		    
		} else{
		    $scope.newSupplierResponse = function(){
			$scope.response_error_info = supplierService.error[state.ecode];
			return false
		    };
		}
	    })};
	
	$scope.cancel = function(){
	    location.href = "#/supplier/supplier_detail";
	};
	
    });


supplierApp.controller(
    "brandNewCtrl",
    function($scope, supplierService, diabloUtilsService){
	// get suppliers
	supplierService.list().$promise.then(function(suppliers){
	    console.log(suppliers);
	    $scope.suppliers = suppliers
	});

	supplierService.list_unconnect_brand().$promise.then(function(brands){
	    console.log(brands);
	    // diablo_order(brands);
	    $scope.unConnectBrands = brands;
	});

	$scope.new_brand = function(brand){
	    console.log(brand);
	    supplierService.new_brand({name:brand.name, supplier:brand.supplier.id}).
		$promise.then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			window.location = "#/brand/brand_detail";
		    } else{
			diabloUtilsService.response(
			    false, "新增品牌", "新增品牌" + brand.name + "失败", $scope);
		    }
		});
	    //diabloUtilsService.response(true, "aaa", "bbb", $scope);
	};

	$scope.connect_brand = function(brand){
	    console.log(brand);
	    supplierService.connect_brand({brand:brand.brand.id, supplier:brand.supplier.id}).
		$promise.then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			window.location = "#/brand/brand_detail";
		    } else{
			diabloUtilsService.response(
			    false, "关联品牌", "关联品牌" + brand.name + "失败", $scope);
		    }
		});
	    //diabloUtilsService.response(true, "aaa", "bbb", $scope);
	};

	$scope.cancel = function(){
	    window.location = "#/brand/brand_detail";
	}
    });


supplierApp.controller(
    "brandDetailCtrl",
    function($scope, supplierService, diabloUtilsService){
	// filters segment
	$scope.filter = {name: '', supplier:''};

	// list
	supplierService.list_brand().$promise.then(function(brands){
	    console.log(brands);
	    diablo_order(brands);
            $scope.brands = brands;
	});
	
	
	$scope.goto_page = function(path){
	    window.location = path;
	};
    });

supplierApp.controller("supplierCtrl", function($scope){});

supplierApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});






