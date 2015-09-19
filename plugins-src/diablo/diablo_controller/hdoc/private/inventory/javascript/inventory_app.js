var inventoryApp = angular.module(
    "inventoryApp", ['ngRoute', 'ngResource',
		     'ui.bootstrap', 'datatables',
		     'ngTable', 'ngTableUtils',
		     'diabloUtils', 'subbmitNotify',
		     'supplierApp', 'userApp']);

// inventoryApp.directive("selfInit", function(){
//     return{
//	priority: -1,
//	link: function(scope, element, attr){
//	    attr.$observe("init", function(){
//		scope.init();
//	    })
//	}
//     }
// })

inventoryApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
	when('/inventory_detail/:shopId', {
	    templateUrl: '/private/inventory/html/inventory_detail.html',
	    controller: 'inventoryDetailCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	}).
	when('/inventory_new/:shopId', {
	    templateUrl: '/private/inventory/html/inventory_new.html',
	    controller: 'inventoryNewCtrl'
	}).
	when('/inventory_check/:shopId', {
	    templateUrl: '/private/inventory/html/inventory_check.html',
	    controller: 'inventoryCheckCtrl'
	}).
	when('/inventory_move/move', {
	    templateUrl: '/private/inventory/html/inventory_move.html',
	    controller: 'inventoryMoveCtrl'	    
	    // resolve: {
	    // 	"user": function(userService){
	    // 	    return userService();
	    // 	}
	    // }
	}).
	when('/inventory_move/detail', {
	    templateUrl: '/private/inventory/html/inventory_move_detail.html',
	    controller: 'inventoryMoveDetailCtrl'
	}).
	when('/inventory_im/import', {
	    templateUrl: '/private/inventory/html/inventory_import.html',
	    controller: 'inventoryImportCtrl'
	}).
	when('/inventory_im/export', {
	    templateUrl: '/private/inventory/html/inventory_export.html',
	    controller: 'inventoryExportCtrl'
	}).
	when('/adjust_price', {
	    templateUrl: '/private/inventory/html/inventory_adjust_price.html',
	    controller: 'inventoryAdjustPriceCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	}).
	when('/size_group', {
	    templateUrl: '/private/inventory/html/size_group_detail.html',
	    controller: 'inventorySizeGroupCtrl'
	}).
	when('/inventory_reject/reject', {
	    templateUrl: '/private/inventory/html/inventory_reject.html',
	    controller: 'inventoryRejectCtrl'
	}).
	when('/inventory_reject/detail', {
	    templateUrl: '/private/inventory/html/inventory_reject_detail.html',
	    controller: 'inventoryRejectDetailCtrl'
	}).	
	otherwise({
	    templateUrl: '/private/inventory/html/inventory_detail.html',
	    controller: 'inventoryDetailCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	    // templateUrl: '/private/member/html/member_index.html',
	    // controller: 'memberCtrl'
	})
}]);

// inventoryApp.factory('authHttpResponseInterceptor',['$q','$location',function($q,$location){
//     return {
//         response: function(response){
//             if (response.status === 401) {
//                 console.log("Response 401");
//             }
//             return response || $q.when(response);
//         },
//         responseError: function(rejection) {
// 	    console.log(rejection);
//             if (rejection.status === 401) {
//                 console.log("Response Error 401",rejection);
//                 $location.path('/login').search('returnTo', $location.path());
//             }
//             return $q.reject(rejection);
//         }
//     }
// }]).config(['$httpProvider',function($httpProvider) {
//     //Http Intercpetor to check auth failures for xhr requests
//     $httpProvider.interceptors.push('authHttpResponseInterceptor');
// }]);

inventoryApp.service("inventoryService", function($resource, $q, $modal, dateFilter){
    this.sex = function(){
	return diablo_sex;
    }

    this.season = function(){
	return diablo_season;
    }

    this._sex2number = function(sex){
	return diablo_sex2number(sex);
    };

    this._season2number = function(season){
	return diablo_season2number(season);
    };

    // dialog
    this.show_dialog = function(result, title, body, scope){
	return $modal.open({
	    templateUrl: '/private/utils/html/modalResponse.html',
	    controller: 'inventoryResponseCtrl',
	    backdrop: 'static',
	    scope: scope,
	    resolve:{
		message: function(){
		    return {
			success: result,
			title: title,
			body: body
		    }
		}
	    }
	})
    };

    // error
    this.error = {1703: "库存增加失败，已存在同样的库存",
		  9001: "数据库操作失败，请联系服务人员",
		  6001: "没有尺码需要修改"};

    // =========================================================================

    /**
    var deferred = $q.defer();
    var promise = deferred.promise;

    promise.then(function success(data) {
	console.log(data);
    }, function error(error) {
	console.error(error);
    }, function notification(notification) {
	console.info(notification);
    });

    var progress = 0;
    var interval = $interval(function() {
	if (progress >= 100) {
	    $interval.cancel(interval);
	    deferred.resolve('All done!');
	}
	progress += 10;
	deferred.notify(progress + '%...');
    }, 100);
    **/

    var inventory = $resource(
	"/inventory/:operation/:id", {operation: '@operation', id: '@id'},
	{
	    list_by_style_number_and_shop: {method: 'POST', isArray:true},
	    list_by_group       :{method: 'POST', isArray:true},
	    list_inventory      :{method: 'POST', isArray:true},
	    list_by_pagination  :{method: 'POST', isArray:true},
	    total_by_pagination :{method: 'POST', isArray:false},
	    filter_inventory    :{method: 'POST', isArray:false}
	    // query: {method: 'GET', isArray:true,
	    // 	    interceptor: {
	    // 		responseError: function(data){
	    // 		    console.log(data);
	    // 		    console.log('error in interceptor', data)}}
	    // 	   }
	}
    );

    this.list_by_style_number = function(styleNumber){
	return inventory.query(
	    {operation: "list_by_style_number", id:styleNumber}).$promise;
    }

    this.list_by_style_number_and_shop = function(style_number, shop){
	return inventory.list_by_style_number_and_shop(
	    {operation: "list_by_style_number_and_shop"},
	    {style_number: style_number,
	     shop:         shop}).$promise;
    }

    this.list_by_group = function(group){
	return inventory.list_by_group(
	    {operation: "list_inventory_by_group"},
	    {style_number :group.style_number,
	     brand        :group.brand,
	     shop         :group.shop}
	).$promise;
    }

    this.get_style_numbers = function(){
	return inventory.query(
	    {operation: "list_style_number"}).$promise;
    }

    this.get_style_numbers_of_shop = function(shop){
    	return inventory.query(
    	    {operation: "list_style_number_of_shop", id:shop}).$promise;
    }

    this.list_all = function(){
	return inventory.query({operation: "list_inventory"})
    };

    this.list = function(shopId){
	if (angular.isUndefined(shopId)){
	    return this.list_all();
	} else{
	    return inventory.query(
		{operation: "list_inventory", id: shopId})
	}
    };

    this.list_with_condtion = function(condition){
	return inventory.list_inventory(
	    {operation: "list_inventory_with_condition"},
	    {name: condition.name, value: condition.value});
    };

    /*
     * begin to pagination function
     */
    this.list_by_pagination = function(shopId, currentPage, countPerPage){
	var settings = {};
	settings.page = currentPage;
	settings.count = countPerPage;
	if (angular.isDefined(shopId)){
	    settings.shop = shopId;
	};
	
	return inventory.list_by_pagination(
	    {operation: "list_by_pagination"}, settings)
    };

    this.total_inventories = function(shopId){
	if (angular.isUndefined(shopId)){
	    return inventory.total_by_pagination({operation: "get_total_inventories"});
	} else{
	    return inventory.total_by_pagination(
		{operation: "get_total_inventories"}, {shop: shopId});
	}
    };

    this.list_pagination_default = function(shopId, countPerPage){
	var get_total = function(){
	    var defer = $q.defer();
	    this.total_inventories(shopId).$promise.then(function(totals){
		defer.resolve(totals);
	    });
	    return defer.promise;
	};

	var get_default_pagination = function(){
	    var defer = $q.defer();
	    this.list_by_pagination(shopId, 1, countPerPage).$promise.then(function(invs){
		defer.resolve(invs);
	    });
	    return defer.promise;
	};

	return $q.all([
	    get_total.call(this),
	    get_default_pagination.call(this, shopId, countPerPage)]);
    };

    /*
     * end to pagination function
     */


    /*
     * do filter
     */
    this.do_filter_by_pagination = function(pattern, fields, currentPage, countPerPage){
	return inventory.filter_inventory(
	    {operation: "filter_inventory"},
	    {pattern: pattern.op,
	     fields:  fields,
	     page:    currentPage,
	     count:   countPerPage})
    };

    // this.total_inventorire_of_filter = function(pattern, fields){
    // 	return inventory.filter_inventory(
    // 	    {operation: "get_total_inventories_of_filter"},
    // 	    {pattern: pattern.op,
    // 	     fields:  fields}
    // 	)
    // };    

    this.colors = function(){
	return inventory.query({operation: "list_color"})
    };

    this.brands = function(){
	return inventory.query({operation: "list_brand"})
    };

    this.types = function(){
	return inventory.query({operation: "list_type"})
    };

    // this.sizes = function(shop){
    // 	return inventory.query({operation: "list_size", id:shop}).$promise;
    // };

    this.get = function(number){
	return inventory.get(
	    {operation: "get_inventory", id: shop_id}
	)};

    this.add = function(ainventory){
	return inventory.save(
	    {operation: "new_inventory"},
	    {brand:      ainventory.brand,
	     number:     ainventory.number,
	     type:       ainventory.inv_type,
	     color:      ainventory.color,
	     price:      ainventory.price,
	     discount:   ainventory.discount,
	     year:       ainventory.year,
	     season:     ainventory.season.id,
	     sex:        ainventory.sex.id,
	     supplier:   ainventory.brand.supplier_id,
	     // size_group: ainventory.group.id,
	     amount:     ainventory.amount,
	     shop:       ainventory.shop
	    }
	)};

    this.destroy = function(ainventory){
	return inventory.delete(
	    {operation: "delete_inventory", id: ainventory.id})
    };

    this.update_inventory = function(ainventory){
	return inventory.save({operation: "update_inventory"}, ainventory).$promise;
    };

    /*
     * size group
     */
    this.add_size_group = function(group){
	return inventory.save(
	    {operation: "new_size_group"},
	    {name:   group.name,
	     si:     group.si,
	     sii:    group.sii,
	     siii:   group.siii,
	     siv:    group.siv,
	     sv:     group.sv,
	     svi:    group.svi})
    };

    this.modify_size_group = function(group){
	return inventory.save(
	    {operation: "update_size_group"},
	    {si:     group.si,
	     sii:    group.sii,
	     siii:   group.siii,
	     siv:    group.siv,
	     sv:     group.sv,
	     svi:    group.svi,
	     gid:    group.id}
	)
    };

    this.delete_size_group = function(gid){
	return inventory.save(
	    {operation: "del_size_group"},
	    {gid: gid}
	)
    };

    this.list_size_group = function(){
	return inventory.query({operation: "list_size_group"})
    };

    /*
     * check inventory
     */
    this.check_inventory = function(inv){
    	return inventory.save({operation: "check_inventory"}, inv).$promise;
    };

    this.list_unchecked_inventory_group = function(shopId){
	return inventory.list_inventory(
	    {operation: "list_unchecked_inventory_group"},{shop: shopId}).$promise
    };

    
    this.list_shop = function(){
	return inventory.query({operation: "list_shop"})
    };

    /*
     *move inventory from one shop to another
     */
    // prepare
    this.pre_move_inventory = function(inv){
	return inventory.save({operation: "move_inventory"},
			      {sn: inv.sn,
			       style_number: inv.style_number,
			       source: inv.source,
			       target: inv.target,
			       amount: inv.amount
			      })
    };
    
    this.list_move_inventory = function(){
	//return $http.get("/inventory/list_moves_inventory");
	return inventory.query({operation: "list_move_inventory"})
    };

    this.do_move = function(inv){
	return inventory.save(
	    {operation: "do_move_inventory"},
	    {sn     :inv.sn,
	     target :inv.target,
	     amount :inv.amount
	    })
    };

    /*
     * reject
     */
    this.reject_inventory = function(inv){
	return inventory.save({operation: "reject_inventory"},
			      {sn: inv.sn,
			       style_number: inv.style_number,
			       shop:   inv.shop,
			       amount: inv.amount
			      })
    };

    this.list_reject_inventory = function(){
	return inventory.query({operation: "list_reject_inventory"})
    };

    /*
     * adjust price
     */
    this.adjust_price = function(adjust){
	var payload = {};
	if (angular.isDefined(adjust.price) && adjust.price){
	    payload.price = parseFloat(adjust.price);
	}
	if (angular.isDefined(adjust.discount) && adjust.discount){
	    payload.discount = parseInt(adjust.discount);
	}
	payload.style = adjust.style;
	return inventory.save(
	    {operation: "adjust_price"}, payload);
    };
});


inventoryApp.controller(
    "inventoryResponseCtrl", function($scope, $modalInstance, message){
	// console.log($scope);
	console.log(message);
	
	$scope.success = message.success;
	$scope.title = message.title;
	$scope.body  = message.body;
	
	$scope.cancel = function(){
	    $modalInstance.dismiss('cancel');
	    // console.log($modalInstance);
	};

	$scope.ok = function() {
	    $modalInstance.dismiss('ok');
	    if (angular.isDefined($scope.$parent.after_delete_response)){
		$scope.$parent.after_response()
	    }
	};
    });

inventoryApp.controller(
    "inventoryNewCtrl",
    function($scope, $routeParams, dateFilter, diabloUtilsService,
	     inventoryService, supplierService){
	// console.log($routeParams);

	// add record
	$scope.chinesePattern = "/[^u4e00-u9fa5]/";
	// $scope.form = {};
	// $scope.inventory = {};
	
	// get all suppliers
	// supplierService.list().$promise.then(function(suppliers){
	//     console.log(suppliers);
	//     $scope.suppliers = suppliers;
	//     $scope.inventory.supplier = suppliers[0];	    
	// });

	// size group
	inventoryService.list_size_group().$promise.then(function(groups){
	    console.log(groups);
	    $scope.size_groups = groups;
	});

	// style numbers to prompt
	$scope.prompt_numbers = [];
	inventoryService.get_style_numbers().then(function(numbers){
	    angular.forEach(numbers, function(number){
		$scope.prompt_numbers.push(number.style_number);
	    });
	})
	
	// colors to prompt
	$scope.prompt_colors = [];
	inventoryService.colors().$promise.then(function(colors){
	    console.log(colors);
	    angular.forEach(colors, function(color){
	    	$scope.prompt_colors.push(
	    	    {id:color.id, name:color.name});
	    });
	});

	// brands to prompt
	$scope.prompt_brands = [];
	inventoryService.brands().$promise.then(function(brands){
	    console.log(brands);
	    brands = diablo_order(brands);
	    angular.forEach(brands, function(brand){
	    	$scope.prompt_brands.push({
		    order_id: brand.order_id, name: brand.name});
	    });
	})

	// types to prompt
	$scope.prompt_types = [];
	inventoryService.types().$promise.then(function(inv_types){
	    inv_types = diablo_order(inv_types);
	    angular.forEach(inv_types, function(type){
	    	$scope.prompt_types.push(
	    	    {order_id:type.order_id, name:type.name});
	    });
	})
	
	// sex
	$scope.seasons = diablo_season2objects;
	// season
	$scope.sexs =  diablo_sex2object;
	
	// default always can be edit, also is a new record
	var in_prompts = function(prompts, item){
	    for(var i=0, l=prompts.length; i<l; i++){
		if (prompts[i].name === item){
		    return true;
		}
	    };
	    return false;
	};
	
	$scope.inventories = [{$editable: false, $new:true}];

	$scope.current_year = function(){
	    return dateFilter($.now(), "yyyy");
	};

	$scope.select_group = function(){
	    var callback = function(params){
		$scope.select_groups = [];
		angular.forEach(params.groups, function(g){
		    if (angular.isDefined(g.select) && g.select){
			$scope.select_groups.push(angular.copy(g));
		    }
		});

		console.log($scope.select_groups);
	    };
	    
	    diabloUtilsService.edit_with_modal(
		"select-size.html", undefined,
		callback, $scope, {groups: $scope.size_groups});
	}
	
	$scope.new_inventory = function(inv){
	    console.log(inv);

	    var callback = function(params){
		console.log(params.groups);

		var amounts = [];
		var total = 0;
		angular.forEach(params.groups, function(g){
		    angular.forEach(g.amount, function(a){
			if (angular.isDefined(a.count) && a.count){
			    amounts.push(a);
			    total += parseInt(a.count);
			}
		    })
		});

		inv.amount = amounts;
		inv.total  = total;
		inv.shop   = $routeParams.shopId;
		inv.groups = params.groups;
		console.log(inv); 

		inventoryService.add(inv).$promise.then(function(state){
		    console.log(state);
		    if(state.ecode == 0){
			// add this number used to prompt when next input
			if (!in_array($scope.prompt_numbers, inv.number)){
			    $scope.prompt_numbers.push(inv.number);
			};
			console.log($scope.prompt_numbers);

			// add this brand used to prompt when next input
			if (!in_prompts($scope.prompt_brands, inv.brand)){
		    	    $scope.prompt_brands.push({
				order_id: $scope.prompt_brands.length + 1,
				name: inv.brand
			    });
			};
			console.log($scope.prompt_brands);

			// add this color used to prompt when next input
			if (!in_prompts($scope.prompt_colors, inv.color)){
			    $scope.prompt_colors.push({
				id: $scope.prompt_colors.length + 1,
				name: inv.color
			    });
			};
			console.log($scope.prompt_colors);

			// add this type used to prompt when next input
			if (!in_prompts($scope.prompt_types, inv.inv_type)){
			    $scope.prompt_types.push({
				order_id: $scope.prompt_types.length + 1,
				name: inv.inv_type
			    });
			};
			console.log($scope.prompt_types);
			
			// reset
			inv.order_id = $scope.inventories.length;
			inv.$new = false;
			inv.$editable = true;
			$scope.inventories.unshift({
			    $editable: false,
			    $new:true,
			    brand: inv.brand,
			    inv_type: inv.inv_type,
			    color:    inv.color,
			    price:    inv.price,
			    discount: inv.discount
			});
		    } else{
			diabloUtilsService.response(
			    false, "新增库存",
			    "新增库存失败：" + inventoryService.error[state.ecode], $scope)
		    }
		});
	    };

	    var groups = [];
	    angular.forEach($scope.select_groups, function(g){
		// var color = typeof(inv.color) === 'object' ? inv.color.name : inv.color;
		var group = {color: inv.color, amount: []};
		
		for(var i=0, l=diablo_sizegroup.length; i<l; i++){
		    var s = diablo_sizegroup[i];
		    if (angular.isDefined(g[s]) && g[s]){
			group.amount.push({size:g[s], color:inv.color});
		    }
		} 
		groups.push(group);
	    }); 

	    if (groups.length === 0){
		diabloUtilsService.response(
		    false, "新增库存",
		    "请选择尺码组！！", $scope)
	    } else{
		diabloUtilsService.edit_with_modal(
	    	    "inventory-new.html", undefined,
	    	    callback, $scope, {groups: groups});
	    } 
	};
	
	$scope.inventory_detail = function(inv){
	    diabloUtilsService.edit_with_modal(
	    	"inventory-detail.html", undefined,
	    	undefined, $scope, {groups: inv.groups});
	};
	
	// // delete
	// $scope.delete_inv = function(inv){
	//     console.log(inv);
	//     inventoryService.destroy(inv).$promise.then(function(state){
	// 	console.log(state)
	// 	if (angular.equals(state.ecode, 0)){
	// 	    $scope.show_error = false;
	// 	}
	// 	else{
	// 	    $scope.show_error = true;
	// 	    $scope.response_error_info = inventoryService.error[state.ecode];
	// 	}
	//     })
	// }

    });

inventoryApp.controller(
    "inventoryCheckCtrl",
    function($scope, $routeParams, supplierService,
	     inventoryService, diabloUtilsService){

	$scope.season = diablo_season;
	$scope.sex = diablo_sex;
	
	// brands
	$scope.prompt_brands = [];
	supplierService.list_brand().$promise.then(function(brands){
	    console.log(brands); 
	    brands = diablo_order(brands); 
	    angular.forEach(brands, function(brand){
	    	$scope.prompt_brands.push({
		    order_id: brand.order_id, name: brand.name});
	    });
	    $scope.brands = brands;
	});

	$scope.get_supplier = function(brand){
	    for(var i=0, l=$scope.brands.length; i<l; i++){
		if(brand === $scope.brands[i].id
		   && $scope.brands[i].supplier_id !== -1){
		    return $scope.brands[i];
		}
	    }
	};

	// $scope.get_brand = function(id){
	//     for(var i=0, l=$scope.prompt_brands.length; i<l; i++){
	// 	if ($scope.prompt_brands[i].id === id){
	// 	    return $scope.prompt_brands[i];
	// 	}
	//     }
	// };
	
	// style_number
	$scope.prompt_numbers = [];
	inventoryService.get_style_numbers_of_shop($routeParams.shopId).then(function(numbers){
	    angular.forEach(numbers, function(number){
		$scope.prompt_numbers.push(number.style_number)
	    })
	});

	// color
	$scope.prompt_colors = [];
	inventoryService.colors().$promise.then(function(colors){
	    diablo_order(colors);
	    angular.forEach(colors, function(color){
	    	$scope.prompt_colors.push(
	    	    {order_id:color.order_id, id:color.id, name:color.name});
	    });
	});

	$scope.prompt_types = [];
	inventoryService.types().$promise.then(function(inv_types){
	    diablo_order(inv_types);
	    
	    angular.forEach(inv_types, function(type){
	    	$scope.prompt_types.push(
	    	    {order_id:type.order_id, id:type.id, name:type.name});
	    });
	});

	$scope.get_type = function(type){
	    for(var i=0, l=$scope.prompt_types.length; i<l; i++){
		if(type === $scope.prompt_types[i].name){
		    return $scope.prompt_types[i];
		}
	    }
	};
	

	$scope.to_s = function(value){
	    // console.log(value.toString());
	    return value.toString();
	};
	
	var shopId = $routeParams.shopId;
	inventoryService.list_unchecked_inventory_group(shopId).then(function(data){
	    console.log(data);
	    $scope.inventories = data;
	    diablo_order($scope.inventories);
	});

	var get_amount = function(cid, size, amounts){
	    for(var i=0, l=amounts.length; i<l; i++){
		if (amounts[i].cid === cid && amounts[i].size === size){
		    return amounts[i]
		}
	    }
	}; 
	
	$scope.check_inventory = function(inv){
	    
	    var in_amount = function(amounts, inv){
		for(var i=0, l=amounts.length; i<l; i++){
		    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
			amounts[i].count += parseInt(inv.amount);
			return true;
		    }
		}
		return false;
	    };
	    
	    var group = {style_number: inv.style_number,
			 brand: inv.brand_id,
			 shop:  inv.shop_id};
	    inventoryService.list_by_group(group).then(function(data){
		console.log(data);

		var callback = function(params){
		    console.log(params);
		    // console.log(inv);
		    // get checked
		    var check_inv = {
			style_number:  inv.style_number,
			brand:         inv.brand_id,
			shop:          inv.shop_id,
			supplier:      $scope.get_supplier(inv.brand_id).supplier_id,
			check_amounts: []};
		    // if(inv.check_style_number !== inv.style_number)
		    // 	check_inv.check_style_number = inv.check_style_number;
		    // if(inv.check_brand !== inv.brand)
		    // 	check_inv.check_brand = inv.check_brand;
		    var change_num = 0;
		    if(inv.check_type.name !== inv.type){
			check_inv.check_type = parseInt(inv.check_type.id);
			change_num++;
		    }
		    if(inv.check_org_price !== $scope.to_s(inv.org_price)) {
			check_inv.check_org_price = parseFloat(inv.check_org_price);
			change_num++;
		    }
		    if(inv.check_plan_price !== $scope.to_s(inv.plan_price)){
			check_inv.check_plan_price = parseFloat(inv.check_plan_price);
			change_num++;
		    }
		    if(inv.check_discount !== $scope.to_s(inv.discount)){
			check_inv.check_discount = parseInt(inv.check_discount);
			change_num++;
		    }

		    angular.forEach(params.amounts, function(a){
			for (var i=0, l=inv.amounts.length; i<l; i++){
			    if (inv.amounts[i].cid === a.cid
				&& inv.amounts[i].size === a.size
				&& inv.amounts[i].count !== a.count){
				check_inv.check_amounts.push(a);
				change_num++;
				break;
			    }
			}
		    });
		    
		    console.log(check_inv);

		    // if(change_num === 0){
		    // 	diabloUtilsService.response(
		    // 	    false, "库存审核", "审核前后数据一致，无需审核！！", $scope);
		    // 	return;
		    // }

		    if(check_inv.check_amounts.length === 0){
			check_inv.check_amounts = undefined;
		    }
		    
		    inventoryService.check_inventory(check_inv).then(function(state){
			console.log(state);
			if (state.ecode == 0){
			    inv.type = inv.check_type.name;
			    
			    if (angular.isDefined(check_inv.check_org_price)){
				inv.org_price =  check_inv.check_org_price;
			    }
			    
			    if (angular.isDefined(check_inv.check_plan_price)){
				inv.plan_price = check_inv.check_plan_price;
			    }
			    
			    if (angular.isDefined(check_inv.check_discount)){
				inv.discount = check_inv.check_discount;
			    }

			    inv.amounts = params.amounts;
			    inv.$editable = false;
			    inv.$checked = true;
			} else{
			    diabloUtilsService.response(
				false, "库存审核",
				"审核失败：" + inventoryService.error[state.ecode], $scope);
			}
		    });
		    
		};

		
		var sizes = [];
		var colors = [];
		var amounts = [];
		angular.forEach(data, function(d){
		    if (!in_array(sizes, d.size)) sizes.push(d.size);
		    
		    var color = {cid:d.color_id, cname: d.color};
		    if (!in_array(colors, color)) colors.push(color);

		    if (!in_amount(amounts, d)){
			amounts.push(
			    {cid:d.color_id, cname:d.color,
			     size:d.size, count:parseInt(d.amount)})
		    } 
		});

		console.log(amounts);

		inv.amounts = amounts;
		inv.sizes   = sizes;
		inv.colors  = colors;
		var payload = {sizes:      sizes,
			       colors:     colors,
			       amounts:    amounts,
			       get_amount: get_amount};

		diabloUtilsService.edit_with_modal(
		    "inventory-check.html", undefined, callback, $scope, payload); 
	    })
	};

	$scope.inventory_detail = function(inv){
	    var payload = {sizes:      inv.sizes,
			   colors:     inv.colors,
			   amounts:    inv.amounts,
			   get_amount: get_amount};
	    diabloUtilsService.edit_with_modal(
		"inventory-detail.html", undefined, undefined, $scope, payload); 
	}
	
    });
