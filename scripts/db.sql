/*
Script of create DB tables, of cause, Mysql was used
*/
--
/*
shopman(1..*)---------(1)shops(0..*)--------(0..*)stocks
                           |(1..*)
                           |
                           |(1..*)
			 customer
			   |(1)
			   |
			   |(0..1)
			 member
*/

/* ***BEING*** CRM *** */
create table province(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(64),
    deleted         INTEGER default 0, -- 0: no;  1: yes
    primary key     (id)
)default charset=utf8;

create table city(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(64),
    province        INTEGER default -1,
    deleted         INTEGER default 0, -- 0: no;  1: yes
    primary key     (id)
)default charset=utf8;


create table employees
(
    id              INTEGER AUTO_INCREMENT,	
    number          VARCHAR(8),
    name            VARCHAR(64),
    sex             SMALLINT(1), -- 0:woman, 1:man
    entry           DATE,
    position        SMALLINT(1) default 2, -- 0:supper, 1: shopowner; 2: saler
    mobile          VARCHAR(11),
    address         VARCHAR(64),
    merchant        INTEGER, -- which merchant belong to
    deleted         INTEGER default 0, -- 0: no;  1: yes
    unique  key     index_mn (merchant, name),
    key             index_m  (merchant),
    primary key     (id)
) default charset=utf8;

create table merchants
(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(64) not null,
    owner            VARCHAR(64) not null,  -- the merchant belonged to
    mobile           VARCHAR(11) not null,
    address          VARCHAR(255) not null,
    type             TINYINT default 0, -- 0:saler 1:wholesaler
    province         TINYINT default -1, -- which province
    entry_date       DATE,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    unique  key index_name (name),
    primary key      (id)
) default charset=utf8;


create table shops
(
    id                 INTEGER AUTO_INCREMENT,
    repo               INTEGER default -1, -- which repertory
    type               TINYINT default 0, -- 0: shop, 1: repo
    name               VARCHAR(255) not null,
    address            VARCHAR(255),
    open_date          DATE,
    shopowner          INTEGER default -1, -- Leader of the shop, choice from employ, default is no owner
    merchant           INTEGER default -1, -- which merchant belong to
    deleted            INTEGER default 0, -- 0: no;  1: yes
    unique key index_nm (name, merchant),
    key        index_s  (merchant),
    primary key        (id)
) default charset=utf8;

create table suppliers
(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(127) not null,
    balance         DECIMAL(10, 2) default 0, -- max: 99999999.99
    mobile          VARCHAR(11),
    address         VARCHAR(256),
    merchant        INTEGER default -1, -- which merchant belong to
    change_date     DATETIME,
    entry_date      DATETIME,
    deleted         INTEGER default 0, -- 0: no;  1: yes
    unique key      index_nm (name, merchant),
    key             index_m (merchant),
    primary key     (id)
) default charset=utf8;

create table size_group(
   id               INTEGER AUTO_INCREMENT,
   name             VARCHAR(16),
   si               VARCHAR(8),
   sii              VARCHAR(8),
   siii             VARCHAR(8),
   siv              VARCHAR(8),
   sv               VARCHAR(8),
   svi              VARCHAR(8),
   merchant         INTEGER,
   deleted          INTEGER default 0, -- 0: no;  1: yes
   unique key       index_nm (name, merchant),
   key              index_m (merchant),
   primary key      (id)
)default charset=utf8;

create table colors
(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(8) not null,
    type             TINYINT default 0, -- color type, 0: nothing
    remark           VARCHAR(255),
    merchant         INTEGER default null,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    unique key       index_nm (name, merchant),
    key              index_m  (merchant),
    primary key      (id)
) default charset=utf8;

-- 1:red;  2:yellow;  3:green;  4:blue;
-- 5:dark; 6:white;   7:purple; 8:gray
create table color_type(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(8),
    deleted          INTEGER default 0, -- 0: no;  1: yes
    unique key index_n (name),
    primary key      (id)
)default charset=utf8;

create table brands(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(8) default null,
    -- pinyin           VARCHAR(16) not null,
    supplier         INTEGER default -1,  -- supplier of brand
    merchant         INTEGER default -1,  -- brand belong to
    deleted          INTEGER default 0, -- 0: no;  1: yes
    
    unique  key      index_nm (name, supplier, merchant),
    key              index_m (merchant),
    primary key      (id)
)default charset=utf8;

create table inv_types(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(64),
    -- pinyin           VARCHAR(16) not null,
    merchant         INTEGER, -- type belong to
    deleted          INTEGER default 0, -- 0: no;  1: yes

    unique  key     index_nm (name, merchant),
    key             index_m (merchant),
    primary key      (id)
)default charset=utf8;


