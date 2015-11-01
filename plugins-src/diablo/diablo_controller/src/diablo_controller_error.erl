
-module(diablo_controller_error).

-include("../../../../include/knife.hrl").

-compile(export_all).

%% member
success(add_member, Mobile) ->
    {0, "Success to create a member with member " ++ ?to_s(Mobile)};
success(delete_member, Number) ->
    {0, "Success to delete a member with member " ++ ?to_s(Number)};
success(update_member, Number) ->
    {0, "Success to update member with member " ++ ?to_s(Number)};
success(score_to_money, Number) ->
    {0, "Success to consumed score with member " ++ ?to_s(Number)};

%% merchant
success(add_merchant, Name) ->
    {0, "Success to create a merchant " ++ ?to_s(Name)};
success(delete_merchant, Id) ->
    {0, "Success to delete the merchant " ++ ?to_s(Id)};
success(update_merchant, Id) ->
    {0, "Success to update the merchant " ++ ?to_s(Id)};

%% employ
success(add_employ, Name) ->
    {0, "Success to create a employ " ++ ?to_s(Name)};
success(update_employ, Id) ->
    {0, "Success to update the employ " ++ ?to_s(Id)};
success(delete_employ, Id) ->
    {0, "Success to delete the employ " ++ ?to_s(Id)};


%% shop
success(add_shop, Name) ->
    {0, "Success to create a shop " ++ ?to_s(Name)};
success(update_shop, Id) ->
    {0, "Success to update the shop with id  " ++ ?to_s(Id)};
success(delete_shop, Id) ->
    {0, "Success to delete the shop with id " ++ ?to_s(Id)};
success(add_repo, Id) ->
    {0, "Success to create a repertory " ++ ?to_s(Id)};

%% right
success(add_account, Name) ->
    {0, "Success to create a account " ++ ?to_s(Name)};
success(delete_account, Account) ->
    {0, "Success to delete the account " ++ ?to_s(Account)};
success(update_account_role, Role) ->
    {0, "Success to update account's role with new role " ++ ?to_s(Role)};
success(add_role, Name) ->
    {0, "Success to create a role " ++ ?to_s(Name)};
success(update_role, RoleId) ->
    {0, "Success to update the role " ++ ?to_s(RoleId)};

%% supplier
success(add_supplier, Name) ->
    {0, "Success to create a supplier " ++ ?to_s(Name)};
success(update_supplier, Id) ->
    {0, "Success to update the supplier with id  " ++ ?to_s(Id)};
success(delete_supplier, Id) ->
    {0, "Success to delete the supplier with id " ++ ?to_s(Id)};
success(add_brand, Name) ->
    {0, "Success to create the brand " ++ ?to_s(Name)};
success(connect_brand, Name) ->
    {0, "Success to connect the brand " ++ ?to_s(Name)};

%% inventory
success(add_inventory, Number) ->
    {0, "Success to create a inventory " ++ ?to_s(Number)};
success(update_inventory, Id) ->
    {0, "Success to update the inventory with id  " ++ ?to_s(Id)};
success(delete_inventory, Id) ->
    {0, "Success to delete the inventory with id " ++ ?to_s(Id)};
success(add_size_group, _) ->
    {0, "Success to add size group"};
success(add_color, Name) ->
    {0, "Success to add color of name " ++ ?to_s(Name)};
success(update_size_group, GroupId) ->
    {0, "Success to update size group [" ++ ?to_s(GroupId) ++ "]"};
success(delete_size_group, GroupId) ->
    {0, "Success to delete size group [" ++ ?to_s(GroupId) ++ "]"};
success(check_inventory, User) ->
    {0, "Success to check inventory with user " ++ ?to_s(User)};
success(pre_move_inventory, Sn) ->
    {0, "Success to pre move inventory with SN " ++ ?to_s(Sn)};
success(do_move_inventory, Sn) ->
    {0, "Success to do move inventory with SN " ++ ?to_s(Sn)};
success(do_reject_inventory, Sn) ->
    {0, "Success to do reject inventory with SN " ++ ?to_s(Sn)};
success(adjust_price, Inventory) ->
    {0, "Success to adjust price of inventory " ++ ?to_s(Inventory)};

%% sale
success(sale, Extra) ->
    {0, "Success to payment with extra: " ++ ?to_s(Extra)};
success(reject, RunningNo) ->
    {0, "Success to reject with running number: " ++ ?to_s(RunningNo)};

