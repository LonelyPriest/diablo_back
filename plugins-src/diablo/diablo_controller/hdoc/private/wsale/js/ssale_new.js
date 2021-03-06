wsaleApp.controller("ssaleNewCtrl", function(
    $scope, $q, $timeout, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, wgoodService, purchaserService, 
    wretailerService, wsaleService,
    user, filterFirm, filterRetailer, filterEmployee,
    filterSizeGroup, filterBrand, filterType, filterColor, base){

    // console.log(filterEmployee);
    $scope.pattern  = {money: diabloPattern.decimal_2,
		       sell:  diabloPattern.integer_except_zero};
    
    $scope.timeout_auto_save = undefined;
    $scope.round             = diablo_round;
    
    $scope.back  = function(){
	diablo_goto_page("#/new_wsale_detail");
    };

    $scope.setting = {q_backend     :true,
		      show_discount :true,
		      check_sale    :true,
		      round         :diablo_round_record,
		      auto_cash     :diablo_no};

    $scope.sell_styles = diablo_sell_style; 

    // base setting 
    $scope.immediately_print = function(shopId){
	return diablo_base_setting(
	    "pim_print", shopId, base, parseInt, diablo_no); 
    };

    $scope.q_typeahead = function(){
	// default prompt comes from backend
	return diablo_base_setting(
	    "qtypeahead", $scope.select.shop.id, base, parseInt, diablo_yes);
    };
    // console.log($scope.q_typeahead); 

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

    $scope.price_type = function(shopId){
	return diablo_base_setting(
	    "price_type",
		-1,
	    base,
	    parseInt,
	    $scope.sell_styles[0].id);
    }(); 
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.wsale_mode      = wsaleService.wsale_mode;
    $scope.disable_refresh = true;
    
    $scope.select = {
	cash: undefined,
	card: undefined,
	wire: undefined,
	verificate: undefined,
	
	total:          0,
	abs_total:      0,
	has_pay:        0.00,
	should_pay:     0.00,
	sell_total:     0,
	reject_total:   0
	// extra_pay: 0.00
    }; 

    // console.log($scope.select); 
    
    // shops
    $scope.shops = user.sortShops;
    if ($scope.shops.length !== 0){
	$scope.select.shop = $scope.shops[0]; 
	$scope.setting.check_sale = $scope.check_sale($scope.select.shop.id); 
    }
    
    $scope.find_shop = function(shopId){
	for(var i=0, l=$scope.shops.length; i<l; i++)
	    if(shopId === $scope.shops[i].id){
		return $scope.shops[i];
	    }
    }

    $scope.change_shop = function(){
	$scope.local_save(); 
	$scope.setting.check_sale = $scope.check_sale($scope.select.shop.id);
	$scope.setting.show_discount = $scope.show_discount();
	$scope.setting.round         = $scope.p_round();
	
	if (!$scope.setting.q_backend){
	    $scope.match_all_w_inventory();
	}
    } 

    // employees
    $scope.employees = filterEmployee;
    // console.log($scope.employees);
    if ($scope.employees.length !== 0){
	$scope.select.employee = $scope.employees[0];
	if (user.loginEmployee !== -1){
	    for (var i=0, l=$scope.employees.length; i<l; i++){
		if (user.loginEmployee === $scope.employees[i].eid){
		    $scope.select.employee = $scope.employees[i]
		    break;
		} 
	    }
	} 

	// console.log($scope.select.employee); 
    }; 
    
    // retailer;
    $scope.retailers = filterRetailer;
    if ($scope.retailers.length !== 0){
	$scope.select.retailer = $scope.retailers[0];
	if (user.loginRetailer !== -1){
	    for (var i=0, l=$scope.retailers.length; i<l; i++){
		if (user.loginRetailer === $scope.retailers[i].id){
		    $scope.select.retailer = $scope.retailers[i]
		    break;
		} 
	    }
	}
	
	var balance = $scope.select.retailer.balance;
	$scope.select.surplus = angular.isDefined(balance)
	    && !isNaN(balance) && balance ? parseFloat($scope.select.retailer.balance) : 0;
	$scope.select.left_balance = $scope.select.surplus;
    }; 

    $scope.change_retailer = function(){
	var balance = $scope.select.retailer.balance;
	$scope.select.surplus = angular.isDefined(balance)
	    && !isNaN(balance) && balance ? parseFloat($scope.select.retailer.balance) : 0;
	$scope.local_save();
	$scope.re_calculate();
	if ($scope.wsale_mode[1].active){
	    $scope.page_changed($scope.current_page); 
	}
    }

    $scope.add_retailer = function(){
	var callback = function(params){
	    console.log(params); 
	    var retailer = {
		name:    params.retailer.name,
		mobile:  params.retailer.mobile,
		address: params.retailer.address};
	    wretailerService.new_wretailer(retailer).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    var append_retailer = function(RetailerId){
			var newRetailer = {
			    name    :retailer.name,
			    id      :RetailerId,
			    py      :diablo_pinyin(retailer.name),
			    balance :0};
			
			$scope.retailers.push(newRetailer);
			$scope.select.retailer = newRetailer;
			$scope.change_retailer();
		    }
		    diabloUtilsService.response_with_callback(
	    		true, "新增零售商",
			"零售商 " + retailer.name + " 成功创建！！",
	    		$scope,
			function(){append_retailer(state.id)});
		} else{
		    diabloUtilsService.response(
	    		false, "新增零售商",
	    		"新增零售商失败：" + wretailerService.error[state.ecode]);
		};
	    })
	}
	diabloUtilsService.edit_with_modal(
	    "new-retailer.html", undefined, callback, $scope, {retailer: {}});
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
	
	$scope.select.cash       = undefined;
	$scope.select.card       = undefined;
	$scope.select.verificate = undefined;
	$scope.select.wire       = undefined;
	// $scope.select.extra_pay  = undefined;
	
	$scope.select.has_pay    = 0.00;
	$scope.select.should_pay = 0.00;

	$scope.select.total     = 0;
	$scope.select.abs_total = 0;
	$scope.select.comment = undefined;
	$scope.select.left_balance = $scope.select.surplus;

	$scope.disable_refresh = true;
	$scope.has_saved = false;

	// $scope.get_retailer(); 
    }; 

    var now = $.now();
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, function(v){return v},
	    dateFilter(diabloFilter.default_start_time(now), "yyyy-MM-dd"));
    };

    // console.log($scope.qtime_start);

    $scope.setting.show_discount = $scope.show_discount();
    $scope.setting.round         = $scope.p_round();

    $scope.setting.q_backend = $scope.q_typeahead($scope.select.shop.id);
    // wsaleGoodService.set_prompt_mode($scope.setting.q_backend);

    $scope.match_all_w_inventory = function(){
	diabloNormalFilter.match_all_w_inventory(
	    {shop:$scope.select.shop.id,
	     start_time:$scope.qtime_start($scope.select.shop.id)}
	).$promise.then(function(invs){
	    // console.log(invs);
	    $scope.all_w_inventory = 
		invs.map(function(inv){
		    var name = inv.style_number
			+ "，" + inv.brand + "，" + inv.type;
		    return angular.extend(
			inv, {name:name, py: diablo_pinyin(name)});
		});
	}); 
    };

    if (!$scope.setting.q_backend){
	$scope.match_all_w_inventory();
    }
    
    $scope.stastic_colspan = function(){
	var all_colspan = 8;
	if (!$scope.setting.show_discount){
	    all_colspan -= 1;
	}
	if (!$scope.setting.check_sale){
	    all_colspan -= 1;
	}

	return all_colspan;
    }();
    // console.log($scope.stastic_colspan);
    // console.log($scope.setting);
    
    // init
    // $scope.refresh();
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});

    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
	return $.now();
    }

    // local save
    /*
     * draft
     */
    var key_re = /^ss-[0-9-]+$/; 
    var current_key = function(){
	return "ss-" + $scope.select.retailer.id.toString()
	    + "-" + $scope.select.shop.id.toString()
	    + "-" + $scope.select.employee.id.toString();
    };

    var draft_keys = function(){
	// return [];
	var keys = localStorageService.keys();
	return keys.filter(function(k){
	    return key_re.test(k); 
	});
    };

    $scope.local_save = function(){
	var key = current_key();
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
	
	// console.log(key_fix);
	
	var drafts = key_fix.map(function(k){
	    var p = k.split("-");
	    return {sn:k,
		    retailer:diablo_get_object(parseInt(p[1]), $scope.retailers),
		    shop:diablo_get_object(parseInt(p[2]), $scope.shops),
		    employee:diablo_get_object(p[3], $scope.employees)
		   }
	});

	console.log(drafts) 
	var callback = function(params){
	    
	    var select_draft = params.drafts.filter(function(d){
	    	return angular.isDefined(d.select) && d.select
	    })[0];

	    console.log($scope.select);
	    $scope.select.retailer =
	    	diablo_get_object(select_draft.retailer.id, $scope.retailers);
	    $scope.select.shop =
	    	diablo_get_object(select_draft.shop.id, $scope.shops);
	    $scope.select.employee =
	    	diablo_get_object(select_draft.employee.id, $scope.employees);
	    
	    var one = localStorageService.get(select_draft.sn);
	    
	    if (angular.isDefined(one) && null !== one){
	        $scope.inventories = angular.copy(one.v);
	        console.log($scope.inventories); 
	        $scope.inventories.unshift({$edit:false, $new:true});

	    	$scope.disable_refresh = false;
	        $scope.re_calculate();
		
	        // $scope.draft = true;
	    } 
	}

	// console.log(drafts);
	diabloUtilsService.edit_with_modal(
	    "ssale-draft.html", undefined, callback, undefined,
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
	    }
	); 
    }; 
    
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    } 

    // $scope.sell_styles = diablo_sell_style;

    // console.log($scope.sell_styles);

    $scope.get_sell_style = function(id){
	for (var i=0, l=$scope.sell_styles.length; i<l; i++){
	    if ($scope.sell_styles[i].id === id){
		return $scope.sell_styles[i];
	    }
	}
    }; 

    $scope.copy_select = function(add, src){
	add.id           = src.id;
	add.style_number = src.style_number;
	add.brand        = src.brand;
	add.brand_id     = src.brand_id;
	add.type_id      = src.type_id;
	add.type         = src.type;
	add.type_id      = src.type_id;
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
	add.sell_style   = $scope.sell_styles[$scope.price_type - 1];
	
	return add;
	
    };
    
    $scope.on_select_good = function(item, model, label){
	// console.log(item); 
	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "销售开单", "开单失败：" + wsaleService.error[2191],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}; 
	
	// add at first allways 
	var add = $scope.inventories[0];
	add = $scope.copy_select(add, item); 

	// console.log(add); 
	$scope.add_inventory(add);
	
	return;
    };

    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved || $scope.draft){
	    return true;
	};

	// console.log($scope.select);
	// any payment of cash, card or wire or any inventory
	if (angular.isDefined($scope.select.cash) && $scope.select.cash
	    || angular.isDefined($scope.select.card) && $scope.select.card
	    || angular.isDefined($scope.select.wire) && $scope.select.wire
	    || angular.isDefined($scope.select.verificate) && $scope.select.verificate
	    || $scope.inventories.length !== 1){
	    return false;
	} 

	return true;
    }; 

    $scope.recover_sell_style = function(inv){
	
	if (inv.recover){
	    return $scope.get_sell_style(inv.sell_style_id);
	}

	return inv.sell_style;
    } 
    
    $scope.save_ssale = function(){
	$scope.has_saved = true; 
	// console.log($scope.inventories); 
	// console.log($scope.select);
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};
	
	var get_sales = function(amounts){
	    var sale_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		var a = amounts[i];
		if (angular.isDefined(a.sell_count) && a.sell_count){
		    var new_a = {
			cid:        a.cid,
			size:       a.size, 
			sell_count: parseInt(amounts[i].sell_count)}; 
		    
		    sale_amounts.push(new_a); 
		}
	    }; 

	    return {amounts:sale_amounts};
	};

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;
	
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    // var batch = add.batch;
	    // console.log(batch);
	    var amount_info = get_sales(add.amounts);
	    if (angular.isUndefined(add.style_number)){
		diabloUtilsService.response(
		    false, "销售开单", "开单失败：序号["
			+ add.order_id.toString() + "]"
			+ wsaleService.error[2192]);
		return;
	    };
	    
	    added.push({
		id          : add.id,
		style_number: add.style_number,
		brand       : add.brand_id,
		brand_name  : add.brand,
		type        : add.type_id,
		type_name   : add.type,
		firm        : add.firm_id,
		sex         : add.sex,
		season      : add.season,
		year        : add.year,
		sell_total  : parseInt(add.sell),
		fdiscount   : seti(add.fdiscount),
		fprice      : setv(add.fprice),
		path        : sets(add.path),

		sizes       : add.sizes,
		s_group     : add.s_group,
		colors      : add.colors,
		free        : add.free,
		comment     : sets(add.comment),
		
		sell_style  : add.sell_style.id,
		amounts     : amount_info.amounts 
	    })
	}; 

	// console.log($scope.select);
	var im_print = $scope.immediately_print($scope.select.shop.id);

	// console.log(im_print);
	var base = {
	    sort:           $scope.setting.r_snumber,
	    retailer:       $scope.select.retailer.id,
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        sets($scope.select.comment),
	    balance:        setv($scope.select.surplus),
	    
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wire:           setv($scope.select.wire),
	    verificate:     setv($scope.select.verificate),
	    should_pay:     setv($scope.select.should_pay),
	    has_pay:        setv($scope.select.has_pay), 
	    
	    total:         seti($scope.select.total),
	    sell_total:    seti($scope.select.sell_total),
	    reject_total:  seti($scope.select.reject_total),

	    mode:          diablo_ssale
	};

	var print = {
	    im_print:    im_print,
	    shop:        $scope.select.shop.name,
	    employ:      $scope.select.employee.name,
	    retailer_id: $scope.select.retailer.id,
	    retailer:    $scope.select.retailer.name
	};

	// console.log(added);
	// console.log(base);

	var dialog = diabloUtilsService; 
	wsaleService.new_w_sale({
	    inventory:added.length === 0 ? undefined : added,
	    base:base, print:print
	}).then(function(result){
	    // console.log(result);
	    var rsn = result.rsn;

	    var print = function(result){
		var messsage = "";
		if (result.pcode == 0){
		    messsage = "成功！！单号：" + rsn + "，请等待服务器打印";
		} else {
		    if (result.pinfo.length === 0){
			messsage += wsaleService.error[result.pcode]
		    } else {
			angular.forEach(result.pinfo, function(p){
			    messsage += "[" + p.device + "] " + wsaleService.error[p.ecode]
			})
		    };
		    messsage = "成功！！单号：" + rsn + "，打印失败：" + messsage;
		}

		return messsage;
	    };

	    var show_dialog = function(title, message){
		dialog.response(true, title, message, undefined)
	    };
	    
	    if (result.ecode == 0){
		// clear local storage
		$scope.local_remove();
		$scope.disable_refresh = false;
		// modify current balance of retailer
		$scope.select.retailer.balance = $scope.select.left_balance;
		$scope.select.surplus = $scope.select.retailer.balance;
		
		if (im_print === diablo_yes){
		    var show_message = "开单" + print(result);
		    show_dialog("销售开单", show_message); 
		} else{
		    var yes_callback = function(){
			wsaleService.print_w_sale(rsn).then(function(result){
			    var show_message = "销售单打印" + print(result);
			    show_dialog("销售单打印", show_message); 
			})
		    };
		    
		    dialog.request(
			"销售单打印", "开单成功，是否打印销售单？",
			yes_callback, undefined, $scope)
		}
		
	    } else{
	    	dialog.response_with_callback(
	    	    false, "销售开单", "开单失败：" + wsaleService.error[result.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };
    
    // watch balance
    var reset_payment = function(newValue){
	$scope.select.has_pay = 0.00;
	var verificate = 0.00;
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

	

	// console.log($scope.float_add);
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay
	    - verificate - $scope.select.has_pay;
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
    	if ($scope.select.form.vForm.$invalid) return; 
    	reset_payment(newValue); 
    }); 
    
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
    
    $scope.re_calculate = function(){
	// console.log("re_calculate");
	$scope.select.total = 0;
	$scope.select.abs_total = 0;
	$scope.select.should_pay = 0.00;
	$scope.select.sell_total = 0;
	$scope.select.reject_total = 0; 

	// console.log($scope.inventories);
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    var sell = parseInt(one.sell);
	    $scope.select.total      += sell;
	    $scope.select.abs_total  += Math.abs(sell);
	    
	    if (sell > 0 ){
		$scope.sell_total += sell;
	    } else {
		$scope.reject_total += sell;
	    }

	    // var f1 = $scope.round(one.fprice * one.fdiscount * 0.01);
	    if ($scope.setting.round === diablo_round_row){
		$scope.select.should_pay
		    += $scope.round(
			one.fprice * one.fdiscount * 0.01 * one.sell);
	    } else {
		$scope.select.should_pay
		    += one.fprice * one.fdiscount * 0.01 * one.sell; 
	    }
	    
	    // console.log($scope.select.should_pay);
	    // $scope.select.should_pay
	    // 	= $scope.select.should_pay + one.fprice * one.sell * one.fdiscount * 0.01;
	}

	$scope.select.should_pay = $scope.round($scope.select.should_pay); 

	// console.log($scope.select.extra_pay);
	var verificate = diablo_set_float($scope.select.verificate);
	verificate = angular.isDefined(verificate) ? verificate : 0;
	
	$scope.select.left_balance
	    = $scope.select.surplus + $scope.select.should_pay
	    - $scope.select.has_pay - verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance); 
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
	// console.log(params.amounts);
	
	var sell_total = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += parseInt(a.sell_count);
	    }
	}); 

	return {amounts:     params.amounts,
		sell_style:  params.sell_style,
		sell:        sell_total,
		// batch:       batch,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice};
    };

    $scope.add_free_inventory = function(inv){
	// console.log(inv);

	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};
	
	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].sell_count = inv.sell;
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true});

	// save
	$scope.disable_refresh = false;
	$scope.local_save();
	$scope.re_calculate();
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv);
	// console.log($scope.select);
	// console.log($scope.setting);
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};

	if ($scope.setting.check_sale === diablo_no && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount       = inv.discount;
	    inv.fprice          = inv[inv.sell_style.f];
	    inv.amounts         = [{cid:0, size:0}];
	} else {
	    // avoid uncheck sale, but inventory is not free
	    // $scope.setting.check_sale = true;
	    var promise = diabloPromise.promise; 
	    var calls   = [];

	    if ($scope.setting.check_sale === diablo_yes || inv.free !== 0){
		calls.push(promise(purchaserService.list_purchaser_inventory,
				   {style_number: inv.style_number,
				    brand:        inv.brand_id,
				    shop:         $scope.select.shop.id
				   })());
	    } 
	    
	    $q.all(calls).then(function(data){
		// console.log(data);
		// data[0] is the inventory belong to the shop
		// data[1] is the last sale of the shop

		if ($scope.setting.check_sale === diablo_yes
		    || inv.free !== 0){
		    var shop_now_inv = data[0];
		    
		    var order_sizes =
			wgoodService.format_size_group(
			    inv.s_group, filterSizeGroup);
		    var sort =
			purchaserService.sort_inventory(
			    shop_now_inv, order_sizes, filterColor);
		    
		    inv.total   = sort.total;
		    inv.sizes   = sort.size;
		    inv.colors  = sort.color;
		    inv.amounts = sort.sort; 
		} 
		
		inv.fdiscount   = inv.discount;
		inv.fprice      = inv[inv.sell_style.f];

		if(inv.free === 0){
		    inv.free_color_size = true;
		    inv.amounts         = [{cid:0, size:0}];
		} else{
		    inv.free_color_size = false;

		    var after_add = function(){
			inv.$edit = true;
			inv.$new = false;
			// oreder
			inv.order_id = $scope.inventories.length; 
			// add new line 
			$scope.inventories.unshift({$edit:false, $new:true});

			$scope.disable_refresh = false;
			$scope.local_save();
			$scope.re_calculate(); 
		    };
		    
		    var callback = function(params){
			// console.log(params);
			var result  = add_callback(params);
			// console.log(result);
			inv.amounts    = result.amounts;
			inv.sell_style = result.sell_style;
			inv.sell       = result.sell;
			// inv.batch      = result.batch;
			inv.fdiscount  = result.fdiscount;
			inv.fprice     = result.fprice;
			after_add();
		    };
		    
		    var modal_size = diablo_valid_dialog(inv.sizes);
		    var large_size = modal_size === 'lg' ? true : false;
		    var payload = {
			// last_discount:  inv.last_discount,
			// last_fprice:    inv.last_fprice,
			sell_styles:    $scope.sell_styles,
			sell_style:     inv.sell_style,
			fdiscount:      inv.fdiscount,
			fprice:         inv.fprice,
			sizes:          inv.sizes,
			large_size:     large_size,
			colors:         inv.colors,
			amounts:        inv.amounts,
			path:           inv.path,
			get_amount:     get_amount,
			get_price:      function(name){return inv[name]},
			valid_sell:     valid_sell,
			valid:          valid_all_sell};

		    $scope.params = angular.copy(payload);
		    diabloUtilsService.edit_with_modal(
			"ssale-new.html", modal_size, callback, $scope, payload); 
		}; 
	    });
	} 
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	// console.log(inv);
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

	$scope.local_save();
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
	    "ssale-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	// console.log(inv);
	inv.$update = true;
	// inv.$a_change = false;
	if (inv.free_color_size){
	    inv.free_update = true;
	    inv.o_fdiscount = inv.fdiscount;
	    inv.o_fprice    = inv.fprice;
	    return;
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    // console.log(result);
	    inv.amounts    = result.amounts;
	    inv.sell_style = result.sell_style;
	    // inv.batch      = result.batch;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;

	    // save
	    $scope.local_save();
	    $scope.re_calculate(); 
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	
	var payload = {sell_styles:  $scope.sell_styles,
		       sell_style:   $scope.get_sell_style(inv.sell_style.id),
		       fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount, 
		       get_price:    function(name){return inv[name]},
		       valid_sell:   valid_sell,
		       valid:        valid_all_sell}; 
	diabloUtilsService.edit_with_modal(
	    "ssale-new.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	// console.log("save_free_update", inv);
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false; 
	inv.amounts[0].sell_count = inv.sell;
	
	// save
	$scope.local_save();
	$scope.re_calculate();
    };

    $scope.cancel_free_update = function(inv){
	// console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.sell        = inv.amounts[0].sell_count;
	inv.fdiscount   = inv.o_fdiscount;
	inv.fprice      = inv.o_fprice;
	$scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    };

    $scope.auto_save_free = function(inv){
	if (angular.isUndefined(inv.sell)
	    || !inv.sell
	    || parseInt(inv.sell) === 0){
	    return;
	} 

	$timeout.cancel($scope.timeout_auto_save);
	$scope.timeout_auto_save = $timeout(function(){
	    // console.log(inv); 
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    }; 

	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv); 
	    }
	}, 1000); 
    };
});