/* --------------------------------------------------------------------------------
** right
-------------------------------------------------------------------------------- */
create table users
(
    id             INTEGER AUTO_INCREMENT,
    name           VARCHAR(127) not null,
    password       VARCHAR(127) not null, -- should be encrypt
    type           TINYINT default -1, -- type to user 0: supper, 1: merchant 2:user
    merchant       INTEGER default -1, -- which merchant belong to, 0: means super
    max_create     INTEGER default -1, -- max users can be created of the user
    create_date    DATETIME,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key    index_name (name),
    primary key    (id)
) default charset=utf8;

create table user_to_role(
    id             INTEGER AUTO_INCREMENT,
    user_id        INTEGER not null,
    role_id        INTEGER not null,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key    index_ur (user_id, role_id),
    primary key    (id)
)default charset=utf8;

create table role_to_shop(
    id             INTEGER AUTO_INCREMENT,
    role_id        INTEGER not null,
    shop_id        INTEGER not null,
    func_id        INTEGER not null,   -- right id of this shop
    merchant       INTEGER default -1,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key index_rscm (role_id, shop_id, func_id, merchant),
    primary key    (id)
)default charset=utf8; 

create table roles(
    id             INTEGER AUTO_INCREMENT,
    name           VARCHAR(127) not null,
    remark         VARCHAR(256),
    type           TINYINT default -1, -- type to role 1: merchant 2:user
    merchant       INTEGER default -1,
    created_by     INTEGER default -1, -- who create this role
    create_date    DATETIME,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key index_nm (name, merchant),
    primary key    (id)
)default charset=utf8;

create table role_to_right(
    id             INTEGER AUTO_INCREMENT,
    role_id        INTEGER not null,
    right_id       INTEGER not null,
    merchant       INTEGER default -1,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key index_rrm (role_id, right_id, merchant),
    primary key    (id)
)default charset=utf8;

create table catlog(
    id             INTEGER AUTO_INCREMENT,
    catlog_id      INTEGER not null,
    name           VARCHAR(256) not null,
    path           VARCHAR(256) not null,
    parent         INTEGER default 0, -- 0: root
    deleted        INTEGER default 0, -- 0: no;  1: yes
    primary key    (id)
)default charset=utf8;

create table funcs(
    id             INTEGER AUTO_INCREMENT,
    fun_id         INTEGER not null,
    name           VARCHAR(256) not null,
    call_fun       VARCHAR(256) not null,
    catlog         INTEGER default -1, -- -1: nothing
    deleted        INTEGER default 0, -- 0: no;  1: yes
    primary key    (id)
)default charset=utf8;
/* --------------------------------------------------------------------------------
** end right
-------------------------------------------------------------------------------- */


/* --------------------------------------------------------------------------------
** print
-------------------------------------------------------------------------------- */
create table w_print_server(
   id              INTEGER AUTO_INCREMENT,
   name            VARCHAR(256) not null, 
   path            VARCHAR(256) not null,
   entry_date      DATE, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   primary key     (id)
)default charset=utf8;

create table w_printer(
   id              INTEGER AUTO_INCREMENT,
   brand           VARCHAR(256) not null,
   model           VARCHAR(32) not null,
   -- col_width       INTEGER not null,
   entry_date      DATE not null, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   primary key     (id)
)default charset=utf8;

create table w_printer_conn(
   id              INTEGER AUTO_INCREMENT,
   printer         INTEGER not null,
   paper_column    INTEGER not null,
   paper_height    INTEGER not null, 
   server          INTEGER, 
   sn              VARCHAR(16),
   code            VARCHAR(16),
   shop            INTEGER,
   -- type            TINYINT default 0, -- 0: shop 1: respo
   status          TINYINT default 0, -- 0: start 1: pause
   merchant        INTEGER, 
   entry_date      DATE, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   primary key     (id)
)default charset=utf8;


create table w_bank_card(
   id              INTEGER AUTO_INCREMENT,
   name            VARCHAR(16) not null,
   no              VARCHAR(32) not null,
   bank            VARCHAR(64) not null,
   remark          VARCHAR(64) default null,
   merchant        INTEGER not null,
   entry_date      DATE, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   
   unique  key     index_nm (no, merchant), 
   primary key     (id)
)default charset=utf8;