%% login
success(login, User) ->
    {0, "Success to login with user " ++ ?to_s(User)}; 
success(destroy_login_user, User) ->
    {0, "Success to destroy login user " ++ ?to_s(User)};

%%
%% about wholesale
%%
%% inventnory
success(add_purchaser_good, Number) ->
    {0, "Success to add purchaser good with style number " ++ ?to_s(Number)};
success(delete_purchaser_good, GoodId) ->
    {0, "Success to delete purchaser good " ++ ?to_s(GoodId)};
success(update_purchaser_good, Good) ->
    {0, "Success to update purchser good with good id " ++ ?to_s(Good)};
success(add_purchaser_inventory, RSN) ->
    {0, "Success to add purchaser inventory with rsn " ++ ?to_s(RSN)};
success(update_w_inventory, RSN) ->
    {0, "Success to update purchaser inventory with rsn " ++ ?to_s(RSN)};
success(check_w_inventory, RSN) ->
    {0, "Success to check purchaser inventory with rsn " ++ ?to_s(RSN)};
success(reject_w_inventory, Total) ->
    {0, "Success to reject purchaser inventory of total amount " ++ ?to_s(Total)};
success(fix_w_inventory, Rsn) ->
    {0, "Success to fix inventory with record no  " ++ ?to_s(Rsn)};

%% retailer
success(add_w_retailer, Retailer) ->
    {0, "Success to add retailer " ++ ?to_s(Retailer)};
success(update_w_retailer, Retailer) ->
    {0, "Success to update retailer " ++ ?to_s(Retailer)};
success(delete_w_retailer, Retailer) ->
    {0, "Success to delete retailer " ++ ?to_s(Retailer)};

%% wsale
success(new_w_sale, RSn) ->
    {0, "Success to new sale of rsn " ++ ?to_s(RSn)};
success(update_w_sale, RSn) ->
    {0, "Success to update sale of rsn " ++ ?to_s(RSn)};
success(check_w_sale, RSn) ->
    {0, "Success to check sale of rsn " ++ ?to_s(RSn)};
success(print_w_sale, RSn) ->
    {0, "Success to print sale with rsn " ++ ?to_s(RSn)};
success(new_w_sale_draft, Sn) ->
    {0, "Success to new sale draft of rsn " ++ ?to_s(Sn)};
success(get_w_sale_draft, Sn) ->
    {0, "Success to get draft " ++ ?to_s(Sn)};
success(reject_w_sale, RSn) ->
    {0, "Success to reject of rsn " ++ ?to_s(RSn)};

%% wprint
success(new_wprint_server, Server) ->
    {0, "Success to new print server " ++ ?to_s(Server)};
success(new_wprinter, PId) ->
    {0, "Success to new printer " ++ ?to_s(PId)};
success(update_wprinter, PId) ->
    {0, "Success to update printer " ++ ?to_s(PId)};
success(delete_wprinter, PId) ->
    {0, "Success to delete printer " ++ ?to_s(PId)};
success(new_wprinter_conn, CId) ->
    {0, "Success to connect the printer with connection" ++ ?to_s(CId)};
success(update_wprinter_conn, CId) ->
    {0, "Success to update the printer with connection  " ++ ?to_s(CId)};
success(delete_wprinter_conn, CId) ->
    {0, "Success to delete printer with connection" ++ ?to_s(CId)};
success(update_wprinter_format, FId) ->
    {0, "Success to update print format of " ++ ?to_s(FId)};
success(add_wprinter_format_to_shop, Shop) ->
    {0, "Success to add wprint format of shop " ++ ?to_s(Shop)};



%% base
success(base_new_card, CardNo) ->
    {0, "Success to new bank card " ++ ?to_s(CardNo)};
success(base_delete_card, CardId) ->
    {0, "Success to delete bank card " ++ ?to_s(CardId)};
success(base_update_card, CardNo) ->
    {0, "Success to update bank card " ++ ?to_s(CardNo)};
success(base_add_setting, Name) ->
    {0, "Success to add base setting of  " ++ ?to_s(Name)};
success(base_update_setting, Name) ->
    {0, "Success to update base setting of  " ++ ?to_s(Name)};
success(base_add_shop_setting, Shop) ->
    {0, "Success to add settings of shop " ++ ?to_s(Shop)};
success(base_update_passwd, Account) ->
    {0, "Success to update password of user " ++ ?to_s(Account)}. 

