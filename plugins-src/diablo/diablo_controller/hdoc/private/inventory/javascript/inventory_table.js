var inventoryTable = function () {
    return {

        //main function to initiate the module
        init: function () {
            function restoreRow(oTable, nRow) {
                var aData = oTable.fnGetData(nRow);
                var jqTds = $('>td', nRow);

                for (var i = 0, iLen = jqTds.length; i < iLen; i++) {
                    oTable.fnUpdate(aData[i], nRow, i, false);
                }

                oTable.fnDraw();
            }

            function editRow(oTable, nRow) {
                var aData = oTable.fnGetData(nRow);
                var jqTds = $('>td', nRow);
                // jqTds[0].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[0] + '">';
                jqTds[1].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[1] + '">';
                jqTds[2].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[2] + '">';
                jqTds[3].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[3] + '">';

		jqTds[4].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[4] + '">';
                jqTds[5].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[5] + '">';
                jqTds[6].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[6] + '">';
                jqTds[7].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[7] + '">';

		jqTds[8].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[8] + '">';
                jqTds[9].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[9] + '">';
                jqTds[10].innerHTML = '<input type="text" class="form-control input-small" value="' + aData[10] + '">';
		
                jqTds[11].innerHTML = '<a class="edit" href="">保存</a>';
                jqTds[12].innerHTML = '<a class="cancel" href="">取消</a>';
            }

            function saveRow(oTable, nRow) {
                var jqInputs = $('input', nRow);
                // oTable.fnUpdate(jqInputs[0].value, nRow, 0, false);
                oTable.fnUpdate(jqInputs[1].value, nRow, 1, false);
                oTable.fnUpdate(jqInputs[2].value, nRow, 2, false);
                oTable.fnUpdate(jqInputs[3].value, nRow, 3, false);
		oTable.fnUpdate(jqInputs[4].value, nRow, 4, false);
                oTable.fnUpdate(jqInputs[5].value, nRow, 5, false);
                oTable.fnUpdate(jqInputs[6].value, nRow, 6, false);
		oTable.fnUpdate(jqInputs[7].value, nRow, 7, false);
		oTable.fnUpdate(jqInputs[8].value, nRow, 8, false);
                oTable.fnUpdate(jqInputs[9].value, nRow, 9, false);
                oTable.fnUpdate(jqInputs[10].value, nRow, 10, false);
                oTable.fnUpdate('<a class="edit" href="">保存</a>', nRow, 11, false);
                oTable.fnUpdate('<a class="delete" href="">取消</a>', nRow, 12, false);
                oTable.fnDraw();
            }

            function cancelEditRow(oTable, nRow) {
                var jqInputs = $('input', nRow);
                // oTable.fnUpdate(jqInputs[0].value, nRow, 0, false);
                oTable.fnUpdate(jqInputs[1].value, nRow, 1, false);
                oTable.fnUpdate(jqInputs[2].value, nRow, 2, false);
                oTable.fnUpdate(jqInputs[3].value, nRow, 3, false);
		oTable.fnUpdate(jqInputs[4].value, nRow, 4, false);
                oTable.fnUpdate(jqInputs[5].value, nRow, 5, false);
                oTable.fnUpdate(jqInputs[6].value, nRow, 6, false);
		oTable.fnUpdate(jqInputs[7].value, nRow, 7, false);
		oTable.fnUpdate(jqInputs[8].value, nRow, 8, false);
                oTable.fnUpdate(jqInputs[9].value, nRow, 9, false);
                oTable.fnUpdate(jqInputs[10].value, nRow, 10, false);
                oTable.fnUpdate('<a class="edit" href="">编辑</a>', nRow, 11, false);
                oTable.fnDraw();
            }

            var oTable = $('#inventory_table').dataTable({
                "aLengthMenu": [
                    [5, 15, 20, -1],
                    [5, 15, 20, "所有"] // change per page values here
                ],
                // set the initial value
                "iDisplayLength": 5,
                
                "sPaginationType": "bootstrap",
                "oLanguage": {
		    "sSearch" : "搜索",
                    "sLengthMenu": "分页：_MENU_",
		    "sZeroRecords": "无记录",
		    "sInfo": "从_START_　到 第_END_　条记录，总共有_TOTAL_条记录",
		    "sInfoFiltered": "（从 _MAX_ 条记录中查询到）",
		    "sInfoEmpty": "无记录",
                    "oPaginate": {
			"sFirst": "第一页",
			"sLast":  "最后一页",
                        "sPrevious": "前一页",
                        "sNext": "后一页"
                    }
                },
                "aoColumnDefs": [{
                    'bSortable': true,
                    'aTargets': [0]
                }]
            });

	    // modify table search input
            jQuery('#inventory_table_wrapper .dataTables_filter input').addClass("form-control input-medium");
	    // modify table per page dropdown
            jQuery('#inventory_table_wrapper .dataTables_length select').addClass("form-control input-small"); 
            jQuery('#inventory_table_wrapper .dataTables_length select').select2({
		//hide search box with special css class
                showSearchInput : false 
            }); // initialize select2 dropdown

            var nEditing = null;

            $('#inventory_new').click(function (e) {
                e.preventDefault();
                var aiNew = oTable.fnAddData(['', '', '', '', '', '', '', '', '', '', '',
					      '<a class="edit" href="">保存</a>', '<a class="cancel" data-mode="new" href="">取消</a>'
					     ]);
                var nRow = oTable.fnGetNodes(aiNew[0]);
                editRow(oTable, nRow);
                nEditing = nRow;
            });

            $('#inventory_table a.delete').live('click', function (e) {
                e.preventDefault();

                if (confirm("Are you sure to delete this row ?") == false) {
                    return;
                }

                var nRow = $(this).parents('tr')[0];
                oTable.fnDeleteRow(nRow);
                alert("Deleted! Do not forget to do some ajax to sync with backend :)");
            });

            $('#inventory_table a.cancel').live('click', function (e) {
                e.preventDefault();
                if ($(this).attr("data-mode") == "new") {
                    var nRow = $(this).parents('tr')[0];
                    oTable.fnDeleteRow(nRow);
                } else {
                    restoreRow(oTable, nEditing);
                    nEditing = null;
                }
            });

            $('#inventory_table a.edit').live('click', function (e) {
                e.preventDefault();

                /* Get the row as a parent of the link that was clicked on */
                var nRow = $(this).parents('tr')[0];

                if (nEditing !== null && nEditing != nRow) {
                    /* Currently editing - but not this row - restore the old before continuing to edit mode */
                    restoreRow(oTable, nEditing);
                    editRow(oTable, nRow);
                    nEditing = nRow;
                } else if (nEditing == nRow && this.innerHTML == "Save") {
                    /* Editing this row and want to save it */
                    saveRow(oTable, nEditing);
                    nEditing = null;
                    alert("Updated! Do not forget to do some ajax to sync with backend :)");
                } else {
                    /* No edit in progress - let's start one */
                    editRow(oTable, nRow);
                    nEditing = nRow;
                }
            });
        }

    };

}();



