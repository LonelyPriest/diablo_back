purchaserApp.controller("purchaserInventoryNewUpdateCtrl", function(
    $scope, $q, $routeParams, diabloPromise, dateFilter, diabloPattern,
    diabloUtilsService, diabloFilter, wgoodService, purchaserService,
    user, filterBrand, filterFirm, filterType, filterEmployee,
    filterSizeGroup, filterColor, base){

    $scope.shops       = user.sortShops;
    $scope.brands      = filterBrand;
    $scope.firms       = filterFirm;
    $scope.types       = filterType;
    $scope.employees   = filterEmployee;
    $scope.size_groups = filterSizeGroup;
    $scope.sexs        = diablo_sex;
    $scope.seasons     = diablo_season;
    $scope.e_pay_types = purchaserService.extra_pay_types; 

    $scope.has_saved   = false;

    $scope.old_select  = {};
    $scope.select      = {};
    $scope.inventories = [];

    $scope.float_add  = diablo_float_add;
    $scope.float_sub  = diablo_float_sub;
    $scope.get_object = diablo_get_object;
    $scope.round      = diablo_round;

    $scope.setting    = {
	round: diablo_round_record
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory_new_detail/" + $routeParams.ppage);
    };

    $scope.p_round = function(shopId){
	// console.log(shopId);
	return diablo_base_setting(
	    "pround", shopId, base, parseInt, diablo_round_record);
    };
    // $('.table').floatThead();

    // pagination
    // $scope.colspan = 9;
    $scope.items_perpage = diablo_items_per_page();
    // $scope.default_page = 1;

    // $scope.get_page = function(page){
    // 	var length = $scope.inventories.length;
    // 	var begin = (page - 1) * $scope.items_perpage;
    // 	var end = begin + $scope.items_perpage > length ?
    // 	    length : begin + $scope.items_perpage;

    // 	var index = [];
    // 	for(var i=begin; i<end; i++){
    // 	    index.push(i);
    // 	}
    // 	return index;
    // };

    // $scope.get_inventory = function(index){
    // 	var invs = [];
    // 	angular.forEach(index, function(i){
    // 	    invs.push($scope.inventories[i]);
    // 	}) 
    // 	return invs;
    // };
    
    // $scope.page_changed = function(page){
    // 	// console.log(page);
    // 	$scope.current_page_index = $scope.get_page(page);
    // }; 

    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0.00;

	// var e_pay = 0;
	// if(angular.isDefined($scope.select.extra_pay)
	//    && $scope.select.extra_pay){
	//     e_pay = $scope.select.extra_pay;
	// }
	
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total      += parseInt(one.total);
	    if ($scope.setting.round === diablo_round_row){
		$scope.select.should_pay += $scope.round(one.org_price * one.total); 
	    } else {
		$scope.select.should_pay += one.org_price * one.total; 
	    }
	};

	$scope.select.should_pay = $scope.round($scope.select.should_pay);

	var e_pay = angular.isDefined($scope.select.e_pay)
	    ? parseFloat($scope.select.e_pay) : 0.00;

	var verificate = angular.isDefined($scope.select.verificate)
	    ? parseFloat($scope.select.verificate) : 0.00;
	
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay
	    + e_pay - $scope.select.has_pay - $scope.select.verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	// $scope.select.left_balance = $scope.float_add(
	//     $scope.select.should_pay,
	//     $scope.float_sub($scope.select.surplus, $scope.select.has_pay)); 
    };
    
    $scope.change_firm = function(){
	// console.log($scope.select.firm);
	$scope.select.surplus = parseFloat($scope.select.firm.balance);
	$scope.re_calculate();
	// $scope.refresh();
    };

    // $scope.today = function(){
    // 	return $.now();
    // };

    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };
    
    var in_sort = function(sorts, tag){
	for (var i=0, l=sorts.length; i<l;i ++){
	    if(tag.style_number === sorts[i].style_number
	       && tag.brand_id  === sorts[i].brand.id){
		if (!in_array(sorts[i].sizes, tag.size)){
		    sorts[i].sizes.push(tag.size)
		}

		var color = diablo_find_color(tag.color_id, filterColor);
		if (!diablo_in_colors(color, sorts[i].colors)){
		    sorts[i].colors.push(color)
		};
		// if (!in_array(sorts[i].colors, {cid:tag.color_id, name:tag.color})){
		//     sorts[i].colors.push({cid:tag.color_id, name:tag.color})
		// }
		
		sorts[i].amounts.push({
		    cid:tag.color_id, size:tag.size, count:tag.amount}); 
		sorts[i].total += tag.amount;
		return true;
	    } 
	}

	return false;
    };
    
    // get rsn detail
    var rsn     = $routeParams.rsn
    var promise = diabloPromise.promise;
    $q.all([
	promise(purchaserService.get_w_invnetory_new, rsn)(),
	promise(purchaserService.get_w_invnetory_new_amount, {rsn:rsn})()
    ]).then(function(result){
	console.log(result);
	// result[0] is the record detail
	// result[1] are the inventory detail that the record is included
	var base = result[0];
	var invs = result[1].data;

	$scope.old_select.rsn        = rsn;
	$scope.old_select.rsn_id     = base.id;
	$scope.old_select.firm       = $scope.get_object(base.firm_id,   $scope.firms);
	$scope.old_select.datetime   = diablo_set_datetime(base.entry_date); 
	
	// $scope.old_select.surplus    = $scope.old_select.firm.balance;
	$scope.old_select.shop       = $scope.get_object(base.shop_id,   $scope.shops);
	$scope.old_select.employee   = $scope.get_object(base.employee_id, $scope.employees);
	$scope.old_select.surplus    = base.balance;
	$scope.old_select.comment    = base.comment;
	$scope.old_select.total      = base.total;
	$scope.old_select.cash       = base.cash;
	$scope.old_select.card       = base.card;
	$scope.old_select.wire       = base.wire;
	$scope.old_select.verificate = base.verificate;
	$scope.old_select.should_pay = base.should_pay;
	$scope.old_select.has_pay    = base.has_pay;


	if (base.e_pay_type === -1){
	    $scope.old_select.e_pay_type = $scope.e_pay_types[0];
	    $scope.old_select.e_pay      = undefined;
	} else{
	    $scope.old_select.e_pay_type
		= diablo_get_object(base.e_pay_type, $scope.e_pay_types);
	    $scope.old_select.e_pay      = base.e_pay; 
	}
	
	// $scope.old_select.e_pay      = base.e_pay;
	// $scope.old_select.rsn        = base.rsn;

	$scope.select = angular.extend($scope.select, $scope.old_select);


	// base setting
	$scope.setting.round = $scope.p_round($scope.select.shop.id);

	var length = invs.length;
	var sorts  = [];
	for(var i = 0; i < length; i++){
	    if(!in_sort(sorts, invs[i])) {
		var add = {$edit:true, $new:false, sizes:[], colors:[], amounts:[]};
		add.style_number    = invs[i].style_number;
		add.brand           = $scope.get_object(invs[i].brand_id, $scope.brands);
		add.type            = $scope.get_object(invs[i].type_id, $scope.types);
		add.sex             = invs[i].sex,
		add.free            = invs[i].free,
		add.season          = invs[i].season;
		add.s_group         = invs[i].s_group;
		add.free_color_size = invs[i].free === 0 ? true : false;
		add.org_price       = invs[i].org_price;
		add.pkg_price       = invs[i].pkg_price;
		add.tag_price       = invs[i].tag_price;
		add.price3          = invs[i].price3;
		add.price4          = invs[i].price4;
		add.price5          = invs[i].price5;
		add.discount        = invs[i].discount;
		add.total           = invs[i].amount;
		
		add.sizes.push(invs[i].size);
		add.colors.push(
		    diablo_find_color(invs[i].color_id, filterColor));
		// add.colors.push({cid:invs[i].color_id, name:invs[i].color});
		add.amounts.push({
		    cid:invs[i].color_id,
		    size:invs[i].size,
		    count:invs[i].amount})
		sorts.push(add); 
	    } 
	}

	// console.log(sorts);
	$scope.old_inventories = sorts;
	
	var order_length = sorts.length;
	angular.forEach(sorts, function(s){
	    var tag = angular.copy(s);
	    tag.order_id = order_length;
	    if (tag.sizes.length !== 1 || tag.sizes[0] !=="0" ){
		tag.sizes = wgoodService.get_size_group(tag.s_group, filterSizeGroup); 
	    }
	    $scope.inventories.push(tag);
	    order_length--;
	})
	
	$scope.inventories.unshift({$edit:false, $new:true});

	// $scope.total_items = $scope.inventories.length; 
	// $scope.current_page_index = $scope.get_page($scope.default_page);

	console.log($scope.old_inventories);
	console.log($scope.inventories);
    });
    
    var reset_payment = function(newValue){
	// console.log("reset_payment", $scope.select);
	$scope.select.has_pay = 0.00;
	
	if(angular.isDefined($scope.select.cash) && $scope.select.cash){
	    $scope.select.has_pay += parseFloat($scope.select.cash);
	}

	if(angular.isDefined($scope.select.card) && $scope.select.card){
	    $scope.select.has_pay += parseFloat($scope.select.card);
	}

	if(angular.isDefined($scope.select.wire) && $scope.select.wire){
	    $scope.select.has_pay += parseFloat($scope.select.wire);
	}

	var verificate = 0.00; 
	if(angular.isDefined($scope.select.verificate)
	   && $scope.select.verificate){
	    verificate = parseFloat($scope.select.verificate); 
	}

	var e_pay = angular.isDefined($scope.select.e_pay)
	    ? $scope.select.e_pay : 0;
	
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay
	    + e_pay - $scope.select.has_pay - verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	
	// $scope.select.left_balance = $scope.float_add(
	//     $scope.select.should_pay,
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

    
    $scope.match_prompt_good = function(viewValue){
	return diabloFilter.match_wgood_with_firm(viewValue, $scope.select.firm.id); 
    }; 
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);

	// has been added
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand.id){
		diabloUtilsService.response_with_callback(
		    false, "采购单修改", "采购单修改失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}

	// add at first allways 
	var add = $scope.inventories[0];
	add.id           = item.id;
	add.style_number = item.style_number;
	add.brand        = $scope.get_object(item.brand_id, $scope.brands);
	// add.brand_id     = item.brand_id;
	add.type         = $scope.get_object(item.type_id, $scope.types);
	// add.type_id      = item.type_id;
	add.sex          = item.sex;
	// add.firm_id      = item.firm_id;
	add.season       = item.season;
	add.org_price    = item.org_price;
	add.tag_price    = item.tag_price;
	add.pkg_price    = item.pkg_price;
	add.price3       = item.price3;
	add.price4       = item.price4;
	add.price5       = item.price5;
	add.discount     = item.discount;
	add.s_group      = item.s_group;
	add.free         = item.free;
	add.sizes        = item.size.split(",");
	add.colors       = item.color.split(",");
	
	if ( add.free === 0 ){
	    add.free_color_size = true;
	    add.amounts = [{cid:0, size:0}];
	} else{
	    add.free_color_size = false;
	    add.amounts = []; 
	}

	console.log(add);

	if (!add.free_color_size){
	    $scope.add_inventory(add)
	};
    };

    var get_update_amount = function(newAmounts, oldAmounts){
	var changedAmounts = [];
	var found = false;
	for (var i=0, l1=newAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=oldAmounts.length; j < l2; j++){
		if (newAmounts[i].cid === oldAmounts[j].cid
		    && newAmounts[i].size === oldAmounts[j].size){
		    // update
		    found = true;
		    
		    var update_count = parseInt(newAmounts[i].count) - parseInt(oldAmounts[j].count);
		    if ( update_count !== 0 ){
			changedAmounts.push(
			    {operation: 'u',
			     cid:       newAmounts[i].cid,
			     size:      newAmounts[i].size,
			     count:     update_count})
		    }
		    
		    break;
		} 
	    }

	    // new
	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'a',
		     cid:       newAmounts[i].cid,
		     size:      newAmounts[i].size,
		     count:     parseInt(newAmounts[i].count)})
	    }
	}

	// delete
	for (var i=0, l1=oldAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=newAmounts.length; j < l2; j++){
		if (oldAmounts[i].cid === newAmounts[j].cid
		    && oldAmounts[i].size == newAmounts[j].size){
		    found = true;
		    break;
		} 
	    }

	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'd',
		     cid:       oldAmounts[i].cid,
		     size:      oldAmounts[i].size,
		     count:     parseInt(oldAmounts[i].count)})
	    }
	}

	console.log(changedAmounts);
	return changedAmounts;
    };
    
    var get_update_inventory = function(){
	var changedInvs = [];
	var found = false;
	for (var i=1, l1=$scope.inventories.length; i < l1; i++){
	    var newInv = $scope.inventories[i];
	    found = false;
	    for (var j=0, l2=$scope.old_inventories.length; j < l2; j++){
		var oldInv = $scope.old_inventories[j];
		// update
		if (newInv.style_number === oldInv.style_number
		    && newInv.brand.id === oldInv.brand.id){
		    var change_amouts = get_update_amount(newInv.amounts, oldInv.amounts);
		    if (change_amouts.length !== 0){
			newInv.operation = 'u';
			// newInv.old_total = oldInv.total;
			newInv.changed_amounts = change_amouts;
			changedInvs.push(newInv);
		    } else {
			// console.log(newInv);
			// console.log(oldInv);
			if (parseFloat(newInv.org_price) !== oldInv.org_price
			    || parseFloat(newInv.discount) !== oldInv.discount){
			    newInv.operation = 'u';
			    changedInvs.push(newInv);
			}
		    }
		    found = true;
		    break;
		} 
	    }
	    
	    if ( !found ){
		// add
		newInv.operation = 'a';
		changedInvs.push(newInv);
	    } 
	}

	// deleted
	for (var i=0, l1=$scope.old_inventories.length; i < l1; i++){
	    var oldInv = $scope.old_inventories[i];
	    found = false;
	    for (var j=1, l2=$scope.inventories.length; j < l2; j++){
		var newInv = $scope.inventories[j];
		// console.log(oldInv);
		// console.log(newInv);
		if (oldInv.style_number === newInv.style_number
		    && oldInv.brand.id === newInv.brand.id){
		    found = true;
		    break;
		} 
	    }
	    
	    if ( !found ){
		oldInv.operation = 'd';
		changedInvs.push(oldInv);
	    }
	} 

	console.log(changedInvs);
	return changedInvs;
    }; 

    // save
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
		false, "采购单修改", "采购单修改失败：" + purchaserService.error[2096]);
	    return;
	};

	var updates = get_update_inventory();
	console.log(updates);
	
	var added = [];
	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];
	    added.push({
		// good           : add.id,
		style_number   : add.style_number,
		brand          : add.brand.id,
		// firm           : add.firm.id,
		type           : add.type.id,
		sex            : add.sex,
		season         : add.season,
		changed_amount : add.changed_amounts,
		operation      : add.operation,
		amount         : function(){
		    if (add.operation === 'd' || add.operation === "a"){
			return add.amounts
		    }}(),
		s_group        : add.s_group,
		free           : add.free,
		org_price      : parseFloat(add.org_price),
		tag_price      : parseFloat(add.tag_price), 
		pkg_price      : parseFloat(add.pkg_price),
		p3             : parseFloat(add.price3),
		p4             : parseFloat(add.price4),
		p5             : parseFloat(add.price5),
		discount       : parseInt(add.discount),
		total          : add.total
		// old_total      : add.old_total
	    })
	};

	var setv = diablo_set_float; 
	var new_datetime = dateFilter($scope.select.datetime, "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.datetime, "yyyy-MM-dd");
	
	if (added.length === 0
	    && ($scope.select.cash === $scope.old_select.cash
		&& $scope.select.card === $scope.old_select.card
		&& $scope.select.wire === $scope.old_select.wire
		&& $scope.select.verificate === $scope.old_select.verificate
		&& $scope.select.employee.id === $scope.old_select.employee.id
		&& $scope.select.shop.id === $scope.old_select.shop.id
		&& $scope.select.comment === $scope.old_select.comment
		&& $scope.select.firm.id === $scope.old_select.firm.id
		&& new_datetime === old_datetime)){
	    diabloUtilsService.response(
	    	false, "采购单编辑", "采购单编辑失败：" + purchaserService.error[2094]);
	    return;
	}

	var base = {
	    id:             $scope.select.rsn_id,
	    rsn:            $scope.select.rsn,
	    firm:           $scope.select.firm.id,
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    // date:           dateFilter($scope.select.date, "yyyy-MM-dd"),
	    employee:       $scope.select.employee.id,
	    comment:        diablo_set_string($scope.select.comment),
	    total:          diablo_set_integer($scope.select.total),
	    balance:        parseFloat($scope.select.surplus), 
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wire:           setv($scope.select.wire),
	    verificate:     setv($scope.select.verificate),
	    e_pay:          setv($scope.select.e_pay),
	    should_pay:     setv($scope.select.should_pay),
	    has_pay:        setv($scope.select.has_pay),
	    
	    old_firm:       $scope.old_select.firm.id,
	    old_balance:    setv($scope.old_select.surplus),
	    old_verify_pay: setv($scope.old_select.verificate),
	    old_should_pay: setv($scope.old_select.should_pay),
	    old_has_pay:    setv($scope.old_select.has_pay),
	    old_datetime:   dateFilter($scope.old_select.datetime, "yyyy-MM-dd HH:mm:ss"),
	};

	console.log(added);
	console.log(base);

	purchaserService.update_w_inventory_new({
	    inventory: added.length === 0 ? undefined: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
		    true, "采购单修改", "采购单修改成功！！单号：" + state.rsn,
		    $scope, function(){diablo_goto_page("#/inventory_new_detail")})
	    	return;
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "采购单修改",
	    	    "采购单修改失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
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
	    // add new line
	    $scope.inventories.unshift({$edit:false, $new:true});

	    // pagination
	    // $scope.total_items = $scope.inventories.length; 
	    // $scope.current_page_index = $scope.get_page($scope.current_page);
	    $scope.re_calculate(); 
	};
	
	var callback = function(params){
	    var result    = add_callback(params);
	    
	    inv.amounts   = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    after_add();
	} 
	
	if(inv.free_color_size){
	    inv.total = inv.amounts[0].count;
	    after_add();
	} else{
	    var payload = {sizes:        inv.sizes,
			   amount:       inv.amounts,
			   org_price:    inv.org_price,
			   get_amount:   get_amount,
			   valid_amount: valid_amount};
	    
	    if (inv.colors.length === 1 && inv.colors[0] === "0"){
		inv.colors = [{cid:0}];
		payload.colors = inv.colors;
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", undefined, callback, $scope, payload)
	    } else{
		inv.colors = inv.colors.map(function(cid){
		    return diablo_find_color(parseInt(cid), filterColor); 
		});
		
		payload.colors = inv.colors;
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", diablo_valid_dialog(inv.sizes),
		    callback, $scope, payload);
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
	// $scope.total_items = $scope.inventories.length; 
	// $scope.current_page_index = $scope.get_page($scope.current_page);

	$scope.re_calculate(); 
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:      inv.sizes,
		       amount:     inv.amounts,
		       org_price:  inv.org_price,
		       colors:     inv.colors,
		       get_amount: get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.update_directory = true;
	    return; 
	}
	
	var callback = function(params){
	    var result    = add_callback(params);
	    inv.amounts   = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    
	    // pagination
	    // $scope.current_page_index = $scope.get_page($scope.current_page); 
	    $scope.re_calculate(); 
	};
	
	var payload = {sizes: inv.sizes,
		       amount: inv.amounts,
		       org_price: inv.org_price,
		       colors: inv.colors,
		       get_amount: get_amount,
		       valid_amount: valid_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-new.html", undefined, callback, $scope, payload)
    };

    $scope.save_update = function(inv){
	inv.$update = false;
	inv.update_directory = false;
	
	if (inv.free_color_size){
	    inv.total = inv.amounts[0].count;
	} //else{
	    $scope.re_calculate()
	// }; 
    }

    $scope.reset_inventory = function(inv){
	// inv.$reset = true; 
	// console.log($scope.inventories);
	$scope.inventories[0] = {$edit:false, $new:true};
	// $scope.current_inventories = $scope.get_page($scope.current_page); 
	// $scope.current_page_index = $scope.get_page($scope.current_page);
    } 
    
});
