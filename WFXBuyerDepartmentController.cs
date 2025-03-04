using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using WFX.Entities.Tables;
using System.Collections.Generic;
using WFX.API.Class.BuyerDepartment;
using System;
using WFX.Entities.Models;

namespace WFX.API.Controller.BuyerDepartment
{
    [Route("api/[controller]")]
    [ApiController]
    public class WFXBuyerDepartmentController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _env;
        private readonly ClsWFXBuyerDepartment<xtBuyerDepartment> _ClsWFXBuyerDepartment;
        public WFXBuyerDepartmentController(IWebHostEnvironment env, IConfiguration configuration,
                                                ClsWFXBuyerDepartment<xtBuyerDepartment> ClsWFXBuyerDepartment)
        {
            _configuration = configuration;
            _env = env;
            _ClsWFXBuyerDepartment = ClsWFXBuyerDepartment;

        }

        [HttpGet]
        [Route("GetBuyerDepartmentData")]
        public ActionResult GetBuyerDepartmentData()
        {
            var objResult = _ClsWFXBuyerDepartment.GetBuyerDepartmentData();
            return Ok(objResult);
        }


        [HttpPost]
        [Route("SaveBuyerDepartmentData")]
        public ActionResult SaveBuyerDepartmentData( ModelWFXBuyerDepartment BuyerDepartmentData)
        {
            var objResult = _ClsWFXBuyerDepartment.SaveBuyerDepartmentData(BuyerDepartmentData);
            return Ok(objResult);
        }
        [HttpPatch]
        [Route("UpdateBuyerDepartmentData{ID}")]
        public ActionResult UpdateBuyerDepartmentData(decimal ID, [FromBody] Dictionary<string, object> updates)
        {
            var objResult = _ClsWFXBuyerDepartment.UpdateBuyerDepartmentData(ID, updates);


            return Ok(objResult);
        }
        [HttpPost("DeleteBuyerDepartmentData")]
        public ActionResult DeleteBuyerDepartmentData([FromBody] List<decimal> BuyerDepartmentIDList)
        {
            var objResult = _ClsWFXBuyerDepartment.DeleteBuyerDepartmentData(BuyerDepartmentIDList);

            return Ok(objResult);
        }
       
    }
}



