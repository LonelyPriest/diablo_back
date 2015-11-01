purchaserApp.controller("purchaserInventoryNewCtrl", function(
    $scope, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, wgoodService, purchaserService,
    localStorageService, user, filterFirm,
    filterEmployee, filterColor, base){
    // console.log(user); 
    // $scope.shops = user.sortAvailabeShops;
    $scope.shops = user.sortShops;
    // console.log($scope.shops);
    
    $scope.firms             = filterFirm;
    $scope.employees         = filterEmployee; 
    $scope.sexs              = diablo_sex;
    $scope.seasons           = diablo_season;
    $scope.float_add         = diablo_float_add;
    $scope.float_sub         = diablo_float_sub;
    $scope.extra_pay_types   = purchaserService.extra_pay_types;
    $scope.round             = diablo_round;
    $scope.disable_refresh   = true;
    $scope.timeout_auto_save = undefined;

    $scope.setting  = {
	round:diablo_round_record
    };
    
    $scope.q_prompt        = diablo_backend;
    
    $scope.right_update_orgprice = function(){
	$scope.modify_orgprice = true;
    }();

    var now = $.now(); 
    // $scope.refresh_firm = function(){
    // 	// $scope.firms = [];
    // 	wgoodService.list_purchaser_firm().then(function(firms){
    // 	    console.log(firms);

    // 	    $scope.firms = firms.map(function(f){
    // 		return {id:f.id, name:f.name, py:diablo_pinyin(f.name), balance:f.balance};
    // 	    })
	    
    // 	    if ($scope.firms.length !== 0){
    // 		$scope.select.firm = $scope.firms[0];
    // 		$scope.select.surplus = parseFloat($scope.select.firm.balance);
    // 	    }
    // 	});
    // };

    $scope.q_typeahead = function(shopId){
	// console.log(shopId);
	// default prompt comes from backend
	return diablo_base_setting(
	    "qtypeahead", shopId, base, parseInt, diablo_backend);
    };

    $scope.p_round = function(shopId){
	// console.log(shopId);
	return diablo_base_setting(
	    "pround", shopId, base, parseInt, diablo_round_record);
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory_new_detail");
    };
	

    $scope.change_firm = function(){
	console.log($scope.select.firm);
	$scope.select.surplus = parseFloat($scope.select.firm.balance);
	$scope.left_balance  = $scope.select.surplus;
	
	$scope.local_save();
	$scope.re_calculate();

	if ($scope.q_prompt === diablo_frontend){
	    $scope.get_all_w_good();
	}
	
	// $scope.refresh();
    };

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});
	// $scope.sexs = diablo_sex;
	// $scope.seasons = diablo_season;
	$scope.select.form.cardForm.$invalid  = false;
	$scope.select.form.cashForm.$invalid  = false;
	$scope.select.form.vForm.$invalid     = false;
	$scope.select.form.wireForm.$invalid  = false;
	$scope.select.form.extraForm.$invalid = false;

	$scope.select.cash       = undefined;
	$scope.select.card       = undefined;
	$scope.select.verificate = undefined;
	$scope.select.wire       = undefined;
	$scope.select.extra_pay  = undefined;
	
	$scope.select.has_pay    = 0;
	$scope.select.should_pay = 0;

	$scope.select.total   = 0;
	$scope.select.comment = undefined;
	$scope.select.left_balance = $scope.select.firm.balance;

	$scope.disable_refresh = true;
	$scope.has_saved = false;
	
	// $scope.get_firm();

	// pagination
	$scope.current_page = $scope.default_page;
	$scope.total_items = $scope.inventories.length; 
	$scope.current_inventories = $scope.get_page($scope.current_page);
    };
    
    // init
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    
    $scope.select = {
	shop: angular.isDefined($scope.shops) && $scope.shops.length !== 0 ? $scope.shops[0]:undefined,
	total: 0,
	has_pay: 0,
	should_pay: 0,
	extra_pay_type: $scope.extra_pay_types[0]};
    
    $scope.current_inventories = [];
    
    if ($scope.firms.length !== 0){
    	$scope.select.firm = $scope.firms[0];
    	$scope.select.surplus = parseFloat($scope.select.firm.balance);
	$scope.select.left_balance = $scope.select.surplus;
    }
    
    if ($scope.employees.length !== 0){
	$scope.select.employee = $scope.employees[0];
    }


    $scope.setting.round = $scope.p_round($scope.select.shop.id);

    // console.log($scope.setting);

    // $scope.get_inventory = function(index){
    // 	$scope.current_inventories = []; 
    // 	// var invs = [];
    // 	angular.forEach(index, function(i){
    // 	    $scope.current_inventories.push($scope.inventories[i]);
    // 	}) 
    // 	// return invs;
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
    $scope.colspan = 10;
    $scope.items_perpage = 20;
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
	return now;
    };

    /*
     * draft
     */
    var current_key = function(){
	return "wp-" + $scope.select.firm.id.toString()
	    + "-" + $scope.select.shop.id.toString()
	    + "-" + $scope.select.employee.id.toString();
    };

    var key_re = /^wp-[0-9-]+$/;
    var draft_keys = function(){
	var keys = localStorageService.keys();
	
	return keys.filter(function(k){
	    return key_re.test(k)
	});
    };

    $scope.local_save = function(){
	var key = current_key();
	// var now = $.now();
	localStorageService.set(
	    key,
	    {t:now, v:$scope.inventories.filter(function(inv){
		return inv.$new === false;})
	    }) 
    };

    $scope.local_remove = function(){
	var key = current_key();
	localStorageService.remove(key);
    } 
    
    $scope.disable_draft = function(){

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
		    firm:diablo_get_object(parseInt(p[1]), $scope.firms),
		    shop:diablo_get_object(parseInt(p[2]), $scope.shops),
		    employee:diablo_get_object(p[3], $scope.employees),
		   }
	});

	// console.log(drafts) 
	var callback = function(params){
	    var select_draft = params.drafts.filter(function(d){
		return angular.isDefined(d.select) && d.select
	    })[0];

	    // console.log($scope.select);
	    $scope.select.firm =
		diablo_get_object(select_draft.firm.id, $scope.firms);
	    $scope.select.shop =
		diablo_get_object(select_draft.shop.id, $scope.shops);
	    $scope.select.employee =
		diablo_get_object(select_draft.employee.id, $scope.employees);
	    
	    var one = localStorageService.get(select_draft.sn);
	    
	    if (angular.isDefined(one) && null !== one){
	        $scope.inventories = angular.copy(one.v);
	        console.log($scope.inventories); 
	        $scope.inventories.unshift({$edit:false, $new:true});

		// pagination
		$scope.total_items = $scope.inventories.length; 
		$scope.current_inventories = $scope.get_page($scope.current_page);
		
		$scope.disable_refresh = false;
	        $scope.re_calculate();
		
	        // $scope.draft = true;
	    } 
	}

	diabloUtilsService.edit_with_modal(
	    "inventory-draft.html", undefined, callback, $scope,
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
    };

    /*
     * match
     */
    $scope.match_prompt_good = function(viewValue){
	if (angular.isUndefined($scope.select.firm)){
	    diabloUtilsService.response_with_callback(
		false, "新增库存", "新增库存失败：" + purchaserService.error[2095],
		$scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
	    return;
	}
	return diabloFilter.match_wgood_with_firm(viewValue, $scope.select.firm.id); 
    };

    $scope.q_prompt = $scope.q_typeahead($scope.select.shop.id);

    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, function(v){return v},
	    dateFilter(diabloFilter.default_start_time(now), "yyyy-MM-dd"));
    };

    $scope.get_all_w_good = function(){
	diabloFilter.match_all_w_good(
	    $scope.qtime_start($scope.select.shop.id), $scope.select.firm.id
	).then(function(goods){
	    // console.log(invs);
	    $scope.all_w_goods =  goods.map(function(g){
		return angular.extend(
		    g, {name:g.style_number + "，"
			+ g.brand + "，" + g.type})
	    });

	    console.log($scope.all_w_goods);
	});
    };
    
    if ($scope.q_prompt === diablo_frontend){
	// console.log($scope.select);
	$scope.get_all_w_good();
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item); 

	// has been added
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "新增库存", "新增库存失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}

	// add at first allways 
	var add = $scope.inventories[0];
	add.id           = item.id;
	add.style_number = item.style_number;
	add.brand        = item.brand;
	add.brand_id     = item.brand_id;
	add.type         = item.type;
	add.type_id      = item.type_id;
	add.sex          = item.sex;
	add.firm_id      = item.firm_id;
	add.year         = item.year; 
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
	add.s_group      = item.s_group;
	add.free         = item.free;
	add.sizes        = item.size.split(",");
	add.colors       = item.color.split(",");
	
	if ( add.free === 0 ){
	    add.free_color_size = true;
	    add.amount = [{cid:0, size:0}];
	} else{
	    add.free_color_size = false;
	    add.amount = []; 
	}

	console.log(add);

	if (!add.free_color_size){
	    $scope.add_inventory(add)
	};
    }; 
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved){
	    return true;
	};
	
	if (angular.isDefined($scope.select.cash) && $scope.select.cash
	    || angular.isDefined($scope.select.card) && $scope.select.card
	    || angular.isDefined($scope.select.wire) && $scope.select.wire
	    || angular.isDefined($scope.select.verificate) && $scope.select.verificate
	    || angular.isDefined($scope.select.extra_pay) && $scope.select.extra_pay
	    || $scope.inventories.length !== 1){
	    return false;
	}


	return true;
    };

    var reset_payment = function(newValue){
	$scope.select.has_pay = 0.00;
	var e_pay = 0.00;
	var verificate = 0.00;
	
	if(angular.isDefined($scope.select.extra_pay)
	   && $scope.select.extra_pay){
	    e_pay = parseFloat($scope.select.extra_pay);
	}
	
	if(angular.isDefined($scope.select.cash) && $scope.select.cash){
	    $scope.select.has_pay += parseFloat($scope.select.cash);
	}

	if(angular.isDefined($scope.select.card) && $scope.select.card){
	    $scope.select.has_pay += parseFloat($scope.select.card);
	}

	if(angular.isDefined($scope.select.wire) && $scope.select.wire){
	    $scope.select.has_pay += parseFloat($scope.select.wire);
	}

	if(angular.isDefined($scope.select.verificate)
	   && $scope.select.verificate){
	    verificate = parseFloat($scope.select.verificate); 
	}

	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay + e_pay
	    - $scope.select.has_pay - verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	// $scope.select.left_balance = $scope.float_add(
	//     $scope.float_add($scope.select.should_pay, e_pay),
	//     $scope.float_sub($scope.select.surplus, $scope.select.has_pay)); 
    };
    
    $scope.$watch("select.cash", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cashForm.$invalid) return; 
	reset_payment(newValue); 
    });

    $scope.$watch("select.card", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cardForm.$invalid) return;
	reset_payment(newValue); 
    });

    $scope.$watch("select.wire", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.wireForm.$invalid) return;
	reset_payment(newValue); 
    });

    $scope.$watch("select.verificate", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.wireForm.$invalid) return; 
	reset_payment(newValue); 
    });

    $scope.$watch("select.extra_pay", function(newValue, oldValue){
	// console.log(newValue);
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.extraForm.$invalid) return; 
    	$scope.re_calculate(); 
    }); 

    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories);

	if (angular.isUndefined($scope.select.firm)
	    || diablo_is_empty($scope.select.firm)
	    || angular.isUndefined($scope.select.shop)
	    || diablo_is_empty($scope.select.shop)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response(
		false, "新增库存", "新增库存失败：" + purchaserService.error[2096]);
	    return;
	};
	
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    added.push({
		good        : add.id,
		style_number: add.style_number,
		brand       : add.brand_id,
		firm        : add.firm_id,
		type        : add.type_id,
		sex         : add.sex,
		year        : angular.isDefined(add.year) && add.year ? add.year : undefined,
		season      : add.season,
		amount      : add.amount,
		s_group     : add.s_group,
		free        : add.free,
		org_price   : parseFloat(add.org_price),
		tag_price   : parseFloat(add.tag_price), 
		pkg_price   : parseFloat(add.pkg_price),
		p3          : parseFloat(add.price3),
		p4          : parseFloat(add.price4),
		p5          : parseFloat(add.price5),
		discount    : parseInt(add.discount),
		path        : add.path,
		alarm_day   : add.alarm_day,
		total       : add.total
	    })
	};

	var setv = diablo_set_float; 
	var e_pay = setv($scope.select.extra_pay);
	
	var base = {
	    firm:          $scope.select.firm.id,
	    shop:          $scope.select.shop.id,
	    date:          dateFilter($scope.select.date, "yyyy-MM-dd"),
	    datetime:      dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       $scope.select.comment,
	    total:         $scope.select.total ? parseInt($scope.select.total):undefined,
	    balance:       parseFloat($scope.select.surplus), 
	    cash:          setv($scope.select.cash),
	    card:          setv($scope.select.card),
	    wire:          setv($scope.select.wire),
	    verificate:    setv($scope.select.verificate),
	    should_pay:    setv($scope.select.should_pay),
	    has_pay:       setv($scope.select.has_pay),
	    
	    e_pay_type:     angular.isUndefined(e_pay) ? undefined : $scope.select.extra_pay_type.id,
	    e_pay:          e_pay,
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true;
	// $scope.local_remove();
	// return;
	purchaserService.add_purchaser_inventory({
	    inventory: added.length === 0 ? undefined: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		$scope.disable_refresh = false; 
		diabloUtilsService.response_with_callback(
		    true, "新增库存", "新增库存成功！！单号：" + state.rsn,
		    $scope, function(){
			// $scope.has_saved = true;
			// modify current balance of retailer
			$scope.select.firm.balance = $scope.select.left_balance;
			$scope.select.surplus = $scope.select.firm.balance;
			$scope.local_remove();
		    })
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "新增库存",
	    	    "新增库存失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false})
	    }
	})
    };

    /*
     * add
     */
    var get_amount = function(cid, sname, amounts){
	var m = {cid:cid, size:sname};
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	
	amounts.push(m); return m;
    };

    var valid_amount = function(amounts){
	var unchanged = 0;
	for (var i=0, l=amounts.length; i<l; i++){
	    if(angular.isUndefined(amounts[i])
	       || angular.isUndefined(amounts[i].count)
	       || !amounts[i].count){
		unchanged++;
	    } 
	}

	// console.log(unchanged, l);
	// console.log(amounts);
	return unchanged === l ? false : true;
    };

    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0.00;

	var e_pay = 0.00;
	if(angular.isDefined($scope.select.extra_pay)
	   && $scope.select.extra_pay){
	    e_pay = parseFloat($scope.select.extra_pay);
	}

	var verificate = 0.00;
	if(angular.isDefined($scope.select.verificate)
	   && $scope.select.verificate){
	    verificate = parseFloat($scope.select.verificate);
	}

	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total      += parseInt(one.total);

	    if ($scope.setting.round === diablo_round_row){
		$scope.select.should_pay
		    += $scope.round(one.org_price * one.total);
	    } else {
		$scope.select.should_pay += one.org_price * one.total; 
	    }
	};

	$scope.select.should_pay = $scope.round($scope.select.should_pay);

	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay + e_pay
	    - $scope.select.has_pay - verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	// $scope.select.left_balance = $scope.float_add(
	//     $scope.float_add($scope.select.should_pay, e_pay),
	//     $scope.float_sub($scope.select.surplus, $scope.select.has_pay));
    };
    
    var add_callback = function(params){
	console.log(params);
	// delete empty
	var new_amount = [];
	for(var i=0, l=params.amount.length; i<l; i++){
	    var amount = params.amount[i]
	    if (angular.isDefined(amount)
		&& angular.isDefined(amount.count)
		&& amount.count){
		// console.log(amount);
		new_amount.push(amount);
	    } 
	}
	
	console.log(new_amount);
	// inv.amount = new_amount;
	var total = 0;
	angular.forEach(new_amount, function(a){
	    total += parseFloat(a.count);
	})

	return {amount:    new_amount,
		total:     total,
		org_price: params.fprice};
	// inv.total = total; 
	// reset(); 
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv);
	// var add = $scope.inventories[0]; 

	var after_add = function(){
	    inv.$edit = true;
	    inv.$new = false;
	    // oreder 
	    inv.order_id = $scope.inventories.length;
	    // backup
	    $scope.local_save();
	    // add new line
	    $scope.inventories.unshift({$edit:false, $new:true});

	    // pagination
	    $scope.total_items = $scope.inventories.length; 
	    $scope.current_inventories = $scope.get_page($scope.current_page);
	    
	    $scope.disable_refresh = false;
	    $scope.re_calculate(); 
	};
	
	var callback = function(params){
	    var result    = add_callback(params);
	    
	    inv.amount    = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    after_add();
	} 
	
	if(inv.free_color_size){
	    inv.total = inv.amount[0].count;
	    after_add();
	} else{
	    var modal_size = diablo_valid_dialog(inv.sizes);
	    var large_size = modal_size === 'lg' ? true : false
	    var payload = {sizes:        inv.sizes,
			   large_size:   large_size,
			   amount:       inv.amount,
			   org_price:    inv.org_price,
			   path:         inv.path,
			   get_amount:   get_amount,
			   valid_amount: valid_amount};

	    if (inv.colors.length === 1 && inv.colors[0] === "0"){
		inv.colors_info = [{cid:0}];
		payload.colors = inv.colors_info;
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", modal_size, callback, $scope, payload)
	    } else{
		inv.colors_info = inv.colors.map(function(cid){
		    return diablo_find_color(parseInt(cid), filterColor); 
		});
		// console.log(inv.colors_info);
		payload.colors = inv.colors_info;
		payload.path   = inv.path;
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", modal_size, callback, $scope, payload);
		// })
	    } 
	} 
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
	
	$scope.local_save();
	// recalculate 
	$scope.re_calculate(); 
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:      inv.sizes,
		       amount:     inv.amount,
		       org_price:  inv.org_price,
		       colors:     inv.colors_info,
		       path:       inv.path,
		       get_amount: get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	inv.$update = true;
	inv.o_org_price = inv.org_price;
	
	if (inv.free_color_size){
	    inv.update_directory = true;
	    return; 
	}
	
	var callback = function(params){
	    var result    = add_callback(params);
	    inv.amount    = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;

	    // save to local
	    $scope.local_save(); 
	    $scope.re_calculate(); 
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	
	var payload = {sizes:      inv.sizes,
		       large_size: large_size,
		       amount:     inv.amount,
		       org_price:  inv.org_price,
		       colors:     inv.colors_info,
		       path:       inv.path,
		       get_amount: get_amount,
		       valid_amount: valid_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-new.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.$update          = false;
	inv.update_directory = false; 
	inv.total            = inv.amount[0].count;
	
	$scope.local_save();
	$scope.re_calculate()

    };

    $scope.cancel_free_update = function(inv){
	console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);
	inv.update_directory = false;
	inv.$update          = false;
	inv.org_price        = inv.o_org_price;
	inv.amount[0].count  = inv.total; 
	// $scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	// inv.$reset = true; 
	// console.log($scope.inventories);
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};
	$scope.current_inventories = $scope.get_page($scope.current_page);
    }

    $scope.auto_save_free = function(inv){
	// console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);

	if (angular.isUndefined(inv.amount[0].count)
	    || !inv.amount[0].count
	    || parseInt(inv.amount[0].count) === 0){
	    return;
	} 
	
	$scope.timeout_auto_save = $timeout(function(){
	    if (inv.$new && inv.free_color_size){
		$scope.add_inventory(inv);
	    }

	    if (!inv.$new && inv.update_directory){
		$scope.save_free_update(inv) 
	    }
	}, 1000); 
    };
});

