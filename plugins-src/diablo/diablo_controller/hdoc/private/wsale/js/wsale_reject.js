wsaleApp.controller("wsaleRejectCtrl", function(
    $scope, $q, $timeout, dateFilter, diabloUtilsService, diabloPromise,
    diabloPattern, diabloFilter, diabloNormalFilter, wgoodService,
    purchaserService, wsaleService, user, filterRetailer, filterEmployee,
    filterSizeGroup, filterColor, base){
    // console.log(base);
    // console.log(user); 
    $scope.shops   = user.sortBadRepoes.concat(user.sortShops);
    // $scope.repoes  = user.sortRepoes; 
    $scope.sexs    = diablo_sex;
    $scope.seasons = diablo_season;
    $scope.f_add   = diablo_float_add;
    $scope.f_sub   = diablo_float_sub;
    $scope.f_mul   = diablo_float_mul;
    $scope.extra_pay_types   = wsaleService.extra_pay_types;
    $scope.round   = diablo_round;
    $scope.timeout_auto_save = undefined;
    $scope.setting = {q_backend:true,
		      show_discount:true,
		      check_sale:true,
		      trace_price:true,
		      round:diablo_round_record};

    $scope.pattern = {reject:diabloPattern.positive_num,
		      price:diabloPattern.positive_decimal_2};
    
    var dialog     = diabloUtilsService;

    // base setting
    $scope.trace_price = function(shopId){
	return diablo_base_setting(
	    "ptrace_price", shopId, base, parseInt, diablo_no); 
    };
    
    $scope.immediately_print = function(shopId){
	return diablo_base_setting("pim_print", shopId, base, parseInt, diablo_no); 
    };

    $scope.q_typeahead = function(){
	// default prompt comes from backend
	return diablo_base_setting(
	    "qtypeahead", $scope.select.shop.id, base, parseInt, diablo_yes);
    };

    $scope.p_round = function(){
	return diablo_base_setting(
	    "pround", $scope.select.shop.id, base, parseInt, diablo_round_record);
    };
    
    $scope.show_discount = function(){
	return diablo_base_setting(
	    "show_discount", $scope.select.shop.id, base, parseInt, diablo_yes);
    };

    $scope.go_back = function(){
	diablo_goto_page("#/new_wsale_detail");
    };

    var now = $.now();
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, function(v){return v},
	    dateFilter(diabloFilter.default_start_time(now), "yyyy-MM-dd"));
    };
    
    $scope.select  = {
	shop: $scope.shops[0],
	total: 0,
	extra_pay_type: $scope.extra_pay_types[0]
    };

    $scope.setting.trace_price = $scope.trace_price($scope.select.shop.id);

    $scope.retailers = filterRetailer;
    if ($scope.retailers.length !== 0){
	$scope.select.retailer = $scope.retailers[0];
	$scope.select.surplus = $scope.round($scope.select.retailer.balance);
	$scope.select.left_balance = $scope.select.surplus;
    }
    
    // employees
    $scope.employees = filterEmployee;
    if ($scope.employees.length !== 0){
	$scope.select.employee = $scope.employees[0];
    }
    
    $scope.sell_styles = diablo_sell_style;

    // init
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});

    
    $scope.disable_refresh = function(){
	return $scope.has_saved ? false:true;
    };
    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});

	$scope.select.should_pay = 0.00; 
	$scope.select.total   = 0;
	$scope.select.extra_pay = undefined;
	$scope.select.comment = undefined;
	$scope.select.left_balance = $scope.select.retailer.balance;

	$scope.has_saved = false;

	$scope.has_saved = false;

	// $scope.get_retailer(); 
    };

    $scope.change_retailer = function(){
	$scope.select.surplus = $scope.select.retailer.balance;
	$scope.re_calculate();
	// $scope.refresh();
    };
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
    	return now;
    };

    $scope.setting.show_discount = $scope.show_discount();
    $scope.setting.round         = $scope.p_round();
    
    $scope.setting.q_backend     = $scope.q_typeahead();
    if (!$scope.setting.q_backend){
	diabloNormalFilter.match_all_w_inventory(
	    {shop:$scope.select.shop.id,
	     start_time:$scope.qtime_start($scope.select.shop.id)}
	).$promise.then(function(invs){
	    // console.log(invs);
	    $scope.all_w_inventory = 
		invs.map(function(inv){
		    return angular.extend(
			inv, {name:inv.style_number + "，" + inv.brand + "，" + inv.type})
		})
	});
    };

    // $scope.get_repo = function(){
    // 	// console.log($scope.shops);
    // 	if ($scope.select.shop.repo !== -1){
    // 	    return diablo_get_object($scope.select.shop.repo, $scope.repoes);
    // 	} else{
    // 	    return $scope.select.shop; 
    // 	}
    // }
    
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    }
    
    $scope.copy_select = function(add, src){
	// console.log(src);
	add.id           = src.id;
	add.style_number = src.style_number;
	add.brand        = src.brand;
	add.brand_id     = src.brand_id;
	add.type         = src.type;
	add.type_id      = src.type_id;
	add.firm_id      = src.firm_id;
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;

	add.org_price    = src.org_price;
	add.tag_price    = src.tag_price;
	add.pkg_price    = src.pkg_price;
	add.price3       = src.price3;
	add.price4       = src.price4;
	add.price5       = src.price5;
	add.discount     = src.discount;
	add.alarm_day    = src.alarm_day;
	
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
		diabloUtilsService.response_with_callback(
		    false, "销售退货", "退货失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}
	
	// add at first allways 
	var add = $scope.inventories[0];
	add = $scope.copy_select(add, item); 
	
	// if ( (add.all_colors.length === 1 && add.all_colors[0] === "0")
	//      && (add.all_sizes.length === 1 && add.all_sizes[0] === "0") ){
	//     add.free_color_size = true;
	//     // add.sell_style = $scope.sell_styles[0];
	//     add.amounts = [{cid:0, size:0}];
	// } else{
	//     add.free_color_size = false;
	//     add.amounts = [];
	// }

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

	var e = (angular.isUndefined($scope.select.extra_pay)
		 || isNaN($scope.select.extra_pay)
		 || !$scope.select.extra_pay);

	if (e && $scope.inventories.length === 1){
	    return true;
	};

	return false;
    }; 
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories);
	
	var get_sales = function(amounts){
	    var sale_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		if (angular.isDefined(amounts[i].reject_count) && amounts[i].reject_count){
		    sale_amounts.push({
			cid:  amounts[i].cid,
			size: amounts[i].size, 
			reject_count: parseInt(amounts[i].reject_count),
			direct: wsaleService.direct.wreject}); 
		}
	    }

	    return sale_amounts;
	};
	
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    added.push({
		style_number: add.style_number,
		brand       : add.brand_id,
		brand_name  : add.brand,
		s_group     : add.s_group,
		colors      : add.colors,
		free        : add.free,
		type        : add.type_id,
		type_name   : add.type,
		sex         : add.sex,
		season      : add.season,
		firm        : add.firm_id,
		year        : add.year,
		org_price   : add.org_price,
		tag_price   : add.tag_price,
		pkg_price   : add.pkg_price,
		price3      : add.price3,
		price4      : add.price4,
		price5      : add.price5,
		discount    : add.discount,
		alarm_day   : add.alarm_day,
		
		amounts     : get_sales(add.amounts),
		sell_total  : parseInt(add.reject),
		fdiscount   : parseInt(add.fdiscount),
		fprice      : parseFloat(add.fprice),
		path        : add.path
	    })
	};

	var setv = diablo_set_float; 
	var seti = diablo_set_integer; 
	var e_pay = setv($scope.select.extra_pay);
	var im_print = $scope.immediately_print($scope.select.shop.id);
	
	var base = {
	    retailer_id:   $scope.select.retailer.id,
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       $scope.select.comment,
	    balance:       setv($scope.select.surplus),
	    should_pay:    setv($scope.select.should_pay),
	    left_balance:  setv($scope.select.left_balance),
	    direct:        wsaleService.direct.wreject,
	    total:         seti($scope.select.total),
	    
	    e_pay_type:    angular.isUndefined(e_pay) ? undefined : $scope.select.extra_pay_type.id,
	    e_pay:         e_pay
	};

	

	var print = {
	    im_print:    im_print,
	    retailer_id: $scope.select.retailer.id,
	    shop:        $scope.select.shop.name,
	    employ:      $scope.select.employee.name,
	    // retailer:    $scope.select.retailer.name
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true;
	var show_dialog = function(title, message){
	    dialog.response_with_callback(
		true, title, message, undefined,
		function(){
		    $scope.select.retailer.balance = $scope.select.left_balance;
		    $scope.select.surplus = $scope.select.retailer.balance;
		})
	};
	
	wsaleService.reject_w_sale({
	    inventory:added, base:base, print:print
	}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
		var msg = "";
		var rsn = result.rsn;
		if (im_print === diablo_yes){
		    if (result.pcode == 0){
			msg = "退货成功！！退货单号：" + rsn + "，请等待服务器打印";
		    } else {
			if (result.pinfo.length === 0){
			    msg += wsaleService.error[result.pcode]
			} else {
			    angular.forEach(result.pinfo, function(p){
				msg += "[" + p.device + "] " + wsaleService.error[p.ecode]
			    })
			};
			msg = "退货成功！！退货单号：" + rsn + "，打印失败：" + msg;
		    };
		    
		    show_dialog("销售退货", msg);
		} else{
		    var yes_callback = function(){
			wsaleService.print_w_sale(rsn).then(function(result){
			    var show_message = "";
			    if (result.pcode == 0){
				show_message = "打印消息发送成功，请等待服务器打印！！";
			    } else {
				if (result.pinfo.length === 0){
				    show_message += wsaleService.error[result.pcode]
				} else {
				    angular.forEach(result.pinfo, function(p){
					show_message += "[" + p.device + "] "
					    + wsaleService.error[p.ecode]
				    })
				};
				show_message = "打印失败：" + show_message;
			    };
			    show_dialog("退货单打印", show_message); 
			})
		    };
		    
		    dialog.request(
			"退货单打印", "退货成功，是否打印退货单？",
			yes_callback, undefined, $scope)
		} 
	    } else{
	    	dialog.response_with_callback(
	    	    false, "销售退货", "退货失败：" + wsaleService.error[result.ecode],
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
	    $scope.select.total += parseInt(one.reject);

	    if ($scope.setting.round === diablo_round_row){
		$scope.select.should_pay
		    += $scope.round(
			one.reject * one.fdiscount * 0.01 * one.fprice);
	    } else {
		$scope.select.should_pay
		    += one.reject * one.fdiscount * 0.01 * one.fprice;
	    }
	    
	}

	$scope.select.should_pay = $scope.round($scope.select.should_pay);

	var e_pay = 0.00;
	if(angular.isDefined($scope.select.extra_pay)
	   && $scope.select.extra_pay){
	    e_pay = $scope.select.extra_pay;
	}
	

	$scope.select.left_balance =
	    $scope.round($scope.select.surplus - $scope.select.should_pay - e_pay);
	    // $scope.f_sub($scope.select.surplus, $scope.f_add($scope.select.should_pay, e_pay));
    };

    $scope.$watch("select.extra_pay", function(newValue, oldValue){
	// console.log(newValue);
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.extraForm.$invalid) return; 
    	$scope.re_calculate(); 
    });
    
    var valid_reject = function(amounts){
	var changed = 0;
	for(var i=0, l=amounts.length; i<l; i++){
	    var reject_count = amounts[i].reject_count; 
	    if (angular.isDefined(reject_count) && reject_count){
		changed++;
		continue;
	    } 
	};

	// console.log(changed);
	return changed === 0 ? false : true;

    };
    
    var add_callback = function(params){
	console.log(params.amounts);
	
	var reject_total = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.reject_count) && a.reject_count){
		reject_total += parseInt(a.reject_count);
	    }
	})

	return {amounts:     params.amounts,
		// sell_style:  params.sell_style, 
		reject:      reject_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice,};
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].reject_count = inv.reject;
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true});
	
	$scope.re_calculate(); 
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv); 
	console.log($scope.setting);
	if ($scope.setting.check_sale === diablo_no
	    && $scope.setting.trace_price === diablo_no
	    && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount       = inv.discount;
	    inv.fprice          = inv[inv.sell_style.f];
	    inv.amounts         = [{cid:0, size:0}];
	} else {
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
	    }
	    
	    $q.all(calls).then(function(data){
		console.log(data);
		// data[0] is the inventory belong to the shop
		// data[1] is the last sale of the shop

		if ($scope.setting.check_sale === diablo_yes
		    || inv.free !== 0){
		    var shop_now_inv = data[0];

		    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
		    var sort = purchaserService.sort_inventory(shop_now_inv, order_sizes, filterColor);

		    inv.total   = sort.total;
		    inv.sizes   = sort.size;
		    inv.colors  = sort.color;
		    inv.amounts = sort.sort; 
		    
		    console.log(inv.sizes);
		    console.log(inv.colors);
		    console.log(inv.amounts); 
		}

		if ($scope.setting.trace_price === diablo_yes){
		    var shop_last_inv = function(){
			if ($scope.setting.check_sale === diablo_yes
			    || inv.free !== 0){
			    return data[1];
			} else {
			    return data[0];
			}
		    }();

		    // last sale info
		    inv.lprice    = shop_last_inv.length === 0
			? undefined:shop_last_inv[0].fprice;
		    inv.ldiscount = shop_last_inv.length === 0
			? undefined:shop_last_inv[0].fdiscount;
		    
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
			inv.reject     = result.reject;
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
			valid:        valid_reject}
		    
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
	// console.log(inv);
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    inv.o_fdiscount = inv.fdiscount;
	    inv.o_fprice    = inv.fprice;
	    return;
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result);
	    inv.amounts    = result.amounts;
	    // inv.sell_style = result.sell_style;
	    inv.reject     = result.reject;
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
	    // valid_sell:   valid_sell,
	    valid:        valid_reject}; 
	diabloUtilsService.edit_with_modal(
	    "wsale-reject.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.amounts[0].reject_count = inv.reject;
	$scope.re_calculate(); 
    };

    $scope.cancel_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.reject = inv.amounts[0].reject_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	$scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    };

    $scope.auto_save_free = function(inv){
	if (angular.isUndefined(inv.reject)
	    || !inv.reject
	    || parseInt(inv.reject) === 0){
	    return;
	} 
	
	$timeout.cancel($scope.timeout_auto_save);
	$scope.timeout_auto_save = $timeout(function(){
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    }
		
	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv); 
	    }
	}, 1000); 
    };
}); 


