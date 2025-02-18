import { Component, HostListener, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import {
  WFXGridCellParams,
  WFXSectionItemParams,
  WFXTitleBarParams,
  WFXToolParams,
  WfxBottomPanelService,
  WfxCommonFunctions,
  WfxShowMessageservice,
  WfxValidationService,
} from 'wfx-erp-library';
import { WfxBuyerDepartmentService } from './wfx-buyer-department.service';
@Component({
  selector: 'wfx-buyer-department-master',
  templateUrl: './wfx-buyer-department-master.component.html',
  styles: [],
})
export class WfxBuyerDepartmentMasterComponent implements OnInit {
  constructor(
    private cmf: WfxCommonFunctions,
    public dialog: MatDialog,
    private msgsvc: WfxShowMessageservice,
    public validationService: WfxValidationService,
    private buyerdepartment: WfxBuyerDepartmentService,
    private wfxBottomPanelSvc: WfxBottomPanelService,
  ) { }
  @HostListener('click', ['$event']) onClick(e: MouseEvent) {
    this.pointerEvent = e;
  }
  pointerEvent: MouseEvent;
  lastEnteredDataOnQS: string = '';
  deptname: any;
  gridApi: any;
  rowData: any[] = [];
  itemsCount: number = 0;
  titleBarJsonDef: WFXTitleBarParams = new WFXTitleBarParams();
  itemJsonDef: WFXSectionItemParams[] = [];
  colDef: WFXGridCellParams[] = [];
  arrOriginalRowData: { index: number; id: string; data: {} }[] = [];
  toollist: WFXToolParams[] = [
    {
      toolName: '',
      toolCode: 'Delete',
      tooltip: {
        tooltipValue: 'Delete',
        tooltipValueType: 'text',
        tooltipPosition: 'above',
        UID: 'XLNK_101',
      },
      toolSvgName: 'Delete',
      UID: 'XLNK_101',
    },
  ];
  contextMenuArr: {
    contextMenu: {
      code: string;
      enabled: boolean;
      text: string;
      UID: string;
    }[];
  } = {
      contextMenu: [
        {
          code: 'Delete',
          enabled: true,
          text: 'Delete',
          UID: 'XLNK_101',
        },
      ],
    };
  BuyerDepartmentValidationRules = [
    {
      property: 'BuyerCompanyCode',
      check: 'required',
      errorMessage: 'Buyer Code is mandatory',
    },
    {
      property: 'DepartmentName',
      check: 'required',
      errorMessage: 'Department Code should be unique',
    },
  ];
  arrBuyer: any[] = [];
  result: any;
  arrBreadCrumb: any;
  quickSearchValue: any = { value: '' };
  quickSearchPlaceholder: string = 'Search by Buyer or Department';
  recordCountDef = {
    labelShowing: 'Showing',
    labelof: 'of',
    labelRecords: 'Records',
  };
  recordCountData = { showingCount: 0, totalCount: 0 };
  searchedTable: any;
  ngOnInit(): void {
    this.bindBuyerDDL();
    this.createBreadcrumbJsonDef();
    this.cmf.setPageTitle('Buyer Departments', 'LBL_TB_335');
    this.titleBarJsonDef = {
      caption: 'Buyer Departments',
      titlebarType: 'pagetitlebar',
      titlebarId: 'titlebarOperationCost',
      toolList: [],
      showAddButton: true,
      UID: 'LBL_TB_335',
    };
    this.colDef = [
      {
        colId: 'chkID',
        colName: '',
        headerCheckboxSelection: true,
        UID: '',
      },
      {
        colId: 'ddlBuyersID',
        colName: 'Buyer',
        inputType: 'select',
        valueText: 'CompanyName',
        value: 'BuyerCompanyCode',
        ddlValuesParamName: 'arrBuyer',
        editable: true,
        mandatory: true,
        width: 120,
        UID: 'LBL_196',
      },
      {
        colId: 'txtDepartmentID',
        colName: 'Department',
        inputType: 'textbox',
        valueText: 'DepartmentName',
        maxLength: 50,
        editable: true,
        mandatory: true,
        width: 120,
        UID: 'LBL_420',
      },
      {
        colId: 'txtSubDepartmentNameID',
        colName: 'Sub-Department Level 1',
        inputType: 'textbox',
        valueText: 'SubDepartmentLevel1',
        maxLength: 50,
        editable: true,
        mandatory: false,
        width: 170,
        UID: 'LBL_4259',
      },
      {
        colId: 'txtSubDepartmentNameID2',
        colName: 'Sub-Department Level 2',
        inputType: 'textbox',
        valueText: 'SubDepartmentLevel2',
        maxLength: 50,
        editable: true,
        mandatory: false,
        width: 170,
        UID: 'LBL_4260',
      },
      {
        colId: 'txtDepartmentNameID',
        colName: 'Department Name',
        inputType: 'textbox',
        valueText: 'Department',
        maxLength: 8000,
        editable: false,
        width: 130,
        UID: 'LBL_494',
      },
      {
        colId: 'chkActive',
        colName: 'Active',
        inputType: 'checkbox',
        valueText: 'Active',
        width: 100,
        UID: 'LBL_1202',
      },
      {
        colId: 'chktnaActive',
        colName: 'TNA Mandator',
        inputType: 'checkbox',
        valueText: 'TNAMandatory',
        width: 100,
        UID: 'LBL_4261',
      },
      {
        colId: 'txtExtendedMenu',
        colName: '',
        inputType: 'valueTextIcon',
        valueText: 'extendedmenu',
        onClick: [{ fnName: 'onCellContextMenu' }],
        width: 60,
        sortable: false,
        resizable: false,
        suppressValueTooltip: true,
        pinned: 'right',
        suppressMenu: true,
        openContextMenuOnClick: true,
        UID: '',
      },
      {
        colId: 'statusToolBar',
        colName: '',
        valueText: '',
        width: 55,
        value: '',
        hide: false,
        mandatory: false,
        editable: false,
        inputType: 'errorDiscard',
        pinned: 'right',
        filter: false,
        sortable: false,
        resizable: false,
        UID: '',
        onClick: [
          {
            fnName: 'onDiscardClick',
          },
        ],
        suppressMenu: true,
        lockColumnInToolPanel: true,
        hideFromColumnToolPanel: true,
      },
    ];
    this.bindGridData();
  }
  onCellContextMenu(event: any, data: any): void {
    setTimeout(() => {
      const contextMenuOptions: any = this.contextMenuArr.contextMenu.map(
        ({ text, enabled, code, UID }) => ({
          name: text,
          code: code,
          disabled: !enabled,
          UID: UID,
          action: () => {
            this.ContextMenuOnClick(code, event);
          },
        })
      );
      event.event = this.pointerEvent;
      this.cmf.overWriteGridContextMenuForcely(event, contextMenuOptions);
    }, 1);
  }
  createBreadcrumbJsonDef() {
    this.arrBreadCrumb = [
      {
        NodeName: 'Sales',
        isClickable: false,
        type: 'label',
        UID: 'LBL_TB_2383',
      },
      {
        NodeName: 'Customer',
        isClickable: false,
        type: 'label',
        UID: 'LBL_TB_1286',
      },
      {
        NodeName: 'Buyer Departments',
        isClickable: false,
        type: 'label',
        UID: 'LBL_TB_335',
      },
    ];
  }
  bindGridData() {
    this.buyerdepartment.GetBuyerDepartmentData().subscribe((res: any) => {
      if (res.StatusCode === 200 && res.ErrorMsg === '') {
        this.rowData = res.ResponseData;
        this.searchedTable = this.rowData;
        this.recordCountData = { showingCount: this.rowData.length, totalCount: this.rowData.length, };
        if (this.lastEnteredDataOnQS !== "") {
          this.onQuickSearch(this.lastEnteredDataOnQS);
        }
      } else {
        this.msgsvc.showSnackBar('Fail', res.ErrorMsg);
      }
    });
    this.itemsCount = 0;
  }
  addNewRow(e: any) {
    this.cmf.addRows(this.gridApi, {
      visibleIcon: false,
      Active: false,
      statusToolBar: {
        error: false,
        discard: false,
        errorStatus: '',
        tooltip: 'Reset',
      },
      SubDepartmentLevel1: '',
      SubDepartmentLevel2: ''
    });
  }
  gridWFXbuyerdepartment_onRowSelected() {
    const selectedRows = this.gridApi.getSelectedRows();
    this.itemsCount = selectedRows.length;
    let data: any = {
      toolsMenusArray: this.toollist,
      itemsCount: this.itemsCount,
      isCheckboxSelected: this.itemsCount === this.rowData.length,
    };
    this.wfxBottomPanelSvc.invokeInitilizeData(data);
  }
  ContextMenuOnClick(code: any, event: any) {
    if (code === 'Delete') {
      let buyerdata: any[] = [];
      if (event.data.ID > 0) {
        buyerdata.push(event.data.ID);
        this.DeleteBuyerDepartmentData(buyerdata);
      } else {
        buyerdata.push({ id: event.data.ID });
        this.deleteDataFromGrid(buyerdata);
      }
    }
  }
  OnGridReady(params: any): void {
    this.gridApi = params.api;
  }
  DeleteBuyerDepartmentData(BuyerCompanyIDList: any) {
    this.buyerdepartment.DeleteBuyerDepartmentData(BuyerCompanyIDList).subscribe((res: any) => {
      if (res.StatusCode === 200 && res.ErrorMsg === '') {
        this.msgsvc.showSnackBarMini('Success', 'Deleted Successfully!');
        this.bindGridData();
      }
    });
  }
  onCellValueChanged(event: any) {
    if (JSON.stringify(event.node.newValue) !== JSON.stringify(event.node.oldValue)) {
      if (this.cmf.getGridRowsJsonData(this.gridApi).length > 0) {
        this.arrOriginalRowData = this.cmf.storeOriginalRowData(event, this.arrOriginalRowData);
        if (this.validationService.handleCellValueChanged(event, this.BuyerDepartmentValidationRules, this.gridApi)) {
          if (
            event.node.data.BuyerCompanyCode !== '' && event.node.data.DepartmentName !== '' && event.node.data.ID) {
            const DepartmentName = event.node.data.DepartmentName || '';
            const SubDepartmentLevel1 = event.node.data.SubDepartmentLevel1 || '';
            const SubDepartmentLevel2 = event.node.data.SubDepartmentLevel2 || '';
            const updatedDepartmentName = [DepartmentName, SubDepartmentLevel1, SubDepartmentLevel2,].filter((part) => part !== '').join('-');
            event.node.data.Department = updatedDepartmentName;
            this.cmf.updateCellValue('txtDepartmentNameID', updatedDepartmentName, { params: event.node });
            const isExisting = this.rowData.some(
              (item: any) =>
                item.BuyerCompanyCode === event.node.data.BuyerCompanyCode &&
                item.DepartmentName === event.node.data.DepartmentName &&
                item.ID !== event.node.data.ID
            );
            if (isExisting) {
              this.msgsvc.showSnackBar(
                'Error',
                'This combination of BuyerCompanyCode and Department already exists.'
              );
              return;
            }
            let model: any = {
              ID: event.node.data.ID,
              CompanyName: event.node.data.CompanyName,
              DepartmentName: event.node.data.DepartmentName,
              SubDepartmentLevel1: event.node.data.SubDepartmentLevel1,
              SubDepartmentLevel2: event.node.data.SubDepartmentLevel2,
              Department: event.node.data.Department,
              Active: event.node.data.Active,
              TNAMandatory: event.node.data.TNAMandatory ?? false,
              BuyerCompanyCode: event.node.data.BuyerCompanyCode,
            };
            if (event.node.data.ID < 0 || !event.node.data.ID) {
              this.buyerdepartment.SaveBuyerDepartmentData(model).subscribe((res: any) => {
                let Response;
                Response = JSON.parse(res.ErrorMsg);
                if (Response.Status === 'Success') {
                  this.msgsvc.showSnackBar('Success', 'Saved Successfully');
                  event.node.data.ID = Response.ResponseID;
                  this.rowData.push(event.node.data);
                  this.searchedTable = [];
                  this.searchedTable = this.rowData;
                  this.gridApi.applyTransaction({
                    update: [event.node.data],
                  });
                } else {
                  this.msgsvc.showSnackBar('Error', Response.ErrorMsg);
                }
              });
            }
            else {
              const rowData = event.node.data;
              const ID = rowData.ID;
              let columnName = event.colID;
              let updates = this.getColumnUpdates(columnName, rowData);
              if (Object.keys(updates).length > 0) {
                this.UpdateBuyerDepartmentData(ID, updates);
              }
              if (updates[SubDepartmentLevel1] !== '' || updates[SubDepartmentLevel2] !== '') {
                this.deptname = 1;
                const update: any = {
                  Department: updatedDepartmentName,
                };
                this.UpdateBuyerDepartmentData(ID, update);
                this.deptname = 0;
              }
            }
          }
        }
      }
    }
  }
  UpdateBuyerDepartmentData(ID: any, updates: any) {
    this.buyerdepartment.UpdateBuyerDepartmentData(ID, updates).subscribe((res: any) => {
      if (res.StatusCode === 200) {
        if (this.deptname === 1) {
          return;
        }
        this.msgsvc.showSnackBar('Success', 'updated successfully');
      } else {
        this.msgsvc.showSnackBar('Error', res.ErrorMsg);
      }
    });
  }
  getColumnUpdates(columnName: string, rowData: any): any {
    const updatesMap: any = {
      ddlBuyersID: () => ({ BuyerCompanyCode: rowData.BuyerCompanyCode }),
      txtDepartmentID: () => ({ DepartmentName: rowData.DepartmentName }),
      txtSubDepartmentNameID: () => ({
        SubDepartmentLevel1: rowData.SubDepartmentLevel1,
      }),
      txtSubDepartmentNameID2: () => ({ SubDepartmentLevel2: rowData.SubDepartmentLevel2, }),
      chkActive: () => ({ Active: rowData.Active ? 1 : 0 }),
      chktnaActive: () => ({ TNAMandatory: rowData.TNAMandatory ? 1 : 0 }),
    };
    return updatesMap[columnName] ? updatesMap[columnName]() : {};
  }
  toolsOnClick(e: any) {
    let selectedRows = this.cmf.getGridSelectedRows(this.gridApi);
    let deleteRowsFromDB: any[] = [];
    if (e.actionCode === 'Delete') {
      let unSavedata: any[] = [];
      let selected_id: any[] = [];
      selectedRows.forEach((selectedrow: any) => {
        if (selectedrow.ID > 0) {
          deleteRowsFromDB.push(selectedrow.ID);
          selected_id.push({
            id: selectedrow.ID,
          });
        } else {
          unSavedata.push({
            id: selectedrow.ID,
          });
        }
      });
      if (unSavedata.length > 0) {
        this.deleteDataFromGrid(unSavedata);
      }
      if (deleteRowsFromDB.length > 0) {
        this.DeleteBuyerDepartmentData(deleteRowsFromDB);
      }
    }
  }
  deleteDataFromGrid(unsaveDataArr: any) {
    let rowsData: any[] = this.cmf.getGridRowsJsonData(this.gridApi, '');
    unsaveDataArr.forEach((selectedrow: any) => {
      const selectedRowdata = rowsData.filter(
        (x) => Number(x.ID) === Number(selectedrow.id)
      );
      this.cmf.deleteParticularRows(this.gridApi, selectedRowdata);
    });
  }
  onDiscardClick(rowNode: any) {
    this.arrOriginalRowData = this.cmf.onErrorDiscardIconClick(
      rowNode,
      this.arrOriginalRowData
    );
  }
  onQuickSearch(enteredData: any) {
    this.rowData = [];
    this.lastEnteredDataOnQS = enteredData;
    this.searchedTable.forEach((currentData: any) => {
      if (
        currentData.CompanyName !== undefined &&
        currentData.CompanyName.toLowerCase().indexOf(enteredData.toLowerCase()) !== -1 || currentData.Department !== undefined &&
        currentData.Department.toLowerCase().indexOf(enteredData.toLowerCase()) !== -1
      ) {
        this.rowData.push(currentData);
      }
    });
    this.recordCountData = {
      showingCount: this.rowData.length,
      totalCount: this.searchedTable.length,
    };
  }
  bindBuyerDDL() {
    this.buyerdepartment.GetDDL('Buyer', 'WFXBuyerDepartment', '').subscribe((res: any) => {
      if (res.ResponseData && res.StatusCode === 200) {
        this.arrBuyer = res.ResponseData.map((item: any) => ({
          value: item.BuyerCompanyCode,
          text: item.Buyer,
        }));
      }
    });
  }
}
