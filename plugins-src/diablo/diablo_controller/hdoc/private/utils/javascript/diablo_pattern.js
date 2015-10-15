angular.module("diabloPattern", []).service("diabloPattern", [function(){
    // mobile
    this.mobile = /^0?(13[0-9]|15[0-35-9]|18[0236-9]|14[57])[0-9]{8}$/;

    // telphone or mobile
    this.tel_mobile = /^\d{3,4}\d{7,8}(-\d{3,4})?$|^0?(13[0-9]|15[0-35-9]|18[0236-9]|14[57])[0-9]{8}$/;

    // only number
    this.number = /^[0-9]*$/;
    
    this.positive_num = /^[1-9][0-9]*$/;
    
    this.positive_decimal_2 = /^\d+(.\d{1,2})?$/;

    this.decimal_2 = /^[+|\-]?\d+(.\d{1,2})?$/;

    this.integer_except_zero = /^[+|\-]?[1-9][0-9]*$/

    // character or number
    this.char_number = /^[A-Za-z0-9]+$/;

    // character, number or -
    this.char_number_slash_bar = /^[A-Za-z0-9-\/]{2,20}$/;

    // character, number or _
    this.char_number_underline = /^\w+$/;

    // comment
    this.comment = /^[\u4e00-\u9fa5A-Za-z0-9\uFF00-\uFFFF]+$/;

    // size group
    this.size = /^[A-Za-z0-9\/]{1,3}$/

    this.chinese = /^[\u4e00-\u9fa5]+$/;
    
    this.chinese_name = /^[\u4e00-\u9fa5]{2,3}$/;

    this.ch_en_num = /^[\u4e00-\u9fa5A-Za-z0-9]+$/;
    
    this.head_ch_en_num  = /^[\u4e00-\u9fa5][\u4e00-\u9fa5A-Za-z0-9\s]+$/;

    this.ch_name_address = /^[\u4e00-\u9fa5][\u4e00-\u9fa5A-Za-z0-9\s]+$/;

    this.style_number = /^[A-Za-z0-9-]{2,10}$/;

    // this.passwd = /^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])[a-zA-Z0-9]{6,15}/;
    this.passwd = /^(?=.*[a-zA-Z])(?=.*[0-9])[a-zA-Z0-9]{6,15}/

    this.url = '^((https|http|ftp|rtsp|mms)?://)'
	+ '?(([0-9a-z_!~*\'().&=+$%-]+: )?[0-9a-z_!~*\'().&=+$%-]+@)?' //user@ of ftp
	+ '(([0-9]{1,3}.){3}[0-9]{1,3}' // IP199.194.52.184
	+ '|' // or domain
	+ '([0-9a-z_!~*\'()-]+.)*' // domain - www.
	+ '([0-9a-z][0-9a-z-]{0,61})?[0-9a-z].' // level-2 domain
	+ '[a-z]{2,6})' // first level domain
	+ '(:[0-9]{1,4})?' // port :80
	+ '((/?)|' // a slash isn't required if there is no file name
	+ '(/[0-9a-zA-Z_!~*\'().;?:@&=+$,%#-]+)+/?)$';
}]);