%% -----------------------------------------------------------------------------
%% error define
%% -----------------------------------------------------------------------------
%% members
error(number_exist, Number) ->
    {1001, "Member " ++ ?to_s(Number) ++ " has been exists."};
error(member_exist, Mobile) ->
    {1002, "Member " ++ ?to_s(Mobile) ++ " has been exists."};
error(member_not_exist, Number) ->
    {1003, "Member " ++ ?to_s(Number) ++ " does not exists."};
error(not_enough_score, Number) ->
    {1004, "Member " ++ ?to_s(Number) ++ " has not enough score."};
error(action_not_support, Action) ->
    {1004, "Action " ++ ?to_s(Action) ++ " does not supported now."};

%% login
error(login_error, _nouse) ->
    {1101, "User or password is invalid, please check."};
error(login_invalid_session, _nouse) ->
    {1102, "invalid session."}; 
error(login_no_user, _) ->
    {1103, "User name must be input."};
error(login_no_password, _) ->
    {1104, "User password must be input."};
error(login_user_active, User) ->
    {1105, "user " ++ ?to_s(User) ++ "has been logined and actitived."};
error(login_exceed_user, Merchant) ->
    {1106, "exceed the max user of merchant " ++ ?to_s(Merchant) ++ "."};
error(login_no_user_fire, Merchant) ->
    {1107, "there is no user can be fired of merchant " ++ ?to_s(Merchant) ++ "."};
error(login_invalid_user, User) ->
    {1108, "invalid user " ++ ?to_s(User) ++ "."};

%% merchant
error(merchant_exist, Name) ->
    {1201, "Merchant " ++ ?to_s(Name) ++ " has been exist."};
error(account_of_merchant_not_empty, Merchant) ->
    {1202, "Account of Merchant " ++ ?to_s(Merchant) ++ " is not empty."};

%% shop
error(shop_exist, Name) ->
    {1301, "shop " ++ ?to_s(Name) ++ " has been exist."};
error(repo_exist, Name) ->
    {1302, "repo " ++ ?to_s(Name) ++ " has been exist."};

%% employ
error(employ_exist, Name) ->
    {1401, "employ " ++ ?to_s(Name) ++ " has been exist."};


%% right
error(right_type_not_support, _nouse) ->
    {1501, "right type does not supported now."};
error(account_exist, Name) ->
    {1502, "account " ++ ?to_s(Name) ++ " has been exist."};
error(merchant_account_exist, Merchant) ->
    {1503, "account of merchant " ++ ?to_s(Merchant) ++ " has been exist."};
error(role_exist, Name) ->
    {1504, "role " ++ ?to_s(Name) ++ " has been exist."};
error(function_not_found, Name) ->
    {1505, "function " ++ ?to_s(Name) ++ " does not found."};
error(user_not_found, User) ->
    {1506, "user " ++ ?to_s(User) ++ " does not found."};
error(max_account, Merchant) ->
    {1507, "beyond the limit that merchant " ++ ?to_s(Merchant) ++ " was permited."};
error(role_empty_shop, Merchant) ->
    {1507, "shop of" ++ ?to_s(Merchant) ++ "must be created before create role."};

%% supplier
error(supplier_exist, Name) ->
    {1601, "supplier " ++ ?to_s(Name) ++ " has been exist."};

%% inventory
error(inventory_exist, Name) ->
    {1703, "supplier " ++ ?to_s(Name) ++ " has been exist."};
error(brand_exist, Name) ->
    {1704, "brand " ++ ?to_s(Name) ++ " has been exist."};
error(move_invalid_inventory, Sn) ->
    {1705, "move invalid inventory with sn " ++ ?to_s(Sn) ++ "."};
error(move_inventory_moved, Sn) ->
    {1706, "inventory with sn " ++ ?to_s(Sn) ++ " had been moved."};
error(inventory_empty, Sn) ->
    {1707, "empty inventory with sn" ++ ?to_s(Sn) ++ "."};
error(inventory_not_enough, Sn) ->
    {1708, "not enought inventory with sn" ++ ?to_s(Sn) ++ "."};

%% sale
error(failed_to_payment, Error) ->
    {1802, "failed to payment with error " ++ ?to_s(Error)};
error(failed_to_record, Error) ->
    {1803, "failed to record sale with error " ++ ?to_s(Error)};
error(failed_to_add_score, Error) ->
    {1804, "failed to add the score of member with error " ++ ?to_s(Error)};
