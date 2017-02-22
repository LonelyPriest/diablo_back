var wsaleUtils = function(){
    return {
	typeahead: function(shop, base){
            return diablo_base_setting(
		"qtypeahead", shop, base, parseInt, diablo_yes);
	},

	im_print: function(shop, base){
	    return diablo_base_setting(
		"pim_print", shop, base, parseInt, diablo_no);
	},

	trace_price: function(shop, base){
	    return diablo_base_setting(
		"ptrace_price", shop, base, parseInt, diablo_no);
	},

	show_discount: function(shop, base)
	{
	    return diablo_base_setting(
		"show_discount", shop, base, parseInt, diablo_yes);
	},

	hide_sell_style: function(shop, base){
	    return diablo_base_setting(
		"h_sell_style", shop, base, parseInt, diablo_no);
	},

	hide_tagprice: function(shop, base){
	    return diablo_base_setting(
		"h_tagprice", shop, base, parseInt, diablo_no);
	},

	head_amount: function(shop, base){
	    return diablo_base_setting(
		"head_amount", shop, base, parseInt, diablo_no);
	},

	modify_comment: function(shop, base){
	    return diablo_base_setting(
		"m_comment", shop, base, parseInt, diablo_no);
	},

	get_round: function(shop, base){
	    return diablo_base_setting(
		"pround", shop, base, parseInt, diablo_round_record);
	},

	check_sale: function(shop, base){
	    return diablo_base_setting(
		"check_sale", shop, base, parseInt, diablo_yes);
	},

	price_type: function(shop, base, defaultPrice){
	    return diablo_base_setting(
		"price_type", shop, base, parseInt, defaultPrice);
	},

	auto_cash: function(shop, base){
	    return diablo_base_setting(
		"auto_cash", shop, base, parseInt, diablo_no);
	},

	sys_customer: function(base){
	    return diablo_base_setting(
		"s_customer", -1, base, parseInt, 0); 
	} 
    }

}();
