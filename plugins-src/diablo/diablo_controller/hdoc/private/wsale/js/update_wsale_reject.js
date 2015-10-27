wsaleApp.controller("wsaleUpdateRejectCtrl", function(
    $scope, $q, $routeParams, dateFilter, diabloUtilsService, diabloPromise,
    diabloFilter, wgoodService, purchaserService, wsaleService,
    user, filterRetailer, filterEmployee, filterSizeGroup,
    filterBrand, filterColor, filterType, base){
    // console.log(base);
    // console.log(user); 
    $scope.shops           = user.sortBadRepoes.concat(user.sortShops);
    $scope.retailers       = filterRetailer; 
    $scope.employees       = filterEmployee;
    $scope.size_groups     = filterSizeGroup;
    $scope.brands          = filterBrand;
    $scope.types           = filterType;
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    $scope.e_pay_types     = wsaleService.extra_pay_types;
    $scope.sell_styles     = diablo_sell_style;

    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.get_object      = diablo_get_object;
    $scope.round           = diablo_round;
    
    $scope.setting  = {q_backend:true,
		       show_discount:true,
		       check_sale:true,
		       trace_price:true,
		       round:diablo_round_record};
    
    var dialog      = diabloUtilsService;

    $scope.go_back = function(){
	diablo_goto_page("#/new_wsale_detail/" + $routeParams.ppage);
    };

    $scope.show_discount = function(){
	return diablo_base_setting(
	    "show_discount", $scope.select.shop.id, base, parseInt, diablo_yes);
    };

    $scope.p_round = function(){
	return diablo_base_setting(
	    "pround", $scope.select.shop.id, base, parseInt, diablo_round_record);
    };
    
    $scope.check_sale = function(shopId){
	return diablo_base_setting(
	    "check_sale", shopId, base, parseInt, diablo_yes);
    };

    $scope.trace_price = function(shopId){
	return diablo_base_setting(
	    "ptrace_price", shopId, base, parseInt, diablo_no); 
    };
    
    $scope.old_select  = {};
    $scope.select      = {}; 
    $scope.inventories = []; 

    $scope.change_retailer = function(){
	$scope.select.surplus = parseFloat($scope.select.retailer.balance);
	$scope.re_calculate();
	// $scope.refresh();
    };
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    /*
     * get reject by rsn
     */
    var in_sell = function(sells, tag){
	for(var i=0, l=sells.length; i<l; i++){
	    if (tag.style_number === sells[i].style_number
		&& tag.brand_id  === sells[i].brand_id
		&& tag.color_id  === sells[i].color_id
		&& tag.size      === sells[i].size){

		tag.sell       = Math.abs(sells[i].amount);
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
	console.log(result);
	if (result.ecode === 0){
	    // result[0] is the record detail
	    // result[1] are the inventory detail that the record is included
	    var base        = result.sale;
	    var invs        = result.inv;
	    var sell_detail = result.detail; 

	    // console.log(datetime);
	    $scope.old_select.rsn        = base.rsn;
	    $scope.old_select.rsn_id     = base.id;
	    $scope.old_select.datetime   = diablo_set_datetime(base.entry_date);
	    $scope.old_select.retailer   = $scope.get_object(base.retailer_id, $scope.retailers);

	    console.log($scope.e_pay_types);
	    if (base.e_pay_type === -1){
		$scope.old_select.e_pay_type = $scope.e_pay_types[0];
		$scope.old_select.e_pay      = undefined;
	    } else{
		$scope.old_select.e_pay_type
		    = $scope.get_object(base.e_pay_type, $scope.e_pay_types);
		$scope.old_select.e_pay      = base.e_pay; 
	    }

	    console.log($scope.old_select);
	    // $scope.old_select.surplus    = $scope.old_select.retailer.balance;
	    $scope.old_select.surplus      = base.balance;
	    $scope.old_select.shop         = $scope.get_object(base.shop_id,   $scope.shops);
	    $scope.old_select.employee     = $scope.get_object(base.employ_id, $scope.employees);
	    $scope.old_select.comment      = base.comment;
	    $scope.old_select.total        = Math.abs(base.total);
	    $scope.old_select.should_pay   = Math.abs(base.should_pay);
	    $scope.old_select.left_balance = $scope.f_add(base.balance, base.should_pay);
	    $scope.select = angular.extend($scope.select, $scope.old_select);
	    // console.log($scope.select);
	    // setting
	    $scope.setting.show_discount = $scope.show_discount();
	    $scope.setting.round         = $scope.p_round();
	    $scope.setting.check_sale    = $scope.check_sale($scope.select.shop.id);
	    $scope.setting.trace_price		 = $scope.trace_price($scope.select.shop.id);
	    console.log($scope.setting);

	    var length = invs.length;
	    var sorts  = [];
	    for(var i = 0; i < length; i++){
		var inv  = in_sell(sell_detail, invs[i]);
		if(!in_sort(sorts, inv)) {
		    var add = {$edit:true, $new:false, sizes:[], colors:[], amounts:[]};

		    add.style_number    = inv.style_number;
		    add.brand           = $scope.get_object(inv.brand_id, $scope.brands);
		    add.type            = $scope.get_object(inv.type_id, $scope.types);
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
	    console.log($scope.old_inventories);
	    console.log($scope.inventories);
	}
	
    });

    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    }
    
    $scope.copy_select = function(add, src){
	// console.log(src);
	add.id           = src.id;
	add.style_number = src.style_number;
	add.brand        = $scope.get_object(src.brand_id, $scope.brands);
	add.type         = $scope.get_object(src.type_id, $scope.types); 
	add.firm_id      = src.firm_id;
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;

	// add.org_price    = src.org_price;
	add.tag_price    = src.tag_price;
	add.pkg_price    = src.pkg_price;
	add.price3       = src.price3;
	add.price4       = src.price4;
	add.price5       = src.price5;
	add.discount     = src.discount;
	// add.alarm_day    = src.alarm_day;
	
	add.path         = src.path;
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.sell_style   = $scope.sell_styles[0]; 
	return add; 
    };
    
    $scope.on_select_good = function(item, model, label){
	// console.log(item);

	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		dialog.response_with_callback(
		    false, "退货单编辑", "退货编辑失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}
	
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

	// var e = (angular.isUndefined($scope.select.extra_pay)
	// 	 || isNaN($scope.select.extra_pay)
	// 	 || !$scope.select.extra_pay);

	// if (e && $scope.inventories.length === 1){
	//     return true;
	// };

	return false;
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
			     count:     -update_count})
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
		     count:     -parseInt(newAmounts[i].sell_count)})
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
		     count:     -parseInt(oldAmounts[i].sell_count)})
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
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories); 
	
	var updates = get_update_inventory();
	console.log(updates);
	var added = [];

	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];
	    added.push({
		// id             : add.id,
		style_number   : add.style_number,
		brand          : add.brand.id,
		// brand_name     : add.brand,
		type           : add.type.id,
		// type_name   : add.type,
		firm           : add.firm_id,
		sex            : add.sex,
		season         : add.season,
		year           : add.year,
		s_group        : add.s_group,
		free           : add.free,
		path           : add.path,

		org_price      : add.org_price,
		tag_price      : add.tag_price,
		pkg_price      : add.pkg_price,
		price3         : add.price3,
		price4         : add.price4,
		price5         : add.price5,
		discount       : add.discount,
		alarm_day      : add.alarm_day,
		
		changed_amount : add.changed_amounts,
		operation      : add.operation,
		amount         : function(){
		    if (add.operation === 'd' || add.operation === "a"){
			console.log(add.amounts);
			var filter =  add.amounts.filter(function(m){
			    return angular.isDefined(m.sell_count)
				&& !isNaN(parseInt(m.sell_count))
				&& parseInt(m.sell_count) !== 0;
			});
			return filter.map(function(m){
			    return {cid:m.cid,
				    size:m.size,
				    sell_count: -parseInt(m.sell_count)};
			});
			// return add.amounts.map(function(a){
			//     if (angular.isDefined(a.sell_count)
			// 	&& a.sell_count && parseInt(a.sell_count) !== 0){
			// 	return {cid:a.cid,
			// 		size:a.size,
			// 		sell_count: -parseInt(a.sell_count)};
			//     }
			// })
		    }}(),
		
		sell_total     : -parseInt(add.sell),
		fdiscount      : parseInt(add.fdiscount),
		fprice         : parseFloat(add.fprice), 
		
		sell_style     : angular.isDefined(add.sell_style) ? add.sell_style.id:undefined
	    })
	};
	
	var setv  = diablo_set_float; 
	var seti  = diablo_set_integer;
	var sets  = diablo_set_string; 

	var base = {
	    id:            $scope.select.rsn_id,
	    rsn :          $scope.select.rsn,
	    retailer:      $scope.select.retailer.id,
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id, 
	    balance:       parseFloat($scope.select.surplus),
	    
	    should_pay:     -setv($scope.select.should_pay),
	    
	    e_pay:         function(){
		var e = setv($scope.select.e_pay);
		return angular.isUndefined(e) ? undefined : -e;
	    },
	    comment:        sets($scope.select.comment),

	    old_shop:       $scope.old_select.shop.id,
	    old_retailer:   $scope.old_select.retailer.id, 
	    old_balance:    $scope.old_select.surplus,
	    old_should_pay: -$scope.old_select.should_pay,
	    old_datetime:   dateFilter($scope.old_select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    
	    // left_balance:  parseFloat($scope.select.left_balance),
	    total:         -seti($scope.select.total)
	};
	
	console.log(added);
	console.log(base);

	// console.log($scope.old_select);
	if ($scope.select.shop.id !== $scope.old_select.shop.id){
	    dialog.response_with_callback(
		false, "退货单编辑", "退货单编辑失败：", "暂不支持店铺修改！！",
		undefined, function(){$scope.has_saved = false})
	};
	
	var new_datetime = dateFilter($scope.select.datetime, "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.datetime, "yyyy-MM-dd");
	if (added.length === 0
	    && ($scope.select.employee.id === $scope.old_select.employee.id
		&& $scope.select.shop.id === $scope.old_select.shop.id
		&& $scope.select.retailer.id === $scope.old_select.retailer.id
		&& $scope.select.comment === $scope.old_select.comment
		&&  new_datetime === old_datetime)){
	    diabloUtilsService.response_with_callback(
	    	false, "退货单编辑", "退货单编辑失败：" + wsaleService.error[2699],
		undefined, function() {$scope.has_saved = false});
	    return;
	}

	// $scope.has_saved = false;
	// return;

	wsaleService.update_w_sale_new({
	    inventory:added.length === 0 ? undefined : added, base:base
	}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
		msg = "退货单编辑成功！！单号：" + result.rsn; 
	    	diabloUtilsService.response_with_callback(
	    	    true, "退货单编辑", msg, $scope,
	    	    function(){$scope.go_back()})
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "退货单编辑", "退货单编辑失败：" + wsaleService.error[result.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	}) 
    }; 

    /*
     * add
     */ 
    var get_amount = function(cid, sname, amounts){
	// console.log(amounts);
	// var m = {cid:cid, size:sname};
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    };
    
    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0.00;
	
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total += parseInt(one.sell);
	    if ($scope.setting.round === diablo_round_row){
		$scope.select.should_pay
		    += $scope.round(one.sell * one.fprice * one.fdiscount * 0.01);
	    } else {
		$scope.select.should_pay
		    += one.sell * one.fprice * one.fdiscount * 0.01;
	    } 
	    // $scope.f_add(
	    //     $scope.select.should_pay, 
	    //     (one.sell * one.fdiscount * 0.01) * one.fprice);
	}

	$scope.select.should_pay = $scope.round($scope.select.should_pay);

	var e_pay = 0.00;
	if(angular.isDefined($scope.select.e_pay)
	   && $scope.select.e_pay){
	    e_pay = parseFloat($scope.select.e_pay);
	}

	// console.log($scope.select.should_pay);
	
	$scope.select.left_balance
	    = $scope.round($scope.select.surplus - $scope.select.should_pay - e_pay);

	// console.log($scope.select);
	// $scope.select.left_balance =
	//     $scope.f_sub($scope.select.surplus, $scope.f_add($scope.select.should_pay, e_pay));
    };

    $scope.$watch("select.extra_pay", function(newValue, oldValue){
	// console.log(newValue);
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.extraForm.$invalid) return; 
    	$scope.re_calculate(); 
    });


    var valid_all = function(amounts){
	var total = 0;
	for(var i=0, l=amounts.length; i<l; i++){
	    var sell_count = amounts[i].sell_count; 
	    if (angular.isDefined(sell_count) && sell_count){
		total += parseInt(sell_count);
	    } 
	}

	return total === 0 ? false:true;
    };

    var add_callback = function(params){
	console.log(params.amounts);
	
	var sell = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell += parseInt(a.sell_count);
	    }
	})

	return {amounts:     params.amounts,
		// sell_style:  params.sell_style, 
		sell:        sell,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice,};
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

	if ($scope.setting.check_sale === diablo_no
	    && $scope.setting.trace_price === diablo_no
	    && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount       = inv.discount;
	    inv.fprice          = inv[inv.sell_style.f];
	    inv.amounts         = [{cid:0, size:0}];
	} else {
	    // avoid uncheck sale, but inventory is not free
	    // $scope.setting.check_sale = true;
	    var promise   = diabloPromise.promise;
	    var condition = {style_number: inv.style_number,
			     brand: inv.brand_id,
			     shop:  $scope.select.shop.id};

	    var calls     = [];

	    if ($scope.setting.check_sale === diablo_yes || inv.free !== 0){
		calls.push(promise(purchaserService.list_purchaser_inventory,
				   condition)());
	    } 
	    
	    if ($scope.setting.trace_price === diablo_yes){
		calls.push(promise(
		    wsaleService.get_last_sale,
		    angular.extend(
			{retailer: $scope.select.retailer.id}, condition))());
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
		}
		
		// if (shop_now_inv.length === 0 ){
		//     inv.exist = false;
		//     diabloUtilsService.response(
		// 	false, "销售退货", "退货失败：" + wsaleService.error[2191]);
		//     return;
		// };

		//
		

		if ($scope.select.trace_price === diablo_yes){
		    // last sale info
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
		    
		    inv.fprice    = inv.lprice
			? inv.lprice : inv[inv.sell_style.f];
		    inv.fdiscount = inv.ldiscount
			? inv.ldiscount : inv.discount; 
		} else {
		    inv.fdiscount   = inv.discount;
		    inv.fprice      = inv[inv.sell_style.f];
		} 

		if(inv.free === 0){
		    inv.free_color_size = true;
		    inv.amounts = [{cid:0, size:0}];
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
			// inv.sell_style = result.sell_style;
			inv.sell       = result.sell;
			inv.fdiscount  = result.fdiscount;
			inv.fprice     = result.fprice;
			after_add();
		    };
		    
		    var modal_size = diablo_valid_dialog(inv.sizes);
		    var large_size = modal_size === 'lg' ? true : false;
		    
		    var payload = {
			// sell_styles:  $scope.sell_styles,
			// sell_style:   inv.sell_style,
			fdiscount:    inv.fdiscount,
			fprice:       inv.fprice,
			sizes:        inv.sizes,
			large_size:   large_size,
			colors:       inv.colors,
			amounts:      inv.amounts,
			path:         inv.path,
			get_amount:   get_amount,
			get_price:    function(name){return inv[name]},
			// valid_one:    valid_one,
			valid_all:    valid_all
		    }
		    
		    diabloUtilsService.edit_with_modal(
			"wsale-reject.html", modal_size, callback, $scope, payload);
		}
	    })   
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
	console.log(inv);
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "wsale-reject-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.o_fdiscount = inv.fdiscount;
	    inv.o_fprice    = inv.fprice;
	    inv.free_update = true;
	    return;
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result);
	    inv.amounts    = result.amounts;
	    // inv.sell_style = result.sell_style;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;
	    $scope.re_calculate(); 
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	var payload = {
	    // sell_styles:  $scope.sell_styles,
	    // sell_style:   inv.sell_style,
	    // fprice:       inv[inv.sell_style.f],
	    fdiscount:    inv.fdiscount,
	    fprice:       inv.fprice,
	    sizes:        inv.sizes,
	    large_size:   large_size,
	    colors:       inv.colors, 
	    amounts:      inv.amounts,
	    path:         inv.path,
	    get_amount:   get_amount,
	    get_price:    function(name){return inv[name]},
	    // valid_one:    valid_one,
	    valid_all:    valid_all
	}; 
	diabloUtilsService.edit_with_modal(
	    "wsale-reject.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false;
	// console.log(inv);
	inv.amounts[0].sell_count = inv.sell;
	$scope.re_calculate(); 
    }

    $scope.cancel_free_update = function(inv){
	inv.free_update = false;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	
	inv.sell = inv.amounts[0].sell_count;
	$scope.re_calculate(); 
    }

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true};;
    }
});
