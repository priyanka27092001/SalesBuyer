using DataAccessLayer;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using WFX.Common.DataAccessLayer.IModel;
using WFX.Common.DataAccessLayer.IRepository;
using WFX.Common.DataAccessLayer.IUnitOfWork;
using WFX.API.Class.Common;
using WFX.Entities.Models;
using WFX.Entities.Tables;
using Newtonsoft.Json;
using Dapper;
using WFX.Common.Methods;

namespace WFX.API.Class.BuyerDepartment
{
    public class ClsWFXBuyerDepartment<T> : WFXBase<T> where T : class
    {
        private readonly IRepository<xtBuyerDepartment> _BuyerDepartment;
        private readonly WFXDatabaseUtility _dbUtility;
        private readonly IRepository<xtPartyGroupDetail> _partygroup;
        private readonly IRepository<xtBusinessUnitMapping> _xtBusinessUnitMapping;
        private readonly IRepository<xtCompanyMapping> _xtCompanyMapping;
        private readonly IRepository<xtPartyProductSubCategory> _xtPartyProductSubCategory;
        private readonly IRepository<xtPartyContactBuyerDepartment> _xtPartyContactBuyerDepartment;
        private readonly IRepository<xtPartyContact> _xtPartyContact;
        private readonly IRepository<xtPartySampleType> _xtPartySampleType;



        public ClsWFXBuyerDepartment(IConfiguration configuration, DBContext context, IUnitOfWorkAsync unitOfWork
            , UserContext userContext, IDbConnection connection, IRepository<xtBuyerDepartment> buyerDepartment, WFXDatabaseUtility dbUtility,
            IRepository<xtPartyGroupDetail> partygroup, IRepository<xtBusinessUnitMapping> businessUnitMapping, IRepository<xtCompanyMapping> companyMapping,
            IRepository<xtPartyProductSubCategory> partyProductSubCategory, IRepository<xtPartyContactBuyerDepartment> partyContactBuyerDepartment,
            IRepository<xtPartyContact> partyContact, IRepository<xtPartySampleType> partySampleType)
            : base(configuration, context, unitOfWork, userContext, connection)
        {
            _BuyerDepartment = buyerDepartment;
            _dbUtility = dbUtility;
            _partygroup = partygroup;
            _xtBusinessUnitMapping = businessUnitMapping;
            _xtCompanyMapping = companyMapping;
            _xtPartyProductSubCategory = partyProductSubCategory;
            _xtPartyContactBuyerDepartment = partyContactBuyerDepartment;
            _xtPartyContact = partyContact;
            _xtPartySampleType = partySampleType;
        }
        public IWFXModel<ModelWFXBuyerDepartment> GetBuyerDepartmentData()
        {
            List<ModelWFXBuyerDepartment> BuyerDepartmentData = new List<ModelWFXBuyerDepartment>();
            BuyerDepartmentData = (from b in _context.xtBuyerDepartment
                                   join c in _context.xtCompany on b.BuyerCompanyCode equals c.MemberCompanyCode
                                   join p in _context.xtPartyGroupDetail on c.MemberCompanyCode equals p.PartyCompanyCode
                                   where p.MemberCompanyCode == _userContext.MemberCompanyCode
                                         && p.BuyerSeller == 1
                                         && p.Inactive == 0
                                         && p.PartyGroupID != 0
                                         && (p.PartyCompanyCode == "0" || b.BuyerCompanyCode == p.PartyCompanyCode)
                                         && (b.ID == 0 || b.ID == b.ID)
                                   group new { b, c } by new
                                   {
                                       b.BuyerCompanyCode,
                                       c.CompanyName,
                                       b.ID,
                                       b.DepartmentName,
                                       b.SubDepartmentLevel1,
                                       b.SubDepartmentLevel2,
                                       b.Department,
                                       b.Active,
                                       b.TNAMandatory,
                                       b.CompanyCode,
                                       b.MemberCompanyCode,
                                       b.CompanyDivisionCode
                                   } into g
                                   select new ModelWFXBuyerDepartment
                                   {
                                       BuyerCompanyCode = g.Key.BuyerCompanyCode,
                                       CompanyName = g.Key.CompanyName,
                                       ID = g.Key.ID,
                                       DepartmentName = g.Key.DepartmentName,
                                       SubDepartmentLevel1 = g.Key.SubDepartmentLevel1 ?? string.Empty,
                                       SubDepartmentLevel2 = g.Key.SubDepartmentLevel2 ?? string.Empty,
                                       Department = g.Key.Department,
                                       Active = (g.Key.Active.HasValue ? Convert.ToBoolean(g.Key.Active.Value) : Convert.ToBoolean(0)), // Default to 0 if null

                                       TNAMandatory = (g.Key.TNAMandatory.HasValue ? Convert.ToBoolean(g.Key.TNAMandatory.Value) : Convert.ToBoolean(0)), // Default to 0 if null
                                       CompanyCode = g.Key.CompanyCode,
                                       MemberCompanyCode = g.Key.MemberCompanyCode,
                                       CompanyDivisionCode = g.Key.CompanyDivisionCode,
                                       isDeletable = true
                                   }).ToList();

            foreach (var i in BuyerDepartmentData)
            {
                var BusinessUnitMapping = _xtBusinessUnitMapping.FindByCondition(x => x.BuyerDepartmentID == i.ID).Any();
                var CompanyMapping= _xtCompanyMapping.FindByCondition(x => x.BuyerDepartmentID == i.ID).Any();
                var PartyProductSubCategory = _xtPartyProductSubCategory.FindByCondition(x => x.BuyerDepartmentID == i.ID && x.PartyCompanyCode == i.BuyerCompanyCode).Any();
                var PartySampleType = _xtPartySampleType.FindByCondition(x => x.BuyerDepartmentID == i.ID && x.PartyCompanyCode == i.BuyerCompanyCode).Any();
                var PartyContactBuyerDepartment = _xtPartyContactBuyerDepartment.FindByCondition(x => x.BuyerDepartmentID == i.ID).Join( _xtPartyContact.FindByCondition(c => c.PartyCompanyCode == i.BuyerCompanyCode),
                    x => x.PartyContactID, c => c.PartyContactID, (x, c) => new { x, c }).Any();

                if (BusinessUnitMapping|| CompanyMapping|| PartyProductSubCategory|| PartySampleType|| PartyContactBuyerDepartment)
                {
                    i.isDeletable = false;

                }
            }
            return WFXResponse.CreateSuccessResponse(BuyerDepartmentData);
        }

