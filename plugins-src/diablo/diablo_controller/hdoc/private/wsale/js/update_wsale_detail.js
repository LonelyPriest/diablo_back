wsaleApp.controller("wsaleUpdateDetailCtrl", function(
    $scope, $routeParams, $q, dateFilter, diabloUtilsService,
    diabloPromise, diabloFilter, diabloPattern,
    wgoodService, purchaserService, wretailerService, wsaleService,
    user, filterRetailer, filterEmployee, filterSizeGroup,
    filterBrand, filterColor, filterType, base){
    console.log(user);

    $scope.pattern     = {money: diabloPattern.decimal_2};
    $scope.shops       = user.sortShops;
    $scope.retailers   = filterRetailer; 
    $scope.employees   = filterEmployee;
    $scope.size_groups = filterSizeGroup;
    $scope.brands      = filterBrand;
    $scope.types       = filterType;
    $scope.sexs        = diablo_sex;
    $scope.seasons     = diablo_season;
    $scope.sell_styles = diablo_sell_style;
    $scope.e_pay_types = wsaleService.extra_pay_types;
    $scope.round       = diablo_round;
    
    $scope.setting     = {
	q_backend:true,
	show_discount:true,
	check_sale:true,
	trace_price:true,
	round: diablo_round_record};

    // $scope.old_base    = {};
    $scope.old_select  = {};
    
    $scope.select      = {}; 
    $scope.inventories = [];
    
    $scope.f_add  = diablo_float_add;
    $scope.f_sub  = diablo_float_sub;
    $scope.f_mul  = diablo_float_mul;
    $scope.get_object = diablo_get_object;

    $scope.show_discount = function(){
	return diablo_base_setting(
	    "show_discount", $scope.select.shop.id, base, parseInt, diablo_yes);
    };

    $scope.trace_price = function(shopId){
	return diablo_base_setting(
	    "ptrace_price", shopId, base, parseInt, diablo_no); 
    };

    $scope.p_round = function(){
	return diablo_base_setting(
	    "pround", $scope.select.shop.id, base, parseInt, diablo_round_record);
    };

    $scope.check_sale = function(shopId){
	return diablo_base_setting(
	    "check_sale", shopId, base, parseInt, diablo_yes);
    };

    $scope.go_back = function(){
	diablo_goto_page("#/new_wsale_detail/" + $routeParams.ppage);
    };

    // pagination
    $scope.colspan = 9;
    $scope.items_perpage = 10;
    $scope.default_page = 1;

    $scope.get_page = function(page){
	var length = $scope.inventories.length;
	var begin = (page - 1) * $scope.items_perpage;
	var end = begin + $scope.items_perpage > length ?
	    length : begin + $scope.items_perpage;

	var index = [];
	for(var i=begin; i<end; i++){
	    index.push(i);
	}
	return index;
    };

    $scope.get_inventory = function(index){
	var invs = [];
	angular.forEach(index, function(i){
	    invs.push($scope.inventories[i]);
	}) 
	return invs;
    };

    $scope.get_sell_style = function(id){
    	for (var i=0, l=$scope.sell_styles.length; i<l; i++){
    	    if ($scope.sell_styles[i].id === id){
    		return $scope.sell_styles[i];
    	    }
    	}
    };

    // $scope.recover_sell_style = function(inv){
    // 	console.log(inv);
    // 	return $scope.get_sell_style(inv.sell_style_id); 
    // }
    
    
    
    $scope.page_changed = function(page){
	// console.log(page);
	$scope.current_page_index = $scope.get_page(page);
    }; 

    $scope.re_calculate = function(){
	// console.log("re_calculate");
	$scope.select.total = 0;
	$scope.select.abs_total = 0;
	$scope.select.should_pay = 0.00;

	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total      += parseInt(one.sell);
	    $scope.select.abs_total  += Math.abs(parseInt(one.sell));

	    if ($scope.setting.round === diablo_round_row){
		$scope.select.should_pay
		    += $scope.round(
			one.fprice * one.fdiscount * 0.01 * one.sell);
	    } else {
		$scope.select.should_pay
		    += one.fprice * one.fdiscount * 0.01 * one.sell; 
	    }
	    
	    // $scope.select.should_pay
	    // 	+= $scope.round(one.fprice * one.sell * one.fdiscount * 0.01);
	}

	$scope.select.should_pay = $scope.round($scope.select.should_pay);

	var e_pay = angular.isDefined(diablo_set_float($scope.select.e_pay))
	    ? $scope.select.e_pay : 0;
	
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay + e_pay
	    - $scope.select.has_pay - $scope.select.verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	// $scope.select.left_balance = $scope.float_add(
	//     $scope.select.should_pay,
	//     $scope.float_sub($scope.select.surplus, $scope.select.has_pay));
    };
    
    $scope.change_retailer = function(){
	$scope.select.surplus = $scope.select.retailer.balance;
	$scope.re_calculate(); 
    }
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    // $scope.today = function(){
    // 	return $.now();
    // }; 
    
    var in_sell = function(sells, tag){
	for(var i=0, l=sells.length; i<l; i++){
	    if (tag.style_number === sells[i].style_number
		&& tag.brand_id  === sells[i].brand_id
		&& tag.color_id  === sells[i].color_id
		&& tag.size      === sells[i].size){

		tag.sell       = sells[i].amount;
		tag.sell_style = $scope.get_object(sells[i].sell_style, $scope.sell_styles);
		// tag.sell_style = sells[i].sell_style;
		tag.fprice     = sells[i].fprice;
		tag.fdiscount  = sells[i].fdiscount;
		break;
	    }
	}

	return tag;
    };
    
    var in_sort = function(sorts, tag){
	for (var i=0, l=sorts.length; i<l;i ++){
	    if(tag.style_number === sorts[i].style_number
	       && tag.brand_id  === sorts[i].brand.id){
		
		sorts[i].total += tag.amount;

		if (angular.isDefined(tag.sell)){
		    if (angular.isUndefined(sorts[i].sell)){
			sorts[i].sell       = tag.sell;
			sorts[i].sell_style = tag.sell_style;
			sorts[i].fdiscount  = tag.fdiscount;
			sorts[i].fprice     = tag.fprice;
		    } else {
			sorts[i].sell  += tag.sell; 
		    }
		}

		if (!in_array(sorts[i].sizes, tag.size)){
		    sorts[i].sizes.push(tag.size)
		}

		// var cname = diablo_get_object(tag.color_id, filterColor).name
		var color = diablo_find_color(tag.color_id, filterColor);
		if (!diablo_in_colors(color, sorts[i].colors)){
		    sorts[i].colors.push(color)
		};
		
		sorts[i].amounts.push({
		    cid:tag.color_id,
		    size:tag.size,
		    count:tag.amount,
		    sell_count:tag.sell}); 
		return true;
	    } 
	}

	return false;
    }; 

    // rsn detail
    var rsn     = $routeParams.rsn
    var promise = diabloPromise.promise;
    wsaleService.get_w_sale_new(rsn).then(function(result){
    // $q.all([
    // 	promise(wsaleService.get_w_sale_new, rsn)(),
    // 	promise(wsaleService.w_sale_rsn_detail, {rsn:rsn})()
    // ]).then(function(result){
	console.log(result);
	if (result.ecode === 0){
	    // result[0] is the record detail
	    // result[1] are the inventory detail that the record is included
	    var base        = result.sale;
	    var invs        = result.inv;
	    var sell_detail = result.detail; 

	    // var date = base.entry_date.substr(0,10).split("-")
	    // var time = base.entry_date.substr(11, 8).split(":");
	    // console.log(datetime);
	    $scope.old_select.rsn      = base.rsn;
	    $scope.old_select.rsn_id   = base.id;
	    $scope.old_select.datetime = diablo_set_datetime(base.entry_date);
	    // $scope.old_select.datetime   = new Date(
	    // 	date[0], date[1]-1, date[2], time[0], time[1], time[2]);
	    $scope.old_select.retailer = $scope.get_object(
		base.retailer_id, $scope.retailers);

	    if (base.e_pay_type === -1){
		$scope.old_select.e_pay_type = $scope.e_pay_types[0];
		$scope.old_select.e_pay      = undefined;
	    } else{
		$scope.old_select.e_pay_type
		    = diablo_get_object(base.e_pay_type, $scope.e_pay_types);
		$scope.old_select.e_pay      = base.e_pay; 
	    }

	    console.log($scope.old_select);
	    // $scope.old_select.surplus    = $scope.old_select.retailer.balance;
	    $scope.old_select.surplus    = base.balance;
	    $scope.old_select.shop       = $scope.get_object(base.shop_id,   $scope.shops);
	    $scope.old_select.employee   = $scope.get_object(base.employ_id, $scope.employees);
	    $scope.old_select.comment    = base.comment;
	    $scope.old_select.total      = base.total;
	    $scope.old_select.cash       = base.cash;
	    $scope.old_select.card       = base.card;
	    $scope.old_select.wire       = base.wire;
	    $scope.old_select.verificate = base.verificate;
	    $scope.old_select.should_pay = base.should_pay;
	    $scope.old_select.has_pay    = base.has_pay;

	    $scope.select = angular.extend($scope.select, $scope.old_select);
	    $scope.select.abs_total = 0;

	    // setting
	    $scope.setting.check_sale    = $scope.check_sale($scope.select.shop.id);
	    $scope.setting.trace_price   = $scope.trace_price($scope.select.shop.id);
	    $scope.setting.show_discount = $scope.show_discount();
	    $scope.setting.round         = $scope.p_round();
	    console.log($scope.setting);

	    // console.log($scope.select);

	    var length = invs.length;
	    var sorts  = [];
	    for(var i = 0; i < length; i++){
		var inv  = in_sell(sell_detail, invs[i]);
		
		if(!in_sort(sorts, inv)) {
		    var add = {$edit:true, $new:false, sizes:[], colors:[], amounts:[]};

		    add.style_number    = inv.style_number;
		    add.brand           = $scope.get_object(inv.brand_id, $scope.brands);
		    add.type            = $scope.get_object(inv.type_id, $scope.types);
		    // add.sex             = inv.sex,
		    add.firm_id         = inv.firm_id;
		    add.free            = inv.free,
		    add.season          = inv.season;
		    add.s_group         = inv.s_group;
		    add.free_color_size = inv.free === 0 ? true : false;
		    // add.org_price       = inv.org_price;
		    add.pkg_price       = inv.pkg_price;
		    add.tag_price       = inv.tag_price;
		    add.price3          = inv.price3;
		    add.price4          = inv.price4;
		    add.price5          = inv.price5;
		    add.total           = inv.amount;
		    add.path            = inv.path;

		    // 
		    add.sell_style      = inv.sell_style;
		    // add.sell_style      = $scope.get_object(inv.sell_style, $scope.sell_styles);
		    add.fdiscount       = inv.fdiscount;
		    add.fprice          = inv.fprice;
		    add.sell            = inv.sell; 

		    add.sizes.push(invs[i].size); 
		    add.colors.push(diablo_find_color(inv.color_id, filterColor));
		    
		    add.amounts.push({
			cid:inv.color_id,
			size:inv.size,
			count:inv.amount,
			sell_count:inv.sell});
		    sorts.push(add); 
		} 
	    }

	    // console.log(sorts);
	    $scope.old_inventories = sorts;

	    var order_length = sorts.length;
	    angular.forEach(sorts, function(s){
		var tag = angular.copy(s);
		s.amounts = s.amounts.filter(function(a){
		    if (angular.isDefined(a.sell_count) && a.sell_count !== 0){
			return true;
		    }
		});
		
		tag.order_id = order_length;
		if (tag.sizes.length !== 1 || tag.sizes[0] !=="0" ){
		    tag.sizes = wgoodService.get_size_group(tag.s_group, filterSizeGroup); 
		}
		$scope.inventories.push(tag);
		order_length--;
	    })
	    
	    $scope.inventories.unshift({$edit:false, $new:true});

	    $scope.re_calculate();

	    $scope.total_items = $scope.inventories.length; 
	    $scope.current_page_index = $scope.get_page($scope.default_page);

	    console.log($scope.old_inventories);
	    console.log($scope.inventories);
	}
	
    });

    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    };

    $scope.copy_select = function(add, src){
	add.id           = src.id;
	add.style_number = src.style_number;
	add.brand        = $scope.get_object(src.brand_id, $scope.brands);
	// add.brand_id     = src.brand_id;
	// add.type         = src.type;
	add.type         = $scope.get_object(src.type_id, $scope.types);
	// add.type_id      = src.type_id;
	add.firm_id      = src.firm_id;
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;

	// add.org_price    = good.org_price;
	add.tag_price    = src.tag_price;
	add.pkg_price    = src.pkg_price;
	add.price3       = src.price3;
	add.price4       = src.price4;
	add.price5       = src.price5;
	add.discount     = src.discount;
	add.path         = src.path;
	
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.sell_style   = $scope.sell_styles[0]; 
	// add.amount       = []; 
	// if ( (add.all_colors.length === 1 && add.all_colors[0] === "0")
	//      && (add.all_sizes.length === 1 && add.all_sizes[0] === "0") ){
	//     add.free_color_size = true;
	//     // add.amount = [{cid:0, size:0}];
	// } else{
	//     add.free_color_size = false;
	//     // add.amount = [];
	// } 
	return add;
	
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);
	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand.id){
		diabloUtilsService.response_with_callback(
		    false, "销售单编辑", "销售单编辑失败：" + wsaleService.error[2191],
		$scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	};
	
	// add at first allways 
	var add = $scope.inventories[0];
	add = $scope.copy_select(add, item); 

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

	// console.log($scope.select);
	// any payment of cash, card or wire or any inventory
	if (angular.isDefined(diablo_set_float($scope.select.cash))
	    || angular.isDefined(diablo_set_float($scope.select.card))
	    || angular.isDefined(diablo_set_float($scope.select.wire))
	    || angular.isDefined(diablo_set_float($scope.select.verificate))
	    || angular.isDefined(diablo_set_string($scope.select.comment))
	    || $scope.inventories.length !== 1
	   ){
	    return false;
	} 

	return true;
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
		    
		    var update_count = parseInt(newAmounts[i].sell_count)
			- parseInt(oldAmounts[j].sell_count);
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
		     count:     parseInt(newAmounts[i].sell_count)})
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
		     count:     parseInt(oldAmounts[i].sell_count)})
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
		    var sort_amounts = newInv.amounts.filter(function(a){
			if (angular.isDefined(a.sell_count)
			    && a.sell_count
			    && parseInt(a.sell_count) !== 0){
			    return true;
			}
		    });
		    var change_amouts = get_update_amount(sort_amounts, oldInv.amounts);
		    if (change_amouts.length !== 0){
			newInv.operation = 'u'; 
			newInv.changed_amounts = change_amouts;
			changedInvs.push(newInv);
		    } else {
			// console.log(newInv);
			// console.log(oldInv);
			if (parseFloat(newInv.fprice) !== oldInv.fprice
			    || parseFloat(newInv.fdiscount) !== oldInv.fdiscount){
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
    
    $scope.save_wsale = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories); 
	console.log($scope.select);
	
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response(
		false, "销售单编辑", "销售单编辑失败：" + wsaleService.error[2192]);
	    return;
	}; 

	var updates = get_update_inventory();
	console.log(updates);
	var added = [];
	
	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];
	    added.push({
		id             : add.id,
		style_number   : add.style_number,
		brand          : add.brand.id,
		brand_name     : add.brand,
		type           : add.type.id,
		// type_name   : add.type,
		firm           : add.firm_id,
		sex            : add.sex,
		season         : add.season,
		year           : add.year,
		changed_amount : add.changed_amounts,
		operation      : add.operation,
		amount         : function(){
		    if (add.operation === 'd' || add.operation === "a"){
			return add.amounts.filter(function(a){
			    if (angular.isDefined(a.sell_count)
				&& a.sell_count
				&& parseInt(a.sell_count) !== 0){
				return true;
			    }
			})
		    }}(),
		sell_total     : parseInt(add.sell),
		fdiscount      : parseInt(add.fdiscount),
		fprice         : parseFloat(add.fprice),
		path           : add.path,

		sizes          : add.sizes,
		s_group        : add.s_group,
		colors         : add.colors,
		free           : add.free,
		
		sell_style     : add.sell_style.id, 
	    })
	};

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;
	
	var base = {
	    id:            $scope.select.rsn_id,
	    rsn:           $scope.select.rsn,
	    retailer:      $scope.select.retailer.id,
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id, 
	    balance:       parseFloat($scope.select.surplus),
	    
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wire:           setv($scope.select.wire),
	    verificate:     setv($scope.select.verificate),
	    e_pay:          setv($scope.select.e_pay),
	    should_pay:     setv($scope.select.should_pay),
	    has_pay:        setv($scope.select.has_pay),
	    comment:        sets($scope.select.comment),

	    old_retailer:   $scope.old_select.retailer.id, 
	    old_balance:    $scope.old_select.surplus,
	    old_verify_pay: $scope.old_select.verificate,
	    old_should_pay: $scope.old_select.should_pay,
	    old_has_pay:    $scope.old_select.has_pay, 
	    old_datetime:   dateFilter($scope.old_select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    
	    // left_balance:  parseFloat($scope.select.left_balance),
	    total:         seti($scope.select.total)
	};

	// var print = {
	//     shop:     $scope.select.shop.name,
	//     employ:   $scope.select.employee.name,
	//     retailer: $scope.select.retailer.name
	// };

	console.log(added);
	console.log(base);
	
	console.log($scope.old_select);
	var new_datetime = dateFilter($scope.select.datetime, "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.datetime, "yyyy-MM-dd");
	if (added.length === 0
	    && ($scope.select.cash === $scope.old_select.cash
		&& $scope.select.card === $scope.old_select.card
		&& $scope.select.wire === $scope.old_select.wire
		&& $scope.select.verificate === $scope.old_select.verificate
		&& $scope.select.employee.id === $scope.old_select.employee.id
		&& $scope.select.shop.id === $scope.old_select.shop.id
		&& $scope.select.retailer.id === $scope.old_select.retailer.id
		&& $scope.select.comment === $scope.old_select.comment
		&&  new_datetime === old_datetime)){
	    diabloUtilsService.response_with_callback(
	    	false, "销售单编辑", "销售单编辑失败：" + wsaleService.error[2699],
		undefined, function() {$scope.has_saved = false});
	    return; 
	};

	// return;

	// $scope.has_saved = true;
	wsaleService.update_w_sale_new({
	    inventory:added.length === 0 ? undefined : added, base:base
	}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
		msg = "销售单编辑成功！！单号：" + result.rsn; 
	    	diabloUtilsService.response_with_callback(
	    	    true, "销售单编辑", msg, $scope,
	    	    function(){
			// $scope.has_saved = true;
			// modify current balance of retailer
			// $scope.select.retailer.balance = $scope.select.left_balance;
			// $scope.select.surplus = $scope.select.retailer.balance;
			// diablo_goto_page("#/wsale/new_wsale_detail");
			$scope.go_back();
		    })
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "销售单编辑", "销售单编辑失败：" + wsaleService.error[result.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };

    // watch balance
    var reset_payment = function(newValue){
	// console.log("reset_payment newValue ", newValue);
	$scope.select.has_pay = 0.00;
	var verificate = 0.00;
	
	if(angular.isDefined($scope.select.cash) && $scope.select.cash){
	    $scope.select.has_pay
		+= parseFloat($scope.select.cash);
	}
	
	if(angular.isDefined($scope.select.card) && $scope.select.card){
	    $scope.select.has_pay
		+= parseFloat($scope.select.card);
	}

	if(angular.isDefined($scope.select.wire) && $scope.select.wire){
	    $scope.select.has_pay
		+= parseFloat($scope.select.wire);
	}

	if(angular.isDefined($scope.select.verificate)
	   && $scope.select.verificate){
	    verificate = parseFloat($scope.select.verificate); 
	}

	var e_pay = angular.isDefined(diablo_set_float($scope.select.e_pay))
	    ? $scope.select.e_pay : 0;

	$scope.select.left_balance
	    = $scope.select.surplus + $scope.select.should_pay + e_pay
	    - $scope.select.has_pay - verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	// console.log($scope.float_add);
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

    /*
     * add
     */
    // $scope.valid_free_size_sell = function(inv){
    // 	if (angular.isDefined(inv.sell)
    // 	    && inv.sell > inv.total){
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
	return undefined;
    }; 

    var valid_sell = function(amount){
	var count = amount.sell_count; 
	if (angular.isUndefined(count)){
	    return true;
	}

	if (!count) {
	    return true;
	}
	
	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	// if (renumber.test(count) && amount.count >= amount.sell_count){
	// 	return true;
	// } 

	if (renumber.test(count)){
	    return true;
	}
	
	return false
    };
    
    var valid_all_sell = function(amounts){
	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	var unchanged = 0;

	for(var i=0, l=amounts.length; i<l; i++){
	    var count = amounts[i].sell_count; 
	    if (angular.isUndefined(count)){
		unchanged++;
		continue;
	    }

	    if (!count){
		unchanged++;
		continue;
	    }

	    // console.log(count)
	    // if (!renumber.test(count) || amounts[i].count < parseInt(count)){
	    // 	return false;
	    // }
	    if (!renumber.test(count)){
		return false;
	    } 
	};

	return unchanged === l ? false : true;

    };

    var add_callback = function(params){
	console.log(params.amounts);
	
	var sell_total = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += parseInt(a.sell_count);
	    }
	})

	return {amounts:     params.amounts,
		sell_style:  params.sell_style,
		sell:        sell_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice};
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].sell_count = inv.sell;
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true});
	
	$scope.re_calculate(); 
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv);
	if ($scope.setting.check_sale == diablo_no
	    && $scope.setting.trace_price === diablo_no
	    && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount       = inv.discount;
	    inv.fprice          = inv[inv.sell_style.f];
	    inv.amounts         = [{cid:0, size:0}];
	} else {
	    var promise   = diabloPromise.promise;
	    var condition = {style_number: inv.style_number,
			     brand: inv.brand.id,
			     shop: $scope.select.shop.id}; 
	    var calls     = [];

	    if ($scope.setting.check_sale === diablo_yes || inv.free !== 0){
		calls.push(promise(purchaserService.list_purchaser_inventory,
				  condition)());
	    };

	    if ($scope.setting.trace_price === diablo_yes){
		calls.push(promise(
		    wsaleService.get_last_sale,
		    angular.extend({
			retailer: $scope.select.retailer.id}, condition))());
	    };
	    
	    $q.all(calls).then(function(data){
		console.log(data);
		// data[0] is the inventory belong to the shop
		// data[1] is the last sale of the shop

		if ($scope.setting.check_sale === diablo_yes
		    || inv.free !== 0){
		    var shop_now_inv = data[0];

		    var order_sizes = wgoodService.format_size_group(
			inv.s_group, filterSizeGroup);
		    var sort = purchaserService.sort_inventory(
			shop_now_inv, order_sizes, filterColor);
		    
		    inv.total   = sort.total;
		    inv.sizes   = sort.size;
		    inv.colors  = sort.color;
		    inv.amounts = sort.sort; 
		    
		    console.log(inv.sizes)
		    console.log(inv.colors);
		    console.log(inv.amounts);
		};
		
		
		// if (shop_now_inv.length === 0 ){
		//     diabloUtilsService.response(
		// 	false, "销售开单", "开单失败：" + wsaleService.error[2190]);
		//     return;
		// };

		

		// last sale info
		if ($scope.setting.trace_price === diablo_yes){
		    var shop_last_inv = function(){
			if ($scope.setting.check_sale === diablo_yes
			    || inv.free !== 0){
			    return data[1];
			} else {
			    return data[0];
			}
		    }();

		    inv.lprice    = shop_last_inv.length === 0
			? undefined:shop_last_inv[0].fprice;
		    inv.ldiscount = shop_last_inv.length === 0
			? undefined:shop_last_inv[0].discount;
		    inv.fdiscount = inv.ldiscount
			? inv.ldiscount : inv.discount;
		    inv.fprice    = inv.lprice
			? inv.lprice : inv[inv.sell_style.f];
		} else {
		    inv.fdiscount   = inv.discount;
		    inv.fprice      = inv[inv.sell_style.f];
		} 

		if(inv.free === 0){
		    inv.free_color_size = true;
		} else{
		    inv.free_color_size = false;

		    var after_add = function(){
			inv.$edit = true;
			inv.$new = false;
			// oreder
			inv.order_id = $scope.inventories.length; 
			// add new line
			$scope.inventories.unshift({$edit:false, $new:true});
			
			$scope.re_calculate(); 
		    };
		    
		    var callback = function(params){
			var result  = add_callback(params);
			console.log(result);
			inv.amounts    = result.amounts;
			inv.sell_style = result.sell_style;
			inv.sell       = result.sell;
			inv.fdiscount  = result.fdiscount;
			inv.fprice     = result.fprice;
			after_add();
		    };
		    
		    var payload = {
			// last_discount:  inv.last_discount,
			// last_fprice:    inv.last_fprice,
			sell_styles:    $scope.sell_styles,
			sell_style:     inv.sell_style,
			fdiscount:      inv.fdiscount,
			fprice:         inv.fprice,
			sizes:          inv.sizes,
			colors:         inv.colors,
			amounts:        inv.amounts,
			path:           inv.path,
			get_amount:     get_amount,
			get_price:      function(name){return inv[name]},
			valid_sell:     valid_sell,
			valid:          valid_all_sell};

		    diabloUtilsService.edit_with_modal(
			"wsale-new.html", inv.sizes.length >= 6 ? "lg":undefined,
			callback, $scope, payload); 
		}; 
	    });
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

	$scope.re_calculate(); 
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "wsale-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	console.log(inv);
	// inv.$update = true; 
	if (inv.free_color_size){
	    inv.sell_style  = $scope.get_object(inv.sell_style.id, $scope.sell_styles);
	    inv.free_update = true;
	    return;
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result);
	    inv.amounts    = result.amounts;
	    inv.sell_style = result.sell_style;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;
	    $scope.re_calculate(); 
	};

	var payload = {sell_styles:  $scope.sell_styles,
		       sell_style:   inv.sell_style,
		       fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount,
		       get_price:    function(name){return inv[name]},
		       valid_sell:   valid_sell,
		       valid:        valid_all_sell}; 
	diabloUtilsService.edit_with_modal(
	    "wsale-new.html", inv.sizes.length >= 6 ? "lg":undefined,
	    callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false; 
	inv.amounts[0].sell_count = inv.sell;
	$scope.re_calculate(); 
    }

    $scope.cancel_free_update = function(inv){
	inv.free_update = false;
	inv.sell = inv.amounts[0].sell_count;
	$scope.re_calculate(); 
    }

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true};;
    }
})