-- about base setting
create table w_base_setting(
   id              INTEGER AUTO_INCREMENT,
   ename           VARCHAR(16) not null,  -- english name
   cname           VARCHAR(16) not null,  -- chinese name
   value           VARCHAR(255) not null,
   type            TINYINT not null, -- 0: print 1: table
   remark          VARCHAR(255) default null,
   shop            INTEGER default -1,
   merchant        INTEGER not null,
   entry_date      DATE, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   primary key     (id)
)default charset=utf8;

-- about print format
create table w_print_format(
   id              INTEGER AUTO_INCREMENT,
   name            VARCHAR(16) not null,
   print           TINYINT default 1,  -- 1: yes, print 0; no
   width           TINYINT not null,
   shop            INTEGER default -1, 
   merchant        INTEGER not null,
   entry_date      DATE default null,
   deleted         INTEGER default 0, -- 0: no;  1: yes
   primary key     (id)
)default charset=utf8;


/** ----------------------------------------------------------------------------
suppliers
-----------------------------------------------------------------------------**/
create table w_retailer
(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(127) not null,
    balance         DECIMAL(10, 2) default 0, -- max: 99999999.99 
    -- pinyin          VARCHAR(16) not null,
    mobile          VARCHAR(11),
    address         VARCHAR(256),
    province        TINYINT default -1,
    city            INTEGER default -1,
    merchant        INTEGER default -1, -- which merchant belong to
    change_date     DATETIME, -- last changed
    entry_date      DATE, -- last changed
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key  index_nm (name, merchant),
    key          index_m  (merchant),
    primary key     (id)
) default charset=utf8;


/*
* invnentory
*/
create table w_inventory_good
(
    id               INTEGER AUTO_INCREMENT,
    style_number     VARCHAR(64) not null,
    sex              TINYINT default -1, -- 0: man, 1:woman
    color            VARCHAR (255), -- all of the color seperate by comma "1, 2, 3..."
    season           TINYINT default -1, -- 0:spring, 1:summer, 2:autumn, 3:winter
    year             YEAR(4) default null,
    type             INTEGER default -1, -- reference to inv_type 
    size             VARCHAR(255), -- all of the size seperate by comma "S/26, M/27...."
    s_group          VARCHAR(32) default 0,  -- which size group "1, 2"
    free             TINYINT default 0,  -- 0: free color and free size 1: others	 
    brand            INTEGER default -1,
    firm             INTEGER default -1,
    org_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    tag_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    pkg_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    price3           DECIMAL(10, 2) default 0, -- max: 99999999.99
    price4           DECIMAL(10, 2) default 0, -- max: 99999999.99
    price5           DECIMAL(10, 2) default 0, -- max: 99999999.99
    discount         DECIMAL(3, 0), -- max: 100
    path             VARCHAR(255) default null, -- the image path
    alarm_day        TINYINT default -1,  -- the days of alarm
    merchant         INTEGER default -1,
    change_date      DATETIME, -- date of last change 
    entry_date       DATE,
    deleted          INTEGER default 0, -- 0: no;  1: yes

    UNIQUE key       index_sbsm (style_number, brand, merchant),
    key              index_sbm  (style_number, brand, firm, merchant),
    key              merchant (merchant),
    
    primary key      (id)
)default charset=utf8;

create table w_inventory
(
    id               INTEGER AUTO_INCREMENT,
    rsn              VARCHAR(32) default null, -- record sn    
    style_number     VARCHAR(64) not null,
    brand            INTEGER default -1,

    -- color            INTEGER default -1,
    -- size             VARCHAR(8), -- S/26, M/27.... 
    type             INTEGER default -1, -- reference to inv_type
    sex              TINYINT default -1, -- 0: man, 1:woman
    season           TINYINT default -1, -- 0:spring, 1:summer, 2:autumn, 3:winter
    amount           INTEGER default 0,
    firm             INTEGER default -1,
    s_group          VARCHAR(32) default 0,  -- which size group
    free             TINYINT default 0,  -- free color and free size 
    year             YEAR(4),

    
    org_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    tag_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    pkg_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    price3           DECIMAL(10, 2) default 0, -- max: 99999999.99
    price4           DECIMAL(10, 2) default 0, -- max: 99999999.99
    price5           DECIMAL(10, 2) default 0, -- max: 99999999.99
    discount         DECIMAL(3, 0), -- max: 100
    
    path             VARCHAR(255) default null, -- the image path
    alarm_day        TINYINT default -1,  -- the days of alarm 
    sell             INTEGER default 0,  -- how many selled
    
    shop             INTEGER default -1,
    state            INTEGER default 0,  -- 0: wait for check, 1: checked

    merchant         INTEGER default -1,
    
    last_sell        DATE default 0,
    change_date      DATETIME, -- date of last change 
    entry_date       DATE,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    
    UNIQUE key       index_sbsm (style_number, brand, shop, merchant),
    key              index_sm (shop, merchant),
    primary key      (id)
)default charset=utf8;