        public dynamic SaveBuyerDepartmentData(ModelWFXBuyerDepartment BuyerDepartmentData)
        {
            string jsonData = JsonConvert.SerializeObject(BuyerDepartmentData);
            string sql = "xspBuyerDepartmentJsonSaveData";
            var parameters = new DynamicParameters();
            parameters.Add("@guid", _userContext.GUID, DbType.String);
            parameters.Add("@data", jsonData, DbType.String);
            parameters.Add("@Response", dbType: DbType.String, direction: ParameterDirection.Output, size: 4000);

            _connection.Execute(sql, parameters, commandType: CommandType.StoredProcedure);

            string errorMsg = parameters.Get<string>("Response");
            if (!string.IsNullOrEmpty(errorMsg))
                return WFXResponse.CreateErrorResponse<object>(errorMsg);

            return WFXResponse.CreateSuccessResponse();
        }
        public IWFXModel<object> UpdateBuyerDepartmentData(decimal ID, Dictionary<string, object> updates)
        {
            return ExecuteUpdateEntity(() =>
            {
                xtBuyerDepartment entity = new();
                entity.ID = ID;
                _BuyerDepartment.UpdateEntity(entity, updates);
            });
        }
        public IWFXModel<object> DeleteBuyerDepartmentData(List<decimal> BuyerDepartmentIDList)
        {
            var buyerDepartmentIDs = BuyerDepartmentIDList.Select(id => id.ToString()).ToList();
            return ExecuteDeleteEntity(() =>
            {
                foreach (decimal id in BuyerDepartmentIDList)
                {
                    var a = _BuyerDepartment.FindByCondition(x => x.ID == id).FirstOrDefault();
                    _BuyerDepartment.DeleteEntity(a);
                }
            });
        }
    }
}
