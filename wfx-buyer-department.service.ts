import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class WfxBuyerDepartmentService {
  API_URL = environment.apiSalesUrl;
  _URL: string = '';
  private readonly salesApiUrl = `${this.API_URL}/WFXBuyerDepartment/`;
  private readonly wfxCommonApiUrl = `${environment.apiCommonUrl}/`;
  constructor(private httpClient: HttpClient) {
  }
  GetBuyerDepartmentData() {
    return this.httpClient.get<any>(`${this.salesApiUrl}GetBuyerDepartmentData`);
  }
  SaveBuyerDepartmentData(Model: any) {
    return this.httpClient.post<any>(`${this.salesApiUrl}SaveBuyerDepartmentData`, Model);
  }
  UpdateBuyerDepartmentData(ID: any, updates: any) {
    return this.httpClient.patch<any>(`${this.salesApiUrl}UpdateBuyerDepartmentData` + ID, updates);
  }
  DeleteBuyerDepartmentData(Model: any) {
    return this.httpClient.post<any>(`${this.salesApiUrl}DeleteBuyerDepartmentData`, Model);
  }

  GetDDL(objectType: any, fromPage: any, pageParams: any) {
    return this.httpClient.get<any>(`${this.wfxCommonApiUrl}WFXCommonData/GetDDL?objectType=${objectType}&fromPage=${fromPage}&pageParams=${pageParams}`);
  }
}