purchaserApp.controller("purchaserInventoryDetailCtrl", function(
    $scope, $routeParams, $q, dateFilter, diabloPattern, diabloFilter,
    diabloUtilsService, diabloPromise, purchaserService, wgoodService,
    localStorageService, user, filterBrand, filterFirm, filterType,
    filterSizeGroup, filterColor, base){
    // $scope.touch_start = function(){
    // 	console.log("touch_start");
    // }
    // var data = {
    // 	labels : ["January","February","March","April","May","June","July"],
    // 	datasets : [
    // 	    {
    // 		fillColor : "rgba(220,220,220,0.5)",
    // 		strokeColor : "rgba(220,220,220,1)",
    // 		data : [65,59,90,81,56,55,40]
    // 	    },
    // 	    {
    // 		fillColor : "rgba(151,187,205,0.5)",
    // 		strokeColor : "rgba(151,187,205,1)",
    // 		data : [28,48,40,19,96,27,100]
    // 	    }
    // 	]
    // };

    // $scope.chart.data = data;

    /*
     * tab-set
     */ 
    $scope.tab_active = {
	time: true,
	chart:false,
    };

    $scope.chart_data = {};
    
    $scope.shops     = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    
    $scope.sexs      = diablo_sex;
    $scope.seasons   = diablo_season;
    $scope.goto_page = diablo_goto_page;

    $scope.setting = {
	show_orgprice: rightAuthen.show_orgprice(user.type),
	alarm:         false
    };

    $scope.$watch("tab_active", function(newValue, oldValue){
	console.log(newValue, oldValue);
    }, false)
    // console.log($scope.show_orgprice);

    // $scope.shops = user.sortShops;

    $scope.hide_column = true;
    $scope.toggle_left = function(){
	$scope.hide_column = !$scope.hide_column;
    }

    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
	// return diabloFilter.match_w_inventory(viewValue, user.availableShopIds)
    };

    /*
     * filter
     */ 

    // initial
    $scope.filters = [];

    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    diabloFilter.add_field("type", filterType);
    diabloFilter.add_field("year", diablo_full_year);
    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("firm", filterFirm);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = $.now();
    var storage = localStorageService.get(diablo_key_inventory_detail);
    console.log(storage);
    
    if (angular.isDefined(storage) && storage !== null){
    	$scope.filters       = storage.filter;
    	$scope.qtime_start   = storage.start_time;
    } else{
	$scope.filters = [];
	
	$scope.qtime_start = function(){
	    var shop = -1
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
    };

    $scope.time   = diabloFilter.default_time($scope.qtime_start);

    // alarm, use default shop
    $scope.setting.alarm = diablo_base_setting(
	"stock_alarm", -1, base, parseInt, diablo_no);

    // console.log($scope.setting);
    
    // console.log($scope.time); 

    // $scope.qtime_start = function(){
    // 	var shop = -1
    // 	if ($scope.shopIds.length === 1){
    // 	    shop = $scope.shopIds[0];
    // 	};
    // 	return diablo_base_setting(
    // 	    "qtime_start", shop, base, diablo_set_date,
    // 	    diabloFilter.default_start_time(now));
    // }();
    // console.log($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time($scope.qtime_start); 
    // $scope.time   = diabloFilter.default_time(); 

    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    
    // default the first page
    $scope.default_page = 1;
    
    $scope.tab_page = {
	page_of_time: $scope.default_page,
	page_of_chart: $scope.default_page
    };
    
    // $scope.current_page = $scope.default_page;
    
    $scope.page_changed = function(page){
	// console.log(page);
	$scope.tab_page.page_of_time = page;
	$scope.do_search($scope.tab_page.page_of_time);
    }

    $scope.chart_mode = function(page){
	// console.log("chart mode");
	$scope.tab_page.page_of_chart = page;
	$scope.do_search($scope.tab_page.page_of_chart);
    }; 

    // $scope.is_alarm = function(alarm){
    // 	// console.log(alarm);
    // 	return alarm ? "danger" : "";
    // }
    
    
    // filter
    var add_search_condition = function(search){
	if (angular.isUndefined(search.shop)
	    || !search.shop || search.shop.length === 0){
	    // search.shop = user.shopIds;
	    search.shop = $scope.shopIds
		=== 0 ? undefined : $scope.shopIds; ;
	};
    };

    var now_date = diablo_now_date();
    
    $scope.do_search = function(page){
	var mode;
	if ($scope.tab_active.chart){
	    mode = 1;
	    $scope.tab_page.page_of_chart = page;
	} else {
	    $scope.tab_page.page_of_time = page; 
	}
	
	localStorageService.set(
	    diablo_key_inventory_detail,
	    {filter:$scope.filters,
	     start_time:diablo_get_time($scope.time.start_time),
	     page:page, t:now});
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);
	    
	    purchaserService.filter_purchaser_inventory_group(
		mode, $scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);

		if (mode === 1){
		    var labels  = [];
		    var totals  = [];
		    var sells   = [];
		    angular.forEach(result.data, function(d){
			labels.push(d.style_number);
			totals.push(d.amount + d.sell);
			sells.push(d.sell);
		    }); 
		    $scope.chart_data.bar={
			label:labels, left:totals, right:sells};
		    
		} else {
		    if (page === 1){
			$scope.total_items = result.total;
			$scope.total_amount = result.t_amount;
			$scope.total_sell   = result.t_sell;
		    }
		    angular.forEach(result.data, function(d){
			if (now_date.getTime() - diablo_set_date(d.last_sell)
			    > diablo_day_millisecond * d.alarm_day){
			    d.isAlarm = true;
			} else{
			    d.isAlarm = false;
			}
		    })
		    
		    $scope.inventories = result.data;
		    angular.forEach(result.data, function(d){
			d.brand = diablo_get_object(d.brand_id, filterBrand);
			d.type  = diablo_get_object(d.type_id, filterType);
			d.firm  = diablo_get_object(d.firm_id, filterFirm);
			// d.shop  = diablo_get_object(d.shop_id, user.sortShops);
		    })
		    diablo_order_page(
			page, $scope.items_perpage, $scope.inventories); 
		}
	    })
	});
    };
    
    $scope.do_search($scope.tab_page.page_of_time);
        
    /*
     * detail
     */

    $scope.free_color_size = function(inv){
	// wait for get goods from server
	if (angular.isUndefined($scope.goods)){
	    return false;
	}
	
	for(var i=0, l=$scope.goods.length; i<l; i++){
	    var good = $scope.goods[i];
	    if (inv.style_number === good.style_number
		&& inv.brand_id === good.brand_id){
		if (good.color === "0" && good.size === "0"){
		    return true;
		}
	    }
	}
	
	return false;
    };

    var dialog = diabloUtilsService;
    $scope.lookup_detail = function(inv){
	console.log(inv);

	var get_amount = function(cid, size){
	    return purchaserService.get_inventory_from_sort(cid, size, inv.amounts)};
	
	if (angular.isDefined(inv.sizes)
	    && angular.isDefined(inv.colors)
	    && angular.isDefined(inv.amounts)){
	    var payload = {sizes:      inv.sizes,
			   colors:     inv.colors,
			   path:       inv.path,
			   get_amount: get_amount 
			  };
	    
	    dialog.edit_with_modal(
		"inventory-detail.html", undefined, undefined, $scope, payload);
	} else{
	    purchaserService.list_purchaser_inventory(
		{style_number: inv.style_number,
		 brand:        inv.brand_id,
		 rsn:          $routeParams.rsn ? $routeParams.rsn:undefined,
		 shop:         inv.shop_id,
		 qtype:        1}
	    ).then(function(invs){
		console.log(invs);
		var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
		console.log(order_sizes);
		var sort    = purchaserService.sort_inventory(invs, order_sizes, filterColor);
		console.log(sort);
		inv.sizes   = sort.size;
		inv.colors  = sort.color;
		inv.amounts = sort.sort;

		var payload = {sizes:      inv.sizes,
			       colors:     inv.colors,
			       path:       inv.path,
			       get_amount: function(cid, size){
				   return get_amount(cid, size, inv.amounts);
			       }};
		dialog.edit_with_modal(
		    "inventory-detail.html", undefined, undefined,
		    $scope, payload, get_amount); 
	    }) 
	}
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    // console.log(search);
	    
	    purchaserService.csv_export(purchaserService.export_type.stock, search)
		.then(function(result){
	    	    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			    function(){window.location.href = result.url;}) 
		    } else {
			dialog.response(
			    false, "文件导出失败", "创建文件失败："
				+ purchaserService.error[result.ecode]);
		    } 
		}); 
	});
    };
});


