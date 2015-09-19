saleApp.controller(
    "detailCtrl",
    function($scope, $routeParams, dateFilter, ngTableUtils,
	     saleService, employService, inventoryService, user){
	// console.log(user);
	// shop to allowed to sale

	$scope.season = diablo_season;
	$scope.sex    = diablo_sex;	
	
	// var allowedShops = rightAction.get_allowed_sale_shops(user.shop);
	
	// var shopIds = [];
	// $scope.prompt_shops = [];
	// var order_id = 1;
	// angular.forEach(allowedShops, function(shop){
	//     shopIds.push(shop.shop_id);
	//     $scope.prompt_shops.push(
	// 	{name :shop.name, id :shop.shop_id, order_id :order_id});
	//     order_id++;
	// });

	/*
	 * prompt
	 */	
	// supplier
	// $scope.prompt_suppliers = [];
	// supplierService.list().$promise.then(function(suppliers){
	//     angular.forEach(suppliers, function(s){
	// 	$scope.prompt_suppliers.push({name :s.name, id :s.id});
	//     })
	// });

	// brands
	$scope.prompt_brands = [];
	inventoryService.brands().$promise.then(function(brands){
	    // console.log(brands);
	    order_id = 1;
	    angular.forEach(brands, function(brand){
	    	$scope.prompt_brands.push(
		    {name :brand.name, id :brand.id, order_id: order_id});
		order_id++;
	    });
	});

	// style_number
	$scope.prompt_numbers = [];
	inventoryService.get_style_numbers().then(function(numbers){
	    angular.forEach(numbers, function(number){
		$scope.prompt_numbers.push(number.style_number)
	    })
	});
	
	// colors
	$scope.prompt_colors = [];
	inventoryService.colors().$promise.then(function(colors){
	    // console.log(colors);
	    order_id = 1;
	    angular.forEach(colors, function(color){
	    	$scope.prompt_colors.push(
		    {name :color.name, id :color.id, order_id: order_id});
		order_id++;
	    })
	});

	// size group
	$scope.prompt_sizes = [];
	inventoryService.list_size_group().$promise.then(function(groups){
	    // console.log(groups);
	    angular.forEach(groups, function(group){
		for (var key in group){
		    if (typeof(group[key]) === "function" || key === "id"){
			continue;
		    } 
		    $scope.prompt_sizes.push(group[key])
		};
	    });
	    // console.log($scope.prompt_sizes);
	});

	// director
	$scope.prompt_directors = [];
	employService.list().$promise.then(function(employees){
	    console.log(employees);
	    angular.forEach(employees, function(e){
	    	$scope.prompt_directors.push(
		    {name: e.name, id: e.id, employ: e.number});
	    })
	});
	
	// ordered
	var order_inventories = function(invs){
	    var inc = (($scope.currentPage - 1) * $scope.itemsPerpage) + 1;
	    angular.forEach($scope.inventories, function(inv){
		inv.order_id = inc;
		inc++;
	    });

	};

	$scope.colspan = 18;
	$scope.itemsPerpage = 5;
	$scope.currentPage  = 1;

	
	// default list
	saleService.sale_detail(
	    parseInt($routeParams.shopId), $scope.currentPage, $scope.itemsPerpage)
	    .$promise.then(function(result){
		console.log(result);
		$scope.totalItems = result.total;
		$scope.inventories = result.data;
		order_inventories($scope.inventories);
	    });

	// paging
	$scope.page_changed = function(){
	    if (angular.isUndefined($scope.search)
		|| diablo_is_empty($scope.search)){
		saleService.sale_detail(
		    parseInt($routeParams.shopId), $scope.currentPage, $scope.itemsPerpage)
		    .$promise.then(function(result){
			//console.log(invs);
			$scope.inventories = result.data;
			order_inventories($scope.inventories);
		    });
	    } else{
		// filter
		saleService.filter_sale(
		    $scope.pattern.match, $scope.search,
		    $scope.currentPage, $scope.itemsPerpage)
		    .$promise.then(function(result){
			console.log(result);
			$scope.inventories = result.data
			order_inventories($scope.inventories);
		    })
	    };
	}
	
	
	/*
	 * filter
	 */
	// canlendar
	$scope.open_calendar = function(event){
	    event.preventDefault();
	    event.stopPropagation();
	};

	// one filter
	$scope.filter = {};
	$scope.filter.fields = [
	    {name:"running_no", chinese: "流水号"},
	    {name:"style_number", chinese:"款号"},
	    {name:"brand", chinese:"品名"},
	    {name:"color", chinese:"颜色"},
	    {name:"year", chinese:"年度"},
	    {name:"season", chinese:"季节"},
	    {name:"size", chinese:"尺码"},
	    {name:"employ", chinese:"导购员"},
	    // {name:"shop", chinese:"店铺"}
	    // {name:"supplier", chinese:"供应商"}
	];

	$scope.prompts = {
	    style_number :$scope.prompt_numbers,
	    brand        :$scope.prompt_brands,
	    color        :$scope.prompt_colors,
	    size         :$scope.prompt_sizes,
	    season       :diablo_season2objects,
	    employ       :$scope.prompt_directors
	    // shop         :$scope.prompt_shops,
	    // supplier     :$scope.prompt_suppliers
	};
	

	// initial, has only one filter
	$scope.pattern = {};
	$scope.filters = [angular.copy($scope.filter)];
	$scope.increment = 0;
	$scope.filter_nums = [0];

	// add a filter
	$scope.add_filter = function(){
	    $scope.increment++;
	    $scope.filter_nums.push($scope.increment);
	    // add filter
	    $scope.filters[$scope.increment] = angular.copy($scope.filter);
	};

	// delete a filter
	$scope.del_filter = function(){
	    $scope.increment--;
	    $scope.filter_nums.splice(-1, 1);
	    $scope.filters.splice(-1, 1);
	};

	$scope.$watch('filters', function(newValue, oldValue){
	    // console.log(newValue);
	    // console.log(oldValue);
	    if (angular.equals(newValue, oldValue)){return};
	    
	    // get field
	    $scope.search = {};
	    angular.forEach($scope.filters, function(f){
		if (angular.isDefined(f.value) && f.value !== ""){
		    var value = null;
		    if (typeof(f.value) === 'object'){
			value = f.value.id
		    } else{
			value = f.value
		    }
		    // repeat
		    if ($scope.search.hasOwnProperty(f.field.name)){
			var old = [].concat($scope.search[f.field.name]);
			if (!in_array(old, value)){
			    $scope.search[f.field.name] = old.concat(value);
			}
		    } else{
			$scope.search[f.field.name] = value;
		    }
		}
	    });
	    
	}, true);

	// $scope.searchTime = {};
	$scope.$watch('searchTime', function(newValue, oldValue){
	    // console.log(newValue);
	    // console.log(oldValue);
	    if (angular.equals(newValue, oldValue)){return};
	    if (angular.isDefined($scope.searchTime.startTime)
		&& $scope.searchTime.startTime !== null){
		
		$scope.search.start_time
		    = dateFilter($scope.searchTime.startTime, "yyyy-MM-dd");
	    };
	    if (angular.isDefined($scope.searchTime.endTime)
		&& $scope.searchTime.endTime !== null){
		// console.log($scope.search.end_time);
		var fullTime = $scope.searchTime.endTime.getTime();
		// end time should add a day
		$scope.search.end_time
		    = dateFilter(fullTime + 86400 * 1000, "yyyy-MM-dd");
	    };
	    // console.log($scope.search);
	}, true);


	// do filter
	$scope.do_search = function(){
	    // console.log($scope.pattern);
	    // console.log($scope.filters);
	    if (diablo_is_empty($scope.search)){
		return;
	    }

	    // match
	    // var match = $scope.pattern.match;
	    // default the first page
	    $scope.currentPage = 1;
	    saleService.filter_sale(
		$scope.pattern.match, $scope.search,
		$scope.currentPage, $scope.itemsPerpage)
		.$promise.then(function(invs){
		    console.log(invs);
		    $scope.totalItems = invs.total
		    // console.log($scope.totalItems);
		    $scope.inventories = invs.data;
		    order_inventories($scope.inventories);
		});
	    
	};

	
    });
