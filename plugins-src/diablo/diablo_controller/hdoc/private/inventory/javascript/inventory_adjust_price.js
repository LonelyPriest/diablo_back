inventoryApp.controller(
    "inventoryAdjustPriceCtrl",
    function($scope, $http, inventoryService, supplierService,
	     diabloUtilsService, diabloPagination, user){
	
	// shop
	$scope.prompt_shops = [];
	angular.forEach(user.shop, function(s){
	    $scope.prompt_shops.push({name :s.name, id :s.shop_id});
	});
	
	// supplier and brand
	$scope.prompt_suppliers = [];
	supplierService.list().$promise.then(function(suppliers){
	    // console.log(suppliers);
	    angular.forEach(suppliers, function(s){
		$scope.prompt_suppliers.push({name :s.name, id :s.id});
	    })
	});
	
	$scope.prompt_brands = [];
	inventoryService.brands().$promise.then(function(brands){
	    console.log(brands);
	    angular.forEach(brands, function(brand){
	    	$scope.prompt_brands.push({name :brand.name, id :brand.id});
	    });
	});

	// style_number
	$scope.prompt_numbers = [];
	inventoryService.get_style_numbers().then(function(numbers){
	    angular.forEach(numbers, function(number){
		$scope.prompt_numbers.push(number.style_number)
	    })
	});
	
	$scope.prompt = {
	    shop         :$scope.prompt_shops,
	    brand        :$scope.prompt_brands,
	    style_number :$scope.prompt_numbers,
	    supplier     :$scope.prompt_suppliers
	};
	
	$scope.menu_items =
	    [{name:"by_number",   chinese: "按款号",  field: "style_number"},
	     {name:"by_shop",     chinese: "按店铺",  field: "shop"},
	     {name:"by_brand",    chinese: "按品名",  field: "brand"},
	     {name:"by_supplier", chinese: "按供应商",field: "supplier"}];

	$scope.invalidInventoy = true;

	var list_with_condtion = function(condition){
	    console.log(condition);
	    inventoryService.list_with_condtion(condition).$promise.then(function(data){
		console.log(data);
		$scope.invalidInventoy = data.length > 0 ? false : true;
		// $scope.inventories = data;		
		diablo_format_year(data);
		diablo_order(data);

		// pagination
		$scope.currentPage = 1;
		$scope.itemsPerpage = 5;
		// $scope.itemsPerpage = diabloPagination.get_itmes_perpage();
		diabloPagination.set_data(data);
		diabloPagination.set_items_perpage($scope.itemsPerpage);
		
		$scope.totalItems = diabloPagination.get_length();
		$scope.page_changed(1);		
	    })
	};
	
	$scope.on_select = function(item, model, label){
	    // console.log(model);
	    var f = $scope.filter;
	    $scope.condition =
		{name: f.item.field,
		 value: typeof(f.value) === 'object' ? f.value.id : f.value};
	    list_with_condtion($scope.condition);
	};

	$scope.season = diablo_season;
	$scope.sex    = diablo_sex;

	$scope.page_changed = function(currentPage){
	    console.log(currentPage);
	    $scope.inventories = diabloPagination.get_page(currentPage);
	};

	$scope.refresh = function(){
	    if (angular.isDefined($scope.condition)
		&& !diablo_is_empty($scope.condition)){
		list_with_condtion($scope.condition);
	    }
	}

	// $scope.items_changed = function(){
	//     console.log($scope.currentPage);
	//     $scope.inventories = diabloPagination.get_page($scope.currentPage)
	// };

	/*
	 * adjust 
	 */
	$scope.adjust_price = function(){	    
	    console.log($scope.adjust);	    
	    console.log($scope.condition);

	    var callback = function(adjust){
		inventoryService.adjust_price(adjust).$promise.then(function(state){
	    	    console.log(state);
		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "调价", "调价成功！！", $scope,
			    function(){list_with_condtion($scope.condition)});
		    } else{
			diabloUtilsService.response(
			    false, "调价",
			    "调价失败：" + inventoryService.error[state.ecode], $scope);
		    }
	    	})
	    };

	    if (angular.isDefined($scope.adjust.price) && $scope.adjust.price){
		var body =  "调整后价格：" + $scope.adjust.price + "，确定要调整吗？";
	    }

	    if (angular.isDefined($scope.adjust.discount) && $scope.adjust.discount){
		var body =  "调整后折扣：" + $scope.adjust.discount + "，确定要调整吗？";
	    }

	    $scope.adjust.style = $scope.condition;
	    diabloUtilsService.request("调价", body, callback, $scope.adjust, $scope);
	};

    }
);