purchaserApp.controller("purchaserInventoryNewDetailCtrl", function(
    $scope, $routeParams, $location, dateFilter, diabloPattern,
    diabloUtilsService, localStorageService, diabloFilter, purchaserService,
    user, filterFirm, filterEmployee, base){
    // console.log(user);
    // console.log(filterFirm);
    // console.log(filterEmployee);

    $scope.shops   = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds);

    $scope.f_add   = diablo_float_add;
    $scope.f_sub   = diablo_float_sub;
    $scope.round   = diablo_round; 

    $scope.hidden = {base:true, balance:true, comment:true};
    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base;
    };
    
    $scope.toggle_balance = function(){
	$scope.hidden.balance = !$scope.hidden.balance;
    };
    
    $scope.toggle_comment = function(){
	$scope.hidden.comment = !$scope.hidden.comment;
    };

    var now    = $.now();
    var dialog = diabloUtilsService;

    $scope.add = function(){
	diablo_goto_page('#/inventory_new');
    }

    $scope.reject = function(){
	diablo_goto_page('#/inventory_reject');
    }

    $scope.inventory_detail = function(){
	diablo_goto_page('#/inventory_detail');
    }

    $scope.save_stastic = function(){
	localStorageService.set(
	    "inventory-trans-stastic",
	    {total_items:      $scope.total_items,
	     total_amounts:    $scope.total_amounts,
	     total_spay:       $scope.total_spay,
	     total_hpay:       $scope.total_hpay,
	     total_cash:       $scope.total_cash,
	     total_card:       $scope.total_card,
	     total_wire:       $scope.total_wire,
	     total_verificate: $scope.total_verificate,
	     t:                now});
    };

    $scope.trans_detail = function(r){
	$scope.save_stastic();
	diablo_goto_page('#/inventory_rsn_detail/'
			 + r.rsn + "/" + $scope.current_page.toString());
    };

    $scope.update_detail = function(r){
	$scope.save_stastic(); 
	if (r.type === 0){
	    diablo_goto_page(
		'#/update_new_detail/'
		    + r.rsn + "/" + $scope.current_page.toString());
	} else{
	    diablo_goto_page(
		'#/update_new_detail_reject/'
		    + r.rsn + "/" + $scope.current_page.toString());
	} 
    };
    
    $scope.check_detail = function(r){
	console.log(r);
	var callback = function(){
	    purchaserService.check_w_inventory_new(r.rsn).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "入库单审核", "入库单审核成功！！单号：" + state.rsn,
			$scope, function(){r.state = 1})
	    	    return;
		} else{
	    	    diabloUtilsService.response(
	    		false, "入库单审核",
	    		"入库单审核失败：" + purchaserService.error[state.ecode]);
		}
	    })
	};

	dialog.request(
	    "入库单审核", "审核完成后，入库单将无法修改，确定要审核吗？",
	    callback, undefined, $scope);
	
    };

    $scope.delete_detail = function(r){
	var callback = function(){
	    
	}
	
	dialog.request(
	    "入库单删除", "入库单删除后，无法恢复，确认要删除吗？",
	    callback, undefined, $scope);
    };

    
    /*
    * filter
    */

    var has_pay =  [{name:">0", id:0, py:diablo_pinyin("大于0")},
    		    {name:"=0", id:1, py:diablo_pinyin("等于0")}];
    
    // initial
    // $scope.filters = []; 
    diabloFilter.reset_field(); 
    diabloFilter.add_field("purchaser_type", purchaserService.purchaser_type);
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     $scope.shops);
    diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("employee", filterEmployee);
    diabloFilter.add_field("has_pay",  has_pay);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var storage = localStorageService.get(diablo_key_invnetory_trans);
    console.log(storage);

    if (angular.isDefined(storage) && storage !== null){
    	$scope.filters     = storage.filter;
    	$scope.qtime_start = storage.start_time;
    } else{
	$scope.filters = [];
	
	$scope.qtime_start = function(){
	    var shop = -1;
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
    };
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    // console.log($scope.time); 

    // console.log($scope.prompt);
    // $scope.qtime_start = function(shopId){
    // 	return diablo_base_setting(
    // 	    "qtime_start", shopId, base, diablo_set_date, diabloFilter.default_start_time(now));
    // }();
    // console.log($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time($scope.qtime_start); 
    //$scope.time   = diabloFilter.default_time();
    
    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    var back_page = diablo_set_integer($routeParams.page);
    // console.log(back_page);
    if (angular.isDefined(back_page)){
	$scope.current_page = back_page;
    } else{
	$scope.current_page = $scope.default_page; 
    };
    
    var add_search_condition = function(search){
	if (angular.isUndefined(search.shop)
	    || !search.shop || search.shop.length === 0){
	    // search.shop = user.shopIds.length === 0 ? undefined : user.shopIds;
	    search.shop = $scope.shopIds
		=== 0 ? undefined : $scope.shopIds; 
	}
    };
    
    $scope.do_search = function(page){
	// console.log(page);
	$scope.current_page = page; 
	
	localStorageService.set(
	    diablo_key_invnetory_trans,
	    {filter:$scope.filters,
	     start_time:diablo_get_time($scope.time.start_time),
	     page:page, t:now});

	if (angular.isDefined(back_page)){
	    var stastic = localStorageService.get("inventory-trans-stastic");
	    console.log(stastic);
	    $scope.total_items      = stastic.total_items;
	    $scope.total_amounts    = stastic.total_amounts;
	    $scope.total_spay       = stastic.total_spay;
	    $scope.total_hpay       = stastic.total_hpay;
	    $scope.total_cash       = stastic.total_cash;
	    $scope.total_card       = stastic.total_card;
	    $scope.total_wire       = stastic.total_wire;
	    $scope.total_verificate = stastic.total_verificate;

	    // recover
	    $location.path("/inventory_new_detail", false);
	    $routeParams.page = undefined;
	    back_page = undefined;
	    localStorageService.remove("inventory-trans-stastic");
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);
	    
	    purchaserService.filter_w_inventory_new(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1 && angular.isUndefined(back_page)){
			$scope.total_items      = result.total
			$scope.total_amounts    = result.t_amount;
			$scope.total_spay       = result.t_spay;
			$scope.total_hpay       = result.t_hpay;
			$scope.total_cash       = result.t_cash;
			$scope.total_card       = result.t_card;
			$scope.total_wire       = result.t_wire;
			$scope.total_verificate = result.t_verificate;
		    }
		    
		    angular.forEach(result.data, function(d){
			d.firm = diablo_get_object(d.firm_id, filterFirm);
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    });
		    $scope.records = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.records);
		}) 
	})
    };
			
    $scope.do_search($scope.current_page);

    $scope.page_changed = function(){
	// console.log($scope.current_page);
	$scope.do_search($scope.current_page);
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    // console.log(search);
	    
	    purchaserService.csv_export(purchaserService.export_type.trans, search)
		.then(function(result){
	    	    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			    function(){window.location.href = result.url;}) 
		    } else {
			dialog.response(
			    false, "文件导出失败", "创建文件失败："
				+ purchaserService.error[result.ecode]);
		    } 
		}); 
	}) 
    };
    
});
