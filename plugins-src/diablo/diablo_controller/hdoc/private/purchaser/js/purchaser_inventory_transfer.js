purchaserApp.controller("purchaserInventoryTransferCtrl", function(
    $scope, $q, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloPromise, diabloFilter, wgoodService, purchaserService,
    user, filterFirm, filterEmployee, filterSizeGroup, filterColor, base){
    // console.log(user);

    // $scope.shops     = user.sortShops;
    $scope.shops             = user.sortBadRepoes.concat(user.sortShops);
    $scope.to_shops          = [];
    
    // $scope.shops     = user.sortAvailabeShops;
    $scope.f_add             = diablo_float_add;
    $scope.f_sub             = diablo_float_sub;
    
    $scope.sexs              = diablo_sex;
    $scope.seasons           = diablo_season;
    $scope.firms             = filterFirm;
    $scope.employees         = filterEmployee;
    $scope.extra_pay_types   = purchaserService.extra_pay_types;
    $scope.timeout_auto_save = undefined;
    $scope.round             = diablo_round;
    $scope.setting           = {
	reject_negative: false,
	round: diablo_round_record
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory_new_detail");
    };

    var now = $.now();

    // init
    $scope.has_saved       = false; 
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true}); 
    
    $scope.select = {
	total: 0,
	should_pay: 0,
	shop: $scope.shops.length !==0 ? $scope.shops[0]: undefined,
	// extra_pay_type: $scope.extra_pay_types[0]
    };

    $scope.get_transfer_sthop = function(){
	$scope.to_shops = [];
	for (var i=0, l=$scope.shops.length; i<l; i++){
	    if ($scope.select.shop.id !== $scope.shops[i].id){
		$scope.to_shops.push($scope.shops[i]);
	    }
	};

	if ($scope.to_shops.length !==0){
	    $scope.select.to_shop = $scope.to_shops[0];
	};
    };

    $scope.disable_refresh = function(){
	return !$scope.has_saved; 
    };
    
    $scope.change_firm = function(){
	console.log($scope.select.firm); 

	if ($scope.q_prompt === diablo_frontend){
	    $scope.get_all_prompt_inventory();
	}
    };

    $scope.change_shop = function(){
	// console.log($scope.select.shop);
	// $scope.setting.reject_negative = diablo_base_setting(
	//     "reject_negative", $scope.select.shop.id, base, parseInt, diablo_no);

	// $scope.setting.round = diablo_base_setting(
	//     "pround", $scope.select.shop.id, base, parseInt, diablo_round_record);
	$scope.get_transfer_sthop();
	if ($scope.q_prompt === diablo_frontend){
	    $scope.get_all_prompt_inventory();
	}
    };

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});
	
	$scope.select.total      = 0;
	$scope.select.comment    = undefined;

	$scope.has_saved = false;

    }; 
    
    if ($scope.firms.length !== 0){
    	$scope.select.firm = $scope.firms[0]; 
    }
    
    if ($scope.employees.length !== 0){
	$scope.select.employee = $scope.employees[0];
    }

    $scope.get_transfer_sthop(); 
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
	return now;
    };

    $scope.q_typeahead = function(shopId){
	// console.log(shopId);
	// default prompt comes from backend
	return diablo_base_setting(
	    "qtypeahead", shopId, base, parseInt, diablo_backend);
    };

    $scope.q_prompt = $scope.q_typeahead($scope.select.shop.id);
    
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, function(v){return v},
	    dateFilter(diabloFilter.default_start_time(now), "yyyy-MM-dd"));
    };

    // console.log($scope.setting);

    $scope.get_all_prompt_inventory = function(){
	diabloFilter.match_all_w_reject_inventory(
	    $scope.qtime_start($scope.select.shop.id),
	    $scope.select.shop.id,
	    $scope.select.firm.id
	).then(function(invs){
	    // console.log(invs);
	    $scope.all_prompt_inventory = invs.map(function(inv){
		return angular.extend(
		    inv, {name:inv.style_number +
			  "，" + inv.brand + "，" + inv.type})
	    });

	    // console.log($scope.all_prompt_inventory);
	});
    };
    
    if ($scope.q_prompt === diablo_frontend){
	// console.log($scope.select);
	$scope.get_all_prompt_inventory()
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
		    false, "库存转移", "转移失败：" + purchaserService.error[2099],
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
	add.year         = item.year;
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
	add.alarm_day    = item.alarm_day;

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
	
	if ($scope.inventories.length === 1){
	    return true;
	};

	return false;
    };
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories);
	
	var get_transfer_amount = function(amounts){
	    var reject_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		if (angular.isDefined(amounts[i].reject_count)
		    && amounts[i].reject_count){
		    amounts[i].reject_Pcount
			= parseInt(amounts[i].reject_count);
		    reject_amounts.push({
			cid:amounts[i].cid,
			size:amounts[i].size,
			count:parseInt(amounts[i].reject_count)
		    }); 
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
		year        : add.year,
		
		amounts     : get_transfer_amount(add.amounts),
		total       : seti(add.reject),
		discount    : add.discount,
		path        : add.path,
		alarm_day   : add.alarm_day
	    })
	}; 
	
	// var e_pay = setv($scope.select.extra_pay);
	
	var base = {
	    firm:          $scope.select.firm.id,
	    balance:       $scope.select.firm.balance,
	    shop:          $scope.select.shop.id,
	    tshop:         $scope.select.to_shop.id,
	    datetime:      dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       sets($scope.select.comment), 
	    total:         seti($scope.select.total) 
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true
	purchaserService.transfer_purchaser_inventory({
	    inventory: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
	    	diabloUtilsService.response(
	    	    true, "库存转移", "库存转移成功！！单号：" + state.rsn)
	    	return;
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "库存转移",
	    	    "库存转移失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };

    $scope.re_calculate = function(){
	$scope.select.total = 0;
	
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total      += parseInt(one.reject); 
	} 
    };
    
    /*
     * add
     */ 

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 

    $scope.valid_free_size_reject = function(inv){
    	if (angular.isDefined(inv.amounts)
    	    && angular.isDefined(inv.amounts[0].reject_count) 
    	    // && !$scope.setting.reject_negative
	    // && parseInt(inv.amounts[0].reject_count) > inv.total
	   ){
	    if (parseInt(inv.amounts[0].reject_count) > inv.total){
		return false;
	    }
    	}
    	return true;
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
		// if ( !$scope.setting.reject_negative
		//      && diablo_set_integer(amount.reject_count)>amount.count)
		if (diablo_set_integer(amount.reject_count) > amount.count) {
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
	    var order_sizes = wgoodService.format_size_group(
		inv.s_group, filterSizeGroup);
	    var sort = purchaserService.sort_inventory(
		invs, order_sizes, filterColor);
	    
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
			reject:  reject_total,
			org_price: params.org_price};
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
		inv.amounts   = result.amounts;
		inv.reject    = result.reject;
		inv.org_price = result.org_price;
		after_add();
	    };

	    if (inv.free === 0){
		inv.free_color_size = true;
	    } else{
		inv.free_color_size = false;
		var payload = {sizes:        inv.sizes,
			       colors:       inv.colors,
			       org_price:    inv.org_price,
			       amounts:      inv.amounts,
			       get_amount:   get_amount,
			       // valid_reject: valid_reject,
			       valid:        valid_all};
		
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", 'normal',
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
		       org_price:    inv.org_price,
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
	    inv.o_org_price  = inv.org_price;
	    return;
	}
	
	var callback = function(params){
	    inv.amounts   = params.amounts;
	    inv.org_price = params.org_price;
	    inv.reject    = 0;
	    angular.forEach(params.amounts, function(a){
		if (angular.isDefined(a.reject_count) && a.reject_count){
		    inv.reject += parseInt(a.reject_count);
		}
	    });

	    calculate();
	};

	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       org_price:    inv.org_price,
		       amounts:      inv.amounts,
		       get_amount:   get_amount,
		       // valid_reject: valid_reject,
		       valid:        valid_all}; 
	diabloUtilsService.edit_with_modal(
	    "inventory-new.html", undefined, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save); 
	inv.free_update = false;
	inv.reject      = inv.amounts[0].reject_count;
	$scope.re_calculate();
    }

    $scope.cancel_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.org_price  = inv.o_org_price;
	inv.amounts[0].reject_count = inv.reject;
    } 
    
    $scope.reset_inventory = function(inv){
	// inv.$reset = true;
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    }


    var timeout_auto_save = undefined;
    $scope.auto_save_free = function(inv){

	$timeout.cancel($scope.timeout_auto_save); 
	if (angular.isUndefined(inv.amounts[0].reject_count)
	    || !inv.amounts[0].reject_count
	    || parseInt(inv.amounts[0].reject_count) === 0){
	    return;
	}

	if (!$scope.setting.reject_negative
	    && parseInt(inv.amounts[0].reject_count) > inv.total){
	    return;
	}

	$scope.timeout_auto_save = $timeout(function(){
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    };

	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv);
	    }
	}, 1000); 
    };
    
});