create table w_inventory_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) default -1, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    shop           INTEGER default -1,
    merchant       INTEGER default -1,
    total          INTEGER default 0,
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    UNIQUE key     index_sbss (style_number, brand, color, size, shop, merchant),
    key            index_sbsm (style_number, brand, shop, merchant),
    primary key    (id)
)default charset=utf8;

create table w_inventory_new(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    employ         VARCHAR(8) not null,     -- employ
    firm           INTEGER default -1, 
    shop           INTEGER default -1,                  -- which shop saled the goods
    merchant       INTEGER default -1,
    
    balance        DECIMAL(10, 2) default 0, -- max: 99999999.99, balance of last record 
    should_pay     DECIMAL(10, 2) default 0, -- max: 99999999.99
    has_pay        DECIMAL(10, 2) default 0, -- max: 99999999.99
    cash           DECIMAL(10, 2) default 0, -- max: 99999999.99
    card           DECIMAL(10, 2) default 0, -- max: 99999999.99
    wire           DECIMAL(10, 2) default 0, -- max: 99999999.99
    verificate     DECIMAL(10, 2) default 0, -- max: 99999999.99
    total          INTEGER default 0,
    comment        VARCHAR(255) default null,

    e_pay_type     TINYINT  default -1,
    e_pay          DECIMAL(10, 2) default 0, -- max: 99999999.99

    type           TINYINT default -1,  -- 0: new inventory 1: reject inventory
    
    state          TINYINT  default 0,  -- 0: wait for check, 1: checked
    check_date     DATETIME default null, -- date of last change 
    entry_date     DATETIME default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    unique  key    rsn (rsn),
    key     index_smef (shop, merchant, employ, firm),
    primary key    (id)
)default charset=utf8;

create table w_inventory_new_detail(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1, 
    -- color          INTEGER default -1,
    -- size           VARCHAR(8) default null, -- S/26, M/27.... 
    type           INTEGER default -1, -- reference to inv_type 
    sex            TINYINT default -1, -- 0: man, 1:woman
    season         TINYINT, -- 0:spring, 1:summer, 2:autumn, 3:winter
    amount         INTEGER default 0,
    firm           INTEGER default -1,

    s_group        VARCHAR(32) default 0,  -- which size group 
    free           TINYINT default 0,  -- free color and free size
    year           YEAR(4),
    
    org_price      DECIMAL(10, 2) default 0, -- max: 99999999.99
    tag_price      DECIMAL(10, 2) default 0, -- max: 99999999.99
    pkg_price      DECIMAL(10, 2) default 0, -- max: 99999999.99
    price3         DECIMAL(10, 2) default 0, -- max: 99999999.99
    price4         DECIMAL(10, 2) default 0, -- max: 99999999.99
    price5         DECIMAL(10, 2) default 0, -- max: 99999999.99
    discount       DECIMAL(3, 0)  default 100, -- max: 100
    path           VARCHAR(255) default null, -- the image path
    
    -- shop           INTEGER default -1,
    -- employ         VARCHAR(8) not null,     -- employ	 
    -- merchant       INTEGER default -1,

    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    
    unique  key  index_rsb (rsn, style_number, brand),
    key     index_sb (style_number, brand),
    primary key    (id)
)default charset=utf8;

create table w_inventory_new_detail_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    total          INTEGER default 0,
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    unique  key    index_rsbcz (rsn, style_number, brand, color, size),
    primary key    (id)
)default charset=utf8;

create table w_inventory_fix(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    shop           INTEGER,                 -- which shop saled the goods
    employ         VARCHAR(8) not null,     -- employ
    exist          INTEGER,
    fixed          INTEGER default 0,
    metric         INTEGER default 0,
    merchant       INTEGER, 
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key  index_rsn (rsn),
    primary key    (id)
)default charset=utf8;