error(failed_to_check_amount, Sn) ->
    {1805, "inventory " ++ ?to_s(Sn) ++ " not enought."};

%% attribute
error(color_exist, Color) ->
    {1901, "color " ++ ?to_s(Color) ++ " has been existed."};
error(size_group_exist, Group) ->
    {1902, "size group " ++ ?to_s(Group) ++ " has been existed."};

%%
%% about wholesale
%%

%% purchaser
error(purchaser_good_exist, Number) ->
    {2001, "purchaser good of number " ++ ?to_s(Number) ++ " is been exist."};

%% retailer
error(retailer_exist, Retailer) ->
    {2101, "retailer " ++ ?to_s(Retailer) ++ " is been exist."};

%% wprint
error(wprint_server_exist, Server) ->
    {2201, "wprint server " ++ ?to_s(Server) ++ " is been exist."};

error(wprinter_exist, PId) ->
    {2301, "wprinter " ++ ?to_s(PId) ++ " is been exist."};

error(wprinter_conn_exist, CId) ->
    {2301, "wprinter connection " ++ ?to_s(CId) ++ " is been exist."};

error(wprinter_conn_used, CId) ->
    {2302, "wprinter connection " ++ ?to_s(CId) ++ " has been used."};

%% wsale
error(shop_not_printer, Shop) ->
    {2401, "the shop " ++ ?to_s(Shop) ++ " have not printer."};
error(wsale_draft_not_exist, SN) ->
    {2501, "draft " ++ ?to_s(SN) ++ " does not exist."};
error(wsale_history_failed, Retailer) ->
    {2601, "failed to get history of retailer " ++ ?to_s(Retailer)};
error(wsale_export_error, Error) ->
    {2701, "failed to export file: " ++ ?to_s(Error)};
error(wsale_export_no_date, Merchant) ->
    {2702, "no date to export of merchant: " ++ ?to_s(Merchant)};

%% about print
error(invalid_sn, PrintSN) ->
    {2411, "invalid SN of print " ++ ?to_s(PrintSN)};
error(fail_to_process, PrintSN) ->
    {2412, "fail to process order of print " ++ ?to_s(PrintSN)};
error(long_content, PrintSN) ->
    {2413, "more than the content of print" ++ ?to_s(PrintSN)};
error(invalid_params, PrintSN) ->
    {2414, "invalid parameter of print " ++ ?to_s(PrintSN)};
error(print_timeout, RSN) ->
    {2415, "timeout of rsn " ++ ?to_s(RSN)};
error(print_unkown_error, RSN) ->
    {2416, "unkown error of print " ++ ?to_s(RSN)};
error(print_http_failed, Reason) ->
    {2417, "fail to request http message of printing:" ++ ?to_s(Reason)};
error(print_content_error, Printer) ->
    {2418, "failed to print " ++ ?to_s(Printer)};
error(printer_unconnect, Printer) ->
    {2419, "printer " ++ ?to_s(Printer) ++ " does not connected."};
error(printer_no_paper, Printer) ->
    {2420, "printer " ++ ?to_s(Printer) ++ " is not enought paper."};
error(printer_unkown_state, Printer) ->
    {2421, "printer " ++ ?to_s(Printer) ++ " in unkown state."};
error(printer_conn_not_found, Printer) ->
    {2422, "printer device " ++ ?to_s(Printer) ++ " not found."};
error(print_size_not_include, Shop) ->
    {2423, "print field size must be include of shop " ++ ?to_s(Shop)};

%% base
error(base_card_exist, CardNo) ->
    {8001, "card:" ++ ?to_s(CardNo) ++ "has been exist"};
error(base_setting_exist, EName) ->
    {8002, "name " ++ ?to_s(EName) ++ " of base setting has been exist"};
error(base_invalid_update_passwd, User) ->
    {8003, "invalid password of user " ++ ?to_s(User)};

%% DB
error(db_error, EInfo) ->
    {9001, "DB error: " ++ ?to_s(EInfo)};
error(db_timeout, _) ->
    {9001, "DB timeout."};
%% unkown method
error(unkown_operation, Method) ->
    {9002, "unkown operation: " ++ ?to_s(Method)};
%% not enought right
error(not_enought_right, Action) ->
    {9901, "not enougth right of action " ++ ?to_s(Action)};
error(operation_invalid_session, Error) ->
    {9902, "operation with invalid session with error " ++ ?to_s(Error)};

error(file_op_error, Error) ->
    {9101, "failed to operator file: ~p", [Error]}.

