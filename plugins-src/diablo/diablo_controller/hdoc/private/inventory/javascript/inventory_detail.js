inventoryApp.controller(
    "inventoryDetailCtrl",
    function($scope, $routeParams,
	     ngTableUtils, inventoryService, diabloUtilsService,
	     supplierService, dateFilter, user){
	// console.log("inventory detail");
	// console.log($routeParams);
	console.log(user);
	// var shopRight = new userRight();
	// var shop = shopRight.shop();
	// console.log(shop);
	// var formatShop = shop.format(user.shop);
	// console.log(formatShop);

	console.log(user.shop);
	
	$scope.can_modify = function(shop_id){
	    return rightAction.can_modify_inv(shop_id, user.shop, "update_inventory");
	};

	$scope.can_delete = function(shop_id){
	    return rightAction.can_modify_inv(shop_id, user.shop, "delete_inventory");
	};

	// shop
	$scope.prompt_shops = [];
	angular.forEach(user.shop, function(s){
	    $scope.prompt_shops.push({name :s.name, id :s.shop_id});
	});
	
	// supplier and brand
	// $scope.prompt_suppliers = [];
	// supplierService.list().$promise.then(function(suppliers){
	//     // console.log(suppliers);
	//     angular.forEach(suppliers, function(s){
	// 	$scope.prompt_suppliers.push({name :s.name, id :s.id});
	//     })
	// });
	
	$scope.prompt_brands = [];
	inventoryService.brands().$promise.then(function(brands){
	    console.log(brands);
	    diablo_order(brands);
	    angular.forEach(brands, function(brand){
	    	$scope.prompt_brands.push(
		    {name: brand.name, id: brand.id, order_id: brand.order_id});
	    });
	    $scope.brands = brands;
	});

	$scope.get_brand = function(brandId){
	    for(var i=0, l=$scope.brands.length; i<l; i++){
		if (brandId === $scope.brands[i].id){
		    return $scope.brands[i];
		}
	    }
	}

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
	    console.log(colors);
	    angular.forEach(colors, function(color){
	    	$scope.prompt_colors.push({name :color.name, id :color.id});
	    })
	});

	// type
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

	// size group
	// $scope.prompt_sizes = [];
	// inventoryService.list_size_group().$promise.then(function(groups){
	//     // console.log(groups);
	//     angular.forEach(groups, function(group){
	// 	for (var key in group){
	// 	    if (typeof(group[key]) === "function" || key === "id"){
	// 		continue;
	// 	    } 
	// 	    $scope.prompt_sizes.push(group[key])
	// 	};
	//     });
	//     // console.log($scope.prompt_sizes);
	// });

	// pagination
	var order_inventories = function(invs){
	    var inc = (($scope.currentPage - 1) * $scope.itemsPerpage) + 1;
	    angular.forEach($scope.inventories, function(inv){
		inv.order_id = inc;
		inc++;
	    });

	};

	// $scope.form    = {};
	$scope.sexs    = diablo_sex;
	$scope.seasons = diablo_season;
	
	$scope.colspan = 15;
	// $scope.totalItems = 20;
	$scope.itemsPerpage = 5;

	// default, query the data of page 1; query the total records
	var permitShops = angular.isDefined($routeParams.shopId) ?
	    [$routeParams.shopId] : function(){
		var shops = [];
		angular.forEach(user.shop, function(s){
		    if (!in_array(shops, s.shop_id)){
			shops.push(s.shop_id)
		    }
		});
		return shops;
	    }();

	// var format_year = function(invs){
	//     angular.forEach(invs, function(inv){
	// 	inv.year = inv.year.slice(0,4);	
	//     })
	// };
	
	inventoryService.list_pagination_default(
	    permitShops.length === 0 ? undefined:permitShops, $scope.itemsPerpage
	).then(function(data){
	    console.log(data);
	    // data[0] is the total inventory
	    // data[1] is the inventories
	    $scope.totalItems = data[0].count;
	    console.log($scope.totalItems);
	    $scope.inventories = data[1];
	    $scope.currentPage = 1;
	    // format_year($scope.inventories);
	    order_inventories($scope.inventories);
	   
	});
	
	$scope.page_changed = function(){	    
	    // console.log($scope.current_page);
	    console.log($scope.search);
	    if (angular.isUndefined($scope.search)
		|| diablo_is_empty($scope.search)){
		inventoryService.list_by_pagination(
		    permitShops, $scope.currentPage, $scope.itemsPerpage)
		    .$promise.then(function(invs){
			//console.log(invs);
			$scope.inventories = invs;
			order_inventories($scope.inventories);
		    });
	    } else{
		// filter
		inventoryService.do_filter_by_pagination(
		    $scope.pattern.match, $scope.search,
		    $scope.currentPage, $scope.itemsPerpage)
		    .$promise.then(function(invs){
			console.log(invs);
			$scope.inventories = invs.data
			order_inventories($scope.inventories);
		    })
	    };
	};

	/* 
	 * Search operation
	 */
	// canlendar
	$scope.open_calendar = function(event){
	    event.preventDefault();
	    event.stopPropagation();
	};
	
	// one filter
	$scope.filter = {};
	$scope.filter.fields = [{name:"style_number", chinese:"款号"},
				{name:"brand", chinese:"品名"},
				{name:"color", chinese:"颜色"},
				{name:"year", chinese:"年度"},
				{name:"season", chinese:"季节"},
				{name:"size", chinese:"尺码"},
				{name:"shop", chinese:"店铺"},
				{name:"supplier", chinese:"供应商"},
			       ];
	$scope.prompts = {
	    style_number :$scope.prompt_numbers,
	    brand        :$scope.prompt_brands,
	    color        :$scope.prompt_colors,
	    size         :$scope.prompt_sizes,
	    season       :diablo_season2objects,
	    shop         :$scope.prompt_shops,
	    supplier     :$scope.prompt_suppliers
	};

	// initial, has only none filter
	$scope.pattern = {};
	// $scope.filters = [angular.copy($scope.filter)];
	$scope.filters = [];
	$scope.increment = 0;
	// $scope.filter_nums = [];

	// add a filter
	$scope.add_filter = function(){
	    // $scope.filter_nums.push($scope.increment);
	    // add filter
	    $scope.filters[$scope.increment] = angular.copy($scope.filter);
	    $scope.filters[$scope.increment].field
		= $scope.filters[$scope.increment].fields[$scope.increment];
	    $scope.increment++;
	};

	// delete a filter
	$scope.del_filter = function(){
	    // $scope.filter_nums.splice(-1, 1);
	    $scope.filters.splice(-1, 1);
	    $scope.increment--; 
	};

	// $scope.search = {shop: permitShops}
	$scope.search = {};
	$scope.$watch('filters', function(newValue, oldValue){
	    // console.log(newValue);
	    // console.log(oldValue);
	    if (angular.equals(newValue, oldValue)){return};
	    
	    // get field
	    // reset every time
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
		var fullTime = $scope.searchTime.endTime.getTime();
		$scope.search.end_time
		    = dateFilter(fullTime + 86400 * 1000, "yyyy-MM-dd");
	    };
	}, true)

	

	// do filter
	$scope.do_search = function(){
	    // console.log($scope.pattern);
	    // console.log($scope.filters);	    	    

	    console.log($scope.search);
	    if (diablo_is_empty($scope.search)){
		return;
	    }

	    if (angular.isUndefined($scope.search.shop)){
		$scope.search.shop = permitShops; 
	    }
	    
	    // match
	    // var match = $scope.pattern.match;
	    // default the first page
	    $scope.currentPage = 1;
	    inventoryService.do_filter_by_pagination(
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

	/*
	 * refresh
	 */
	$scope.refresh = function(){
	    // console.log("refresh");
	    inventoryService.list_pagination_default(permitShops, $scope.itemsPerpage)
		.then(function(data){
		    console.log(data);
		    // data[0] is the total inventory
		    // data[1] is the inventories
		    $scope.totalItems = data[0].count;
		    console.log($scope.totalItems);
		    $scope.inventories = data[1];
		    $scope.currentPage = 1;
		    order_inventories($scope.inventories);
		});
	}

	/*
	 * edit
	 */
	$scope.goto_page = function(path){
	    window.location = path;
	};

	$scope.reset_editable = function(){
	    angular.forEach($scope.inventories, function(inv){
		inv.uneditable = false;
	    });
	}	

	// $scope.modify_inventory = function(modifiedInv){
	//     $scope.modified_inventory = angular.copy(modifiedInv);
	//     // prevent other
	//     angular.forEach($scope.inventories, function(inv){
	// 	if (modifiedInv.id !== inv.id){
	// 	    inv.uneditable = true;
	// 	}
	//     });

	//     // console.log($scope.inventories);
	// }

	

	$scope.save_modified_inventory = function(oldInv){
	    console.log(oldInv);
	    console.log($scope.modified_inventory);
	    if ($scope.form.numberForm.$invalid
		|| $scope.form.colorForm.$invalid
		|| $scope.form.sizeForm.$invalid){
		return;
	    };

	    // get chaned fileds
	    var changedInv = {};
	    for (var key in $scope.modified_inventory){
		if (!angular.equals($scope.modified_inventory[key], oldInv[key])){
		    changedInv[key] = $scope.modified_inventory[key];
		}
	    };

	    // nothing to be modified
	    if (diablo_is_empty(changedInv)){	
		return;
	    };

	    changedInv.sn = $scope.modified_inventory.sn;
	    inventoryService.update_inventory(changedInv).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    for (var key in changedInv){
			oldInv[key] = changedInv[key];
		    };
		    inventoryService.show_dialog(
		    	true, "修改库存成功", "修改库存" + changedInv.sn + "成功", $scope);
		} else {
		    console.log("failed to update inventory");
		    $scope.update_error_info =
			inventoryService.error[state.ecode];
		}
	    });
	    
	};


	/*
	 * groups
	 */ 
	var group_inventory = function(invs){
	    var in_amount = function(amounts, inv){
		for(var i=0, l=amounts.length; i<l; i++){
		    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
			amounts[i].count += parseInt(inv.amount);
			return true;
		    }
		}
		return false;
	    };
	    
	    var get_amount = function(cid, size, amounts){
		for(var i=0, l=amounts.length; i<l; i++){
		    if (amounts[i].cid === cid && amounts[i].size === size){
			return amounts[i]
		    }
		}
	    };
	    
	    var sizes = [];
	    var colors = [];
	    var amounts = [];
	    angular.forEach(invs, function(d){
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

	    return {colors: colors, sizes: sizes, amounts: amounts, get_amount: get_amount}; 
	}

	/*
	 * lookup
	 */
	$scope.inventory_detail = function(inv){
	    if (angular.isDefined(inv.amounts)
		&& angular.isDefined(inv.sizes)
		&& angular.isDefined(inv.colors)){
		var g = {sizes:      inv.sizes,
			 colors:     inv.colors,
			 amounts:    inv.amounts,
			 get_amount: inv.get_amount};

		diabloUtilsService.edit_with_modal(
		    "inventory-detail.html", undefined, undefined, $scope, g);
		return;
	    }
	    
	    var group = {style_number: inv.style_number,
			 brand: inv.brand_id,
			 shop:  inv.shop_id};
	    
	    inventoryService.list_by_group(group).then(function(data){
		var g = group_inventory(data) 
		inv.amounts = g.amounts;
		inv.sizes   = g.sizes;
		inv.colors  = g.colors;
		inv.get_amount = g.get_amount; 

		diabloUtilsService.edit_with_modal(
		    "inventory-detail.html", undefined, undefined, $scope, g); 
	    })
	};

	/*
	 * update
	 */
	$scope.update_inventory = function(inv){
	    console.log(inv);

	    var callback = function(params){
		// get checked
		var update_inv = {
		    style_number:  inv.style_number,
		    brand:         inv.brand_id,
		    shop:          inv.shop_id,
		    // supplier:      $scope.get_supplier(inv.brand_id).supplier_id,
		    update_amounts:[]};

		var change_num = 0; 
		if(inv.check_style_number !== inv.style_number){
		    update_inv.check_style_number = inv.check_style_number;
		    change_num++;
		}
		if(inv.check_brand.name !== inv.brand){
		    update_inv.check_brand = inv.check_brand.id;
		    change_num++;
		} 
		if(inv.check_type.name !== inv.type){
		    update_inv.check_type = inv.check_type.id;
		    change_num++;
		} 
		if(inv.check_plan_price !== $scope.to_s(inv.plan_price)){
		    update_inv.check_plan_price = parseFloat(inv.check_plan_price);
		    change_num++;
		}
		if(inv.check_discount !== $scope.to_s(inv.discount)){
		    update_inv.check_discount = parseInt(inv.check_discount);
		    change_num++;
		}

		angular.forEach(params.amounts, function(a){
		    for (var i=0, l=inv.amounts.length; i<l; i++){
			if (inv.amounts[i].cid === a.cid
			    && inv.amounts[i].size === a.size
			    && inv.amounts[i].count !== a.count){
			    update_inv.update_amounts.push(a);
			    change_num++;
			    break;
			}
		    }
		});
		
		console.log(update_inv);

		if(change_num === 0){
		    diabloUtilsService.response(
			false, "库存审核", "修改前后数据一致，无需修改！！", $scope);
		    return;
		}

		if(update_inv.update_amounts.length === 0){
		    update_inv.check_amounts = undefined;
		}

		inventoryService.update_inventory(update_inv).then(function(state){
		    console.log(state); 
		    if (state.ecode == 0){
			var ok_callback = function(){
			    if (angular.isDefined(update_inv.check_style_number)){
				inv.style_number = update_inv.check_style_number;
			    }
			    
			    if (angular.isDefined(update_inv.check_brand)){
				inv.brand_id = update_inv.check_brand;
				inv.brand    = $scope.get_brand(inv.brand_id);
			    }

			    if (angular.isDefined(update_inv.check_type)){
				inv.type = inv.check_type.name;
			    }

			    if (angular.isDefined(update_inv.check_plan_price)){
				inv.plan_price = update_inv.check_plan_price;
			    }

			    if (angular.isDefined(update_inv.check_discount)){
				inv.discount = update_inv.check_discount;
			    }

			    inv.amounts = params.amounts;
			    inv.$editable = false;
			}
			
			diabloUtilsService.response_with_callback(
			    true, "库存修改", "恭喜你，修改库存成功！！",
			    $scope, ok_callback);
		    } else{
			diabloUtilsService.response(
			    false, "库存修改",
			    "库存修改失败：" + inventoryService.error[state.ecode], $scope);
		    }
		});
	    };
	    
	    var group = {style_number: inv.style_number,
			 brand: inv.brand_id,
			 shop:  inv.shop_id};
	    
	    inventoryService.list_by_group(group).then(function(data){
		var g = group_inventory(data) 
		inv.amounts    = g.amounts;
		inv.sizes      = g.sizes;
		inv.colors     = g.colors;
		inv.get_amount = g.get_amount;

		diabloUtilsService.edit_with_modal(
		    "inventory-update.html", undefined, callback, $scope, g); 
	    })
	}

	$scope.delete_inventory = function(inv){
	    console.log(inv);
	    diabloUtilsService.response(false, "删除库存", "暂不支持该操作！！", $scope);
	    // inventoryService.destroy($scope.selectedDeleteInventory).$promise
	    // 	.then(function(state){
	    // 	    console.log(state);
	    // 	    if (state.ecode == 0){
	    // 		$scope.delete_response = function(){
	    // 		    $scope.response_success_delete_info =
	    // 			"恭喜你，库存 "
	    // 			+ $scope.selectedDeleteInventory.style_number
	    // 			+ " 删除成功";
	    // 		    return true;
	    // 		};
	    // 		$scope.after_delete_response = function(){
	    // 		    location.reload();
	    // 		};
	    // 	    } else{
	    // 		$scope.delete_response = function(){
	    // 		    $scope.response_error_delete_info =
	    // 			inventoryService.error[state.ecode];
	    // 		    return false;
	    // 		}
	    // 	    }
	    // 	})
	};
    });
