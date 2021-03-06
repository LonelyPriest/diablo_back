
var rightAuthen = {

    account: {
	_master: 1,
	_user: 2
    },

    root_right : {
    	_shop: 40000
    },

    actions: function(){
	return {
    	    new_repo     : rightAuthen.root_right._shop + 5,
    	    del_repo     : rightAuthen.root_right._shop + 6,
    	    update_repo  : rightAuthen.root_right._shop + 7,
    	    list_repo    : rightAuthen.root_right._shop + 8
	}
    },
    
    authen: function(authenAction, rights){
	// console.log(rightAuthen.actions()[authenAction]);
    	for (var i = 0, l = rights.length; i < l; i++){
    	    if (rights[i].id === rightAuthen.actions()[authenAction]){
    		// console.log(rights[i].id, actions[Authenaction]);
    		return true;
    	    };
    	};

    	return false;
    },

    show_orgprice: function(userType) {
	return userType === rightAuthen.account._master ? true:false;
    },

    export_stock: function(userType) {
	return userType === rightAuthen.account._master ? true:false;
    },

    master: function(userType) {
	return userType === rightAuthen.account._master ? true:false;
    }
};