wsaleApp.controller("wsaleRejectDetailCtrl", function(
    $scope, diabloUtilsService, diabloFilter,
    wretailerService, wsaleService,
    user, filterRetailer, filterEmployee){

    $scope.goto_page = diablo_goto_page; 
    $scope.float_add = diablo_float_add;

    
    // console.log(user.sortShops);
    // console.log(filterRetailer);
    // console.log(filterEmployee);

    /* 
     * filter operation
     */ 
    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     user.sortShops);
    diabloFilter.add_field("retailer", filterRetailer);
    diabloFilter.add_field("employee", filterEmployee);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    $scope.time   = diabloFilter.default_time(); 


    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = 10;
    $scope.default_page = 1;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = user.shopIds.length === 0 ? undefined : user.shopIds; 
	    }

	    console.log(search);

	    wsaleService.filter_w_sale_reject(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.t_amount;
		    $scope.total_balance = result.t_spay;
		}
		$scope.records = result.data;
		diablo_order_page(page, $scope.items_perpage, $scope.records);
	    })
	})
    }

    $scope.page_changed = function(){
	// console.log($scope.current_page);
	$scope.do_search($scope.current_page);
    }
    
    // default the first page
    $scope.do_search($scope.default_page);


    // details
    $scope.rsn_detail = function(r){
	console.log(r);
	// $location.url("#/wsale_detail/" + r.rsn);
	diablo_goto_page("#/wsale_rsn_detail/1/" + r.rsn);
    }
    
});