create table w_inventory_fix_detail(
    id             INTEGER AUTO_INCREMENT,
    -- key
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    type           INTEGER default -1,
    season         TINYINT, -- 0:spring, 1:summer, 2:autumn, 3:winter 
    firm           INTEGER default -1,
    -- color          INTEGER default -1,
    
    -- size           VARCHAR(8) default null, -- S/26, M/27....
    s_group        VARCHAR(32) default 0,  -- which size group 
    free           TINYINT default 0,  -- free color and free size
    
    -- shop           INTEGER default -1,
    -- merchant       INTEGER default -1,
    
    -- season         TINYINT, -- 0:spring, 1:summer, 2:autumn, 3:winter 
    -- firm           INTEGER default -1,
    path           VARCHAR(255) default null, -- the image path
    
    -- employ         VARCHAR(8) not null,     -- employ
    
    exist          INTEGER not null,
    fixed          INTEGER default 0,
    metric         INTEGER default 0,
    
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key  index_rsb (rsn, style_number, brand),
    primary key    (id)
)default charset=utf8;

create table w_inventory_fix_detail_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    
    exist          INTEGER,
    fixed          INTEGER default 0,
    metric         INTEGER default 0,
    
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key    index_rsbcz (rsn, style_number, brand, color, size),
    primary key    (id)
)default charset=utf8;


/*
* sale
*/
create table w_sale(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    employ         VARCHAR(8) not null,     -- employ
    retailer       INTEGER, 
    shop           INTEGER,                  -- which shop saled the goods
    merchant       INTEGER,
    balance        DECIMAL(10, 2) default 0, -- max: 99999999.99, left blance
    -- cur_balance    DECIMAL(10, 2) default 0, -- max: 99999999.99, balance of current record
    should_pay     DECIMAL(10, 2) default 0, -- max: 99999999.99
    has_pay        DECIMAL(10, 2) default 0, -- max: 99999999.99
    cash           DECIMAL(10, 2) default 0, -- max: 99999999.99
    card           DECIMAL(10, 2) default 0, -- max: 99999999.99
    wire           DECIMAL(10, 2) default 0, -- max: 99999999.99
    verificate     DECIMAL(10, 2) default 0, -- max: 99999999.99
    total          INTEGER default 0,
    comment        VARCHAR(255) default null,

    e_pay_type     TINYINT  default -1,
    e_pay          DECIMAL(10, 2) default 0, -- max: 99999999.99
    
    type           TINYINT  default -1, -- 0:sale 1:reject 
    state          TINYINT  default 0,  -- 0: wait for check, 1: checked
    check_date     DATETIME default null, -- date of last change
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    unique  key rsn (rsn),
    key index_smer  (shop, merchant, employ, retailer),
    primary key     (id),
    
)default charset=utf8;

-- create table w_sale_reject(
--     id             INTEGER AUTO_INCREMENT,
--     rsn            VARCHAR(16), -- record sn
--     employ         VARCHAR(8) not null,     -- employ
--     retailer       INTEGER, 
--     shop           INTEGER,                  -- which shop saled the goods
--     merchant       INTEGER,
--     balance        DECIMAL(10, 2) default 0, -- max: 99999999.99, balance of last record
--     cur_balance    DECIMAL(10, 2) default 0, -- max: 99999999.99, balance of current record
--     total          INTEGER default 0,
--     comment        VARCHAR(255) default null,
--     -- type           TINYINT  default -1, -- 0:sale 1:reject 
--     entry_date     DATETIME,
--     deleted        INTEGER default 0, -- 0: no;  1: yes
--     primary key    (id)
-- )default charset=utf8;

/*
* sale
*/
create table w_sale_detail(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER not null default -1,
    -- color          INTEGER default -1,
    -- size           VARCHAR(8) default null, -- S/26, M/27....
    type           INTEGER default -1, -- reference to inv_type 
    s_group        VARCHAR(32) default 0,  -- which size group
    free           TINYINT default 0,  -- free color and free size 
    -- shop           INTEGER default -1,
    -- merchant       INTEGER default -1, 
    season         TINYINT default -1, -- 0:spring, 1:summer, 2:autumn, 3:winter
    firm           INTEGER default -1,
    year           YEAR(4),
    -- retailer       INTEGER default -1,
    -- employ         VARCHAR(8) not null,     -- employ
    hand           INTEGER default -1, 
    total          INTEGER default 0,
    sell_style     TINYINT default -1,
    fdiscount      DECIMAL(3, 0), -- max: 100
    fprice         DECIMAL(10, 2) default 0, -- max: 99999999.99, left blance 
    path           VARCHAR(255) default null, -- the image path
    comment        VARCHAR(127) default null,
    -- type           TINYINT default -1, -- 0:sale 1:reject 
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key  index_rsb (rsn, style_number, brand),
    key          index_sb  (style_number, brand),
    primary key    (id)
)default charset=utf8;

create table w_sale_detail_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    total          INTEGER default 0,
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key    index_rsbcz (rsn, style_number, brand, color, size),
    primary key    (id)
)default charset=utf8;
