purchaserApp.controller("purchaserInventoryFixCtrl", function(
    $scope, $q, dateFilter, localStorageService, diabloPattern,
    diabloUtilsService, diabloPromise, diabloFilter, purchaserService,
    wgoodService, user, filterEmployee, filterSizeGroup, filterColor){
    console.log(user);

    // var allowedshops = rightAction.get_w_shops(user.sortShops, "fix_w_inventory");
    $scope.shops = user.sortShops;
    
    // $scope.shops = user.sortAvailabeShops;
    
    $scope.sexs = diablo_sex;
    $scope.seasons = diablo_season;

    
    // employees
    $scope.employees = filterEmployee;
    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 

	$scope.has_saved = false;

	// pagination
	$scope.current_page = $scope.default_page;
	$scope.total_items = $scope.inventories.length; 
	$scope.current_inventories = $scope.get_page($scope.current_page); 
    };
    
    /*
     * init
     */ 
    // $scope.refresh();
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    $scope.current_inventories = [];
    $scope.select = {
	shop:$scope.shops[0]
    };
    // $scope.draft  = false;
    $scope.has_saved = false;
    
    // $scope.get_inventory = function(index){
    // 	var invs = [];
    // 	angular.forEach(index, function(i){
    // 	    invs.push($scope.inventories[i]);
    // 	}) 
    // 	return invs;
    // }

    /*
     * pagination
     */
    $scope.get_page = function(page){
	var length = $scope.inventories.length;
	var begin = (page - 1) * $scope.items_perpage;
	var end = begin + $scope.items_perpage > length ?
	    length : begin + $scope.items_perpage;

	var index = [];
	for(var i=begin; i<end; i++){
	    index.push(i);
	}

	var invs = [];
	angular.forEach(index, function(i){
	    invs.push($scope.inventories[i]);
	})
	
	return invs; 
    };
    
    $scope.page_changed = function(page){
	// console.log(page);
	$scope.current_inventories =  $scope.get_page(page);
    };

    // pagination
    $scope.colspan = 9;
    $scope.items_perpage = 4;
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;
    
    $scope.total_items = $scope.inventories.length;
    $scope.current_inventories = $scope.get_page($scope.current_page);    
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
	return $.now();
    }

    $scope.match_style_number = function(viewValue){
	console.log(viewValue);
	return diabloFilter.match_w_fix(viewValue, $scope.select.shop.id);
    } 
    
    // firm
    // $scope.get_firm();
    // purchaserService.list_purchaser_firm().then(function(data){
    //     console.log(data);
    //     $scope.firms = data;
    //     $scope.select.firm = $scope.firms[0];
    //     $scope.select.surplus = parseFloat($scope.select.firm.balance);
    // }); 
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);

	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "库存盘点", "盘点失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	};

	// add at first allways 
	var add = $scope.inventories[0];

	add.id           = item.id;
	add.style_number = item.style_number;
	add.brand        = item.brand;
	add.brand_id     = item.brand_id;
	add.type         = item.type;
	add.type_id      = item.type_id;
	add.firm_id      = item.firm_id;
	add.s_group      = item.s_group;
	add.free         = item.free;
	add.sex          = item.sex;
	add.season       = item.season;
	add.org_price    = item.org_price; 
	add.discount     = item.discount;
	add.path         = item.path;

	console.log(add);
	
	$scope.add_inventory(add); 
	return;
    };

    var current_key = function(){
	return "wd-" + $scope.select.shop.id.toString()
	    + "-" + $scope.select.employee.id.toString();
    };

    var draft_keys = function(){
	var key_re = /^wd-[0-9-]+$/;
	var keys = localStorageService.keys();

	return keys.filter(function(k){
	    return key_re.test(k)
	});
    };

    $scope.local_save = function(){
	var key = current_key();
	var now = $.now();
	// console.log($scope.inventories);
	localStorageService.set(
	    key,
	    {t:now, v:$scope.inventories.filter(function(inv){
		return inv.$new === false;})
	    });
    };

    $scope.local_remove = function(){
	var key = current_key();
	localStorageService.remove(key);
    }

    $scope.disable_draft = function(){
	// var key = current_key();
	// var inventories = localStorageService.get(key); 

	if (draft_keys().length === 0){
	    return true;
	}
	
	if ($scope.inventories.length !== 1){
	    return true;
	};
	
	return false;
    };


    $scope.list_draft = function(){
	
	var key_fix = draft_keys();
	
	// console.log(key); 
	var drafts = key_fix.map(function(k){
	    var p = k.split("-");
	    return {sn:k,
		    employee:diablo_get_object(p[2], $scope.employees),
		    shop:diablo_get_object(parseInt(p[1]), $scope.shops)}
	});

	// console.log(drafts)

	var callback = function(params){
	    var select_draft = params.drafts.filter(function(d){
		return angular.isDefined(d.select) && d.select
	    })[0];

	    // console.log($scope.select);
	    $scope.select.employee =
		diablo_get_object(select_draft.employee.id, $scope.employees);
	    $scope.select.shop =
		diablo_get_object(select_draft.shop.id, $scope.shops);

	    var one = localStorageService.get(select_draft.sn);
	    
	    if (angular.isDefined(one) && null !== one){
	        $scope.inventories = angular.copy(one.v);
	        console.log($scope.inventories); 
	        $scope.inventories.unshift({$edit:false, $new:true});

		// page again
		$scope.total_items = $scope.inventories.length;
		$scope.current_inventories = $scope.get_page($scope.current_page);
		
	        re_calculate();
	    
	        // $scope.draft = true;
	    } 
	}

	diabloUtilsService.edit_with_modal(
	    "wfix-draft.html", undefined, callback, $scope,
	    {drafts:drafts,
	     valid: function(drafts){
		 for (var i=0, l=drafts.length; i<l; i++){
		     if (angular.isDefined(drafts[i].select) && drafts[i].select){
			 return true;
		     }
		 } 
		 return false;
	     },
	     select: function(drafts, d){
		 for (var i=0, l=drafts.length; i<l; i++){
		     if (d.sn !== drafts[i].sn){
			 drafts[i].select = false;
		     }
		 }
	     }
	    }); 
    }
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved){
	    return true;
	}; 

	if ($scope.inventories.length === 1){
	    return true;
	};

	return false;
    }; 
    
    $scope.save_inventory = function(){
	$scope.has_saved = true
	// console.log($scope.inventories); 
	var added = [];
	var get_fixed = function(amounts){
	    var fixed_amounts = []; 
	    angular.forEach(amounts, function(a){
		if (angular.isDefined(a.fixed_count) && a.fixed_count){
		    if (parseInt(a.fixed_count) !== a.count){
			a.fixed_count = parseInt(a.fixed_count);
			fixed_amounts.push(a)
		    }
		}
	    })

	    return fixed_amounts;
	}
	
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    // get changed only
	    var fixed_amounts = get_fixed(add.amounts);
	    if ( fixed_amounts !== 0){
		added.push({
		    style_number    : add.style_number,
		    brand           : add.brand_id,
		    firm            : add.firm_id,
		    type            : add.type_id,
		    // sex             : add.sex,
		    season          : add.season,
		    s_group         : add.s_group,
		    free            : add.free,
		    exist           : add.total,
		    fixed           : add.fixed,
		    metric          : add.metric,
		    // amounts         : get_fixed(add.amounts),
		    amounts         : fixed_amounts,
		    fprice          : add.org_price,
		    fdiscount       : add.discount,
		    path            : add.path
		    // tag_price   : add.tag_price, 
		    // pkg_price   : add.pkg_price,
		    // p3          : add.price3,
		    // p4          : add.price4,
		    // p5          : add.price5,
		    // discount    : add.discount
		})
	    } 
	}; 

	var base = {
	    // firm:          $scope.select.firm.id,
	    shop:             $scope.select.shop.id,
	    date:             dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:         $scope.select.employee.id,
	    total_exist:      $scope.select.total_exist,
	    total_fixed:      $scope.select.total_fixed,
	    total_metric:     $scope.select.total_metric,
	};

	console.log(added);
	console.log(base);
	// return;

	// $scope.has_saved = true
	purchaserService.fix_purchaser_inventory({
	    inventory: added.length === 0 ? undefined : added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
	    	diabloUtilsService.response_with_callback(
	    	    true, "库存盘点", "盘点成功！！盘点单号：" + state.rsn,
		    $scope, $scope.local_remove)
	    	return;
	    } else{
	    	diabloUtilsService.response(
	    	    false, "库存盘点",
	    	    "盘点失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };

    /*
     * add
     */
    // $scope.valid_free_size_reject = function(inv){
    // 	if (angular.isDefined(inv.amounts)
    // 	    && angular.isDefined(inv.amounts[0].reject_count) 
    // 	    && parseInt(inv.amounts[0].reject_count) > inv.total){
    // 	    return false;
    // 	}
    // 	return true;
    // };
    
    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
    };
    
    var re_calculate = function(){
	$scope.select.total_exist = 0; 
    	$scope.select.total_fixed = 0;
	$scope.select.total_metric = 0;
	
    	for (var i=1, l=$scope.inventories.length; i<l; i++){
    	    var one = $scope.inventories[i];
	    
	    $scope.select.total_exist += one.total;
	    
	    if (angular.isDefined(one.fixed) && one.fixed){
		$scope.select.total_fixed += parseInt(one.fixed); 
	    } 
    	}

	$scope.select.total_metric = $scope.select.total_fixed
	    - $scope.select.total_exist;

	// pagination
	$scope.total_items = $scope.inventories.length; 
	$scope.current_page_index = $scope.get_page($scope.current_page);
    }; 

    var valid_fixed = function(amount){
	var re = /^[+|\-]?\d+$/;
	// var re = /^\d+$/;
	if (angular.isDefined(amount)
	    && amount.fixed_count
	    && !re.test(amount.fixed_count)){
	    return false;
	};
	
	return true
    };
    
    var valid_all = function(amounts){
	// var re = /^\d+$/;
	var re = /^[+|\-]?\d+$/;
	var unchanged = 0;
	for(var i=0, l=amounts.length; i<l; i++) {
	    var amount = amounts[i];
	    
	    if (angular.isUndefined(amount.fixed_count)
		|| !amount.fixed_count){
		unchanged++;
		continue;
	    }
	    
	    if (angular.isDefined(amount.fixed_count) && amount.fixed_count
		&& !re.test(amount.fixed_count)){
		// console.log(re.test(amount.fixed_count));
		return false; 
	    } 
	}

	// return unchanged === l ? false : true;
	// console.log(unchanged);
	return unchanged !== 0 ? false : true;
    };

    // var amount_change = function(amounts){
    // 	var fixed = 0;
    // 	for(var i=0, l=amounts.length; i<l; i++) {
    // 	    if (angular.isDefined(amounts[i].fixed_count)
    // 		&& amounts[i].fixed_count
    // 		&& !re.test(amounts[i].fixed_count)){
    // 		fixed += parseInt(amounts[i].fixed_count);
    // 	    }
    // 	}
    // }

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$edit = true;
	inv.$new = false;

	inv.fixed = inv.amounts[0].fixed_count;
	inv.metric = parseInt(inv.fixed) - inv.total;
	
	// oreder
	inv.order_id = $scope.inventories.length;
	$scope.local_save();
	
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true});

	// pagination
	$scope.total_items = $scope.inventories.length;
	$scope.current_inventories = $scope.get_page($scope.current_page);

	// pagination
	// $scope.total_items = $scope.inventories.length; 
	// $scope.current_page_index = $scope.get_page($scope.current_page);
	
	re_calculate(); 
    };
    
    $scope.add_inventory = function(inv){
	purchaserService.list_purchaser_inventory(
	    {style_number:inv.style_number, brand:inv.brand_id, shop:$scope.select.shop.id}
	).then(function(invs){
	    console.log(invs);
	    
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = purchaserService.sort_inventory(invs, order_sizes, filterColor);
	    
	    inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort;

	    var after_add = function(){
		console.log(inv);
		inv.$edit = true;
		inv.$new = false;
		// oreder
		inv.order_id = $scope.inventories.length;
		
		// save to local storage
		$scope.local_save();
		
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true}); 

		// pagination
		$scope.total_items = $scope.inventories.length;
		$scope.current_inventories = $scope.get_page($scope.current_page); 
		
		re_calculate(); 
	    };
	    
	    var callback = function(params){
		inv.amounts = params.amounts;
		inv.fixed   = 0;
		angular.forEach(params.amounts, function(a){
		    if (angular.isDefined(a.fixed_count) && a.fixed_count){
			inv.fixed += parseInt(a.fixed_count);
		    }
		})
		inv.metric  = parseInt(inv.fixed) - inv.total;
		after_add();
	    }; 
	    
	    if (inv.free === 0){
		inv.free_color_size = true;
		// inv.amounts = [{cid:0, size:0, count:inv.total}];
	    } else{
		inv.free_color_size = false;
		var modal_size = diablo_valid_dialog(inv.sizes);
		var large_size = modal_size === 'lg' ? true : false
		var payload = {sizes:        inv.sizes,
			       large_size:   large_size,
			       colors:       inv.colors,
			       amounts:      inv.amounts,
			       get_amount:   get_amount,
			       valid_fixed:  valid_fixed,
			       valid_all:    valid_all
			      };

		diabloUtilsService.edit_with_modal(
		    "inventory-fix.html", modal_size, callback, $scope, payload); 
	    }; 
	}); 
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	console.log(inv);
	// console.log($scope.inventories)

	// var deleteIndex = -1;
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		// $scope.inventories.splice(i, 1)
		// deleteIndex = i;
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}

	// pagination 
	$scope.total_items = $scope.inventories.length;
	$scope.current_inventories = $scope.get_page($scope.current_page); 

	// recalculate
	$scope.local_save();
	re_calculate();
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false
	var payload = {sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors,
		       fixed:        inv.fixed,
		       amounts:      inv.amounts,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-fix-detail.html", modal_size, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    return;
	}
	
	var callback = function(params){
	    inv.amounts = params.amounts;
	    inv.fixed   = 0;
	    angular.forEach(params.amounts, function(a){
		if (angular.isDefined(a.fixed_count) && a.fixed_count){
		    inv.fixed += parseInt(a.fixed_count);
		}
	    })
	    inv.metric  = parseInt(inv.fixed) - inv.total;

	    // save to local
	    $scope.local_save();
	    
	    re_calculate(); 
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false
	
	var payload = {sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors,
		       fixed:        inv.fixed,
		       amounts:      inv.amounts,
		       get_amount:   get_amount,
		       valid_fixed:  valid_fixed,
		       valid_all:    valid_all}; 
	diabloUtilsService.edit_with_modal(
	    "inventory-fix.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false;
	inv.fixed = inv.amounts[0].fixed_count;
	inv.metric = parseInt(inv.fixed) - inv.total;
	$scope.local_save();
	re_calculate(); 
    }

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true};;
    }
});



