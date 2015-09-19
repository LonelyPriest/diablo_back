purchaserApp.controller("purchaserInventoryRejectCtrl", function(
    $scope, $q, dateFilter, diabloPattern, diabloUtilsService,
    diabloPromise, diabloFilter, wgoodService, purchaserService,
    user, filterFirm, filterEmployee, filterSizeGroup, filterColor){
    console.log(user);

    // $scope.shops     = user.sortShops;
    $scope.shops           = user.sortBadRepoes.concat(user.sortShops);
    // $scope.shops     = user.sortAvailabeShops;
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    $scope.firms           = filterFirm;
    $scope.employees       = filterEmployee;
    $scope.extra_pay_types = purchaserService.extra_pay_types;

    // init
    $scope.has_saved       = false; 
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    
    $scope.select = {
	total: 0,
	should_pay: 0,
	extra_pay_type: $scope.extra_pay_types[0]
    };
    
    $scope.disable_refresh = function(){
	return !$scope.has_saved; 
    };
    
    $scope.change_firm = function(){
	console.log($scope.select.firm);
	$scope.select.surplus = parseFloat($scope.select.firm.balance);
	$scope.re_calculate();
    }

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});
	
	$scope.select.should_pay = 0.00;
	$scope.select.total      = 0;
	$scope.select.comment    = undefined;
	$scope.select.left_balance = $scope.select.firm.balance;
	$scope.select.extra_pay    = undefined;

	$scope.has_saved = false;

    };

    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0.00;
	
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total      += parseInt(one.reject);
	    $scope.select.should_pay -= one.org_price * one.reject;
	}

	var e_pay = 0.00;
	if(angular.isDefined($scope.select.extra_pay)
	   && $scope.select.extra_pay){
	    e_pay = parseFloat($scope.select.extra_pay);
	}

	$scope.select.left_balance =
	    $scope.f_add($scope.select.surplus, $scope.f_sub($scope.select.should_pay, e_pay));
	    // $scope.select.surplus + $scope.select.should_pay;
    };

    $scope.$watch("select.extra_pay", function(newValue, oldValue){
	// console.log(newValue);
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.extraForm.$invalid) return; 
    	$scope.re_calculate(); 
    }); 
    
    if ($scope.firms.length !== 0){
    	$scope.select.firm = $scope.firms[0];
    	$scope.select.surplus = parseFloat($scope.select.firm.balance);
	$scope.select.left_balance   = $scope.select.surplus;
    }
    
    if ($scope.employees.length !== 0){
	$scope.select.employee = $scope.employees[0];
    }

    if ($scope.shops.length !== 0){
	$scope.select.shop = $scope.shops[0];
    }
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
	return $.now();
    };

    $scope.match_prompt_inventory = function(viewValue){
	return diabloFilter.match_w_reject_inventory(
	    viewValue, $scope.select.shop.id, $scope.select.firm.id); 
    }; 

    $scope.on_select_inventory = function(item, model, label){
	console.log(item);

	// has been added
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "退货", "退货失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}
	
	// add at first allways 
	var add = $scope.inventories[0];

	// add at first allways 
	var add = $scope.inventories[0];
	add.id           = item.id;
	add.style_number = item.style_number;
	add.brand        = item.brand;
	add.brand_id     = item.brand_id;
	add.type         = item.type;
	add.type_id      = item.type_id;
	add.s_group      = item.s_group;
	add.free         = item.free; 
	add.sex          = item.sex;
	add.season       = item.season;
	add.org_price    = item.org_price;
	add.tag_price    = item.tag_price;
	add.pkg_price    = item.pkg_price;
	add.price3       = item.price3;
	add.price4       = item.price4;
	add.price5       = item.price5;
	add.discount     = item.discount;
	add.path         = item.path;

	console.log(add);

	$scope.add_inventory(add);
	
	return;
    }; 
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved){
	    return true;
	}; 
	
	if ($scope.inventories.length === 1
	    && (angular.isUndefined($scope.select.extra_pay) || !$scope.select.extra_pay)){
	    return true;
	};

	return false;
    };
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories);
	
	var get_reject = function(amounts){
	    var reject_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		if (angular.isDefined(amounts[i].reject_count)
		    && amounts[i].reject_count){
		    amounts[i].reject_count
			= parseInt(amounts[i].reject_count);
		    reject_amounts.push(amounts[i]); 
		} 
	    }

	    return reject_amounts;
	};

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;
	
	var added = []; 
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    added.push({
		style_number: add.style_number,
		brand       : add.brand_id,
		type        : add.type_id,
		sex         : add.sex,
		season      : add.season,
		org_price   : add.org_price,
		tag_price   : add.tag_price,
		pkg_price   : add.pkg_price,
		p3          : add.price3,
		p4          : add.price4,
		p5          : add.price5,
		s_group     : add.s_group,
		free        : add.free,
		amounts     : get_reject(add.amounts),
		total       : seti(add.reject),
		fdiscount   : add.discount,
		fprice      : add.org_price,
		path        : add.path
	    })
	}; 
	
	var e_pay = setv($scope.select.extra_pay);
	
	var base = {
	    firm:          $scope.select.firm.id,
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       sets($scope.select.comment),
	    balance:       setv($scope.select.surplus),
	    should_pay:    setv($scope.select.should_pay),
	    total:         seti($scope.select.total),

	    e_pay_type:    angular.isUndefined(e_pay) ? undefined : $scope.select.extra_pay_type.id,
	    e_pay:         e_pay
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true
	purchaserService.reject_purchaser_inventory({
	    inventory: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		$scope.select.firm.balance = $scope.select.left_balance;
		$scope.select.surplus = $scope.select.firm.balance;
	    	diabloUtilsService.response(
	    	    true, "退货", "退货成功！！退货单号：" + state.rsn)
	    	return;
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "退货",
	    	    "退货失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };

    /*
     * add
     */ 
    $scope.valid_free_size_reject = function(inv){
    	if (angular.isDefined(inv.amounts)
    	    && angular.isDefined(inv.amounts[0].reject_count) 
    	    && parseInt(inv.amounts[0].reject_count) > inv.total){
    	    return false;
    	}
    	return true;
    };
    
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
	return undefined;
    }; 
    
    var valid_all = function(amounts){
	var unchanged = 0;
	// var invalid = true;
	for(var i=0, l=amounts.length; i<l; i++){
	    var amount = amounts[i];
	    if (angular.isUndefined(amount.reject_count)
		|| !amount.reject_count){
		unchanged++;
	    }
	    else {
		if (diablo_set_integer(amount.reject_count) > amount.count){
		    // unchanged++
		    return false;
		}
	    }
	}
	
	return unchanged == l ? false : true;
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$edit = true;
	inv.$new = false;
	inv.reject = inv.amounts[0].reject_count;
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true});
	
	$scope.re_calculate(); 
    };
    
    $scope.add_inventory = function(inv){
	purchaserService.list_purchaser_inventory(
	    {style_number:inv.style_number,
	     brand:inv.brand_id,
	     shop:$scope.select.shop.id,
	     qtype: diablo_badrepo}
	).then(function(invs){
	    console.log(invs);
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = purchaserService.sort_inventory(invs, order_sizes, filterColor);
	    
	    inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort;

	    var add_callback = function(params){
		console.log(params.amounts);
		
		var reject_total = 0;
		angular.forEach(params.amounts, function(a){
		    if (angular.isDefined(a.reject_count) && a.reject_count){
			reject_total += parseInt(a.reject_count);
		    }
		})

		return {amounts: params.amounts,
			reject: reject_total};
	    };

	    var after_add = function(){
		inv.$edit = true;
		inv.$new = false;
		// order
		inv.order_id = $scope.inventories.length; 
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true});
		
		$scope.re_calculate(); 
	    };
	    
	    var callback = function(params){
		var result = add_callback(params);
		inv.amounts = result.amounts;
		inv.reject  = result.reject;
		after_add();
	    };

	    if (inv.free === 0){
		inv.free_color_size = true;
	    } else{
		inv.free_color_size = false;
		var payload = {sizes:        inv.sizes,
			       colors:       inv.colors,
			       amounts:      inv.amounts,
			       get_amount:   get_amount,
			       // valid_reject: valid_reject,
			       valid:        valid_all};
		
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html",
		    inv.sizes.length >= 6 ? "lg" : undefined,
		    callback, $scope, payload); 
	    }
	}) 
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

	$scope.re_calculate();
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
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
	    inv.reject  = 0;
	    angular.forEach(params.amounts, function(a){
		if (angular.isDefined(a.reject_count) && a.reject_count){
		    inv.reject += parseInt(a.reject_count);
		}
	    });
	    
	    $scope.re_calculate(); 
	};

	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       get_amount:   get_amount,
		       // valid_reject: valid_reject,
		       valid:        valid_all}; 
	diabloUtilsService.edit_with_modal(
	    "inventory-new.html",
	    inv.sizes.length >= 6 ? "lg" : undefined, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false;
	inv.reject = inv.amounts[0].reject_count;
	$scope.re_calculate(); 
    }

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true};;
    }
});


