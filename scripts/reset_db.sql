-- drop table inventories;
drop table province;

drop table inventory_to_shop;
drop table inventory_to_move;
drop table inventory_reject_to_supplier;
drop table users;
drop table user_to_role;
drop table roles;
drop table role_to_right;
drop table role_to_shop;
drop table brands;
drop table catlog;
drop table colors;
drop table employees;
drop table inv_types;
drop table funcs;
drop table merchants;
drop table sales;
drop table sale_reject;
drop table shops;
drop table size_group;
drop table suppliers;

drop table members;
drop table money_to_score;
-- drop table rule_money_to_score;
-- drop table rule_score_history;
-- drop table rule_score_to_money;
drop table score_to_money;

-- about wholesale
drop table color_type;

drop table w_retailer;
drop table w_inventory_good;
drop table w_inventory;
drop table w_inventory_new;
drop table w_inventory_reject;
drop table w_inventory_reject_detail;
drop table w_inventory_fix;
drop table w_inventory_fix_detail;

drop table w_sale;
drop table w_sale_detail;
drop table w_sale_reject;
drop table w_print_server;
drop table w_printer;
-- drop table color_type;


-- insert into users(name, password, type, max_create, create_date) values('admin', 'admin123', 0, 1, now());
-- insert into color_type(name) values('红色');
-- insert into color_type(name) values('黄色');
-- insert into color_type(name) values('绿色');
-- insert into color_type(name) values('蓝色');
-- insert into color_type(name) values('黑色');
-- insert into color_type(name) values('白色');
-- insert into color_type(name) values('紫色');
-- insert into color_type(name) values('灰色');
