require.config({
    baseUrl: '/private/purchaser/js',
    paths: {
        "angular": "/public/assets/angular-1.3.9/angular.min",
        "angular-router": "/public/assets/angular-1.3.9/angular-route.min",
	"angular-resource": "/public/assets/angular-1.3.9/angular-resource.min",
	"angular-zh": "/public/assets/angular-1.3.9/i18n/angular-locale_zh",
	"angular-local-storage": "/public/assets/angular-local-storage/angular-local-storage",
	"angular-ui-bootstrap": "/public/assets/bootstrap/ui-bootstrap-tpls-0.13.1",
	
        "jquery": "/public/assets/metronic/plugins/jquery-1.11.3.min",
	"jquery-migrate": "/public/assets/metronic/plugins/jquery-migrate-1.2.1.min",
	"jquery-custom": "/public/assets/metronic/plugins/jquery-ui/jquery-ui-1.10.3.custom.min", 
	"jquery-cookie": "/public/assets/metronic/plugins/jquery.cokie.min",
	"jquery-block": "/public/assets/metronic/plugins/jquery.blockui.min",
	"bootstrap": "/public/assets/bootstrap/js/bootstrap.min",

	"fastclick": "/public/assets/fastclick/fastclick.min",


	"diablo-function": "/private/utils/javascript/diablo_function",
	
	"diablo-authen": "/private/utils/javascript/diablo_authen_app",
	"diablo-pattern": "/private/utils/javascript/diablo_pattern",
	"diablo-utils": "/private/utils/javascript/diablo_utils",
	"diablo-user-right": "/private/right/javascript/user_right_app",
	"diablo-authen-right": "/private/right/javascript/user_right_map",
	"diablo-login-out": "/private/login/javascript/login_out_app",
	"diablo-filter": "/private/utils/javascript/diablo_filter_app",

	"diablo-init": "/private/init/app",

	"diablo-employee": "/private/employ/javascript/employ_app", 
	"diablo-good": "/private/wgood/js/wgood_app",

	"stock" : "/private/purchaser/js/purchaser_inventory",
	"stock-reject": "/private/purchaser/js/purchaser_reject",
	"stock-fix": "/private/purchaser/js/purchaser_inventory_fix",
	"stock-rsn":"/private/purchaser/js/purchaser_inventory_rsn",
	"stock-update": "/private/purchaser/js/purchaser_inventory_update",
	"stock-reject-update": "/private/purchaser/js/purchaser_inventory_reject_update",
	"stock-transfer": "/private/purchaser/js/purchaser_inventory_transfer" 
    },
    
    shim: {
        "angular": {
            exports: "angular",
            deps: ["jquery"]
        },
        "angular-router": {
            exports: "angular-router",
            deps: ["angular"]
        },

	"angular-resource": {
            exports: "angular-esource",
            deps: ["angular"]
        },

	"angular-zh": {
            deps: ["angular"]
        },

	"angular-local-storage": {
            exports: "angular-local-storage",
            deps: ["angular"]
        },

	"angular-ui-bootstrap": {
            exports: "angular-ui-bootstrap",
            deps: ["angular"]
        },

	"diablo-function": {
	    deps: ["jquery"] 
	},

	"diablo-authen": {
            exports: "diablo-authen",
            deps: ["angular"]
        },

	"diablo-pattern": {
            exports: "diablo-pattern",
            deps: ["angular"]
	},

	"diablo-user-right": {
            exports: "diablo-user-right",
            deps: ["angular"]
	},

	"diablo-authen-right": {
            exports: "diablo-authen-right",
            deps: ["angular"]
	},

	"diablo-login-out": {
            deps: ["angular"]
	},

	"diablo-utils": {
            exports: "diablo-utils",
            deps: ["angular"]
	},
	
        "jquery": {
            exports: "jquery"
        },

	"jquery-custom": {
	    deps: ["jquery"],
	},

	"jquery-cookie": {
	    deps: ["jquery"]
        },

	"jquery-block": {
	    deps: ["jquery"]
        },
	
	"jquery-migrate": {
	    deps: ["jquery"]
        },

	"bootstrap": {
	    deps: ["jquery"]
	},

	"fastclick": {
	    // deps: ["jquery"]
	},

	"diablo-good": {
            exports: "diablo-good",
            deps: ["angular"]
	},
	
	"diablo-filter": {
            exports: "diablo-filter",
            deps: ["angular", "diablo-good"]
	},

	"diablo-init":{
	    deps:["jquery"]
	},
	
	"diablo-employee": {
            exports: "diablo-employee",
            deps: ["angular"]
	},
	
	"stock": {
            deps: ["angular"]
	},

	"stock-reject": {
            deps: ["angular"]
	},

	"stock-fix": {
            deps: ["angular"]
	},

	"stock-rsn": {
            deps: ["angular"]
	},

	"stock-update": {
            deps: ["angular"]
	},

	"stock-reject-update": {
            deps: ["angular"]
	},

	"stock-transfer": {
            deps: ["angular"]
	}
    }
});

require(["jquery",
	 
	 "angular", "angular-router", "angular-resource", "angular-zh", "angular-ui-bootstrap",
	 "angular-local-storage",
	 
	 "jquery-custom", "jquery-cookie", "jquery-migrate", "jquery-block",
	 "bootstrap", "fastclick",
	 
	 "diablo-init", "diablo-function", "diablo-authen",
	 "diablo-pattern", "diablo-user-right",
	 "diablo-authen-right", "diablo-login-out", "diablo-utils", "diablo-filter", "diablo-good",

	 "diablo-employee",

	 "stock", "stock-reject", "stock-fix", "stock-rsn", "stock-update",
	 "stock-reject-update", "stock-transfer",
	 
	 "purchaserApp"], function($, angular)
	{
	    // $.noConflict();
	    // console.log(window);
	    // console.log(angular);
	    // console.log(FastClick);
	    var attachFastClick = require('fastclick');
	    attachFastClick(document.body); 
	    App.init(); 
	    $(function() {
		angular.bootstrap(document, ["purchaserApp"]);
	    });
	});