purchaserApp.controller("purchaserInventoryRejectDetailCtrl", function(
    $scope, diabloPattern, diabloUtilsService, diabloFilter,
    purchaserService, user, filterFirm, filterEmployee){
    console.log(user); 

    $scope.shops   = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds);
    
    $scope.add = function(){
	diablo_goto_page('#/record/inventory_new');
    }

    $scope.reject = function(){
	diablo_goto_page('#/record/inventory_reject');
    }

    /*
    ** filter
    */ 
    // initial
    $scope.filters = [];

    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     user.shops);
    diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("employee", filterEmployee); 

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    $scope.time   = diabloFilter.default_time();

    console.log($scope.filter);

    /*
     * pagination 
     */
    $scope.colspan = 15;
    $scope.items_perpage = 10;
    $scope.default_page = 1; 

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length
		    === 0 ? undefined : $scope.shopIds;
	    } 
	    purchaserService.filter_w_inventory_reject(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total
		    }
		    angular.forEach(result.data, function(d){
			d.shop = diablo_get_object(d.shop_id, user.sortShops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
			d.firm     = diablo_get_object(d.firm_id, filterFirm);
		    })
		    $scope.records = result.data; 
		    diablo_order_page(page, $scope.items_perpage, $scope.records); 
		}) 
	})
    }; 
    
    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	// console.log($scope.current_page);
	// console.log(page);
	$scope.do_search($scope.current_page);
    };


    // details
    $scope.rsn_detail = function(r){
	console.log(r);
	diablo_goto_page("#/record/inventory_rsn_detail/reject/" + r.rsn);
    }
});