purchaserApp.controller("purchaserInventoryFixDetailCtrl", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, wgoodService,
    user, filterEmployee, base){
    console.log(user);

    $scope.goto_page = diablo_goto_page;

    $scope.go_fix = function(){
	$scope.goto_page('#/inventory/inventory_fix');
    };

    $scope.go_fix_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/fix');
    };

    /*
    ** filter
    */ 

    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     user.sortShops);
    // diabloFilter.add_field("shop",     user.sortAvailabeShops);
    // diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("employee", filterEmployee); 

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, diablo_set_date, diabloFilter.default_start_time(now));
    }();
    // console.log($scope.qtime_start);
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start); 
    // $scope.time   = diabloFilter.default_time();

    console.log($scope.filter);
    
    /*
     * pagination 
     */
    $scope.colspan = 15;
    $scope.items_perpage = 10;
    $scope.default_page = 1;
    // $scope.current_page = $scope.default_page;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = user.availableShopIds.length
		    === 0 ? undefined : user.shopIds; ;
	    }

	    purchaserService.filter_fix_w_inventory(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total
		    }
		    angular.forEach(result.data, function(d){
			d.shop = diablo_get_object(d.shop_id, user.sortShops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    })
		    $scope.records = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.records);
		})

	    $scope.current_page = page;
	    
	})
    };
    
    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };


    // details
    $scope.rsn_detail = function(r){
	console.log(r);
	diablo_goto_page("#/inventory/inventory_rsn_detail/fix/" + r.rsn);
    }
    
})
