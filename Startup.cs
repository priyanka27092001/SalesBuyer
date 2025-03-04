using DataAccessLayer;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System;
using System.Data;
using System.IO;
using System.Text;
using WFX.API.Class;
using WFX.API.Class.AdvanceLicenseList;
using WFX.API.Class.BuyerDepartment;
using WFX.API.Class.Common;
using WFX.API.Class.Contract;
using WFX.API.Class.MRPList;
using WFX.API.Class.OCOrderLog;
using WFX.API.Class.Order;
using WFX.API.Class.ProjectGroup;
using WFX.API.Class.ReasonForOrderCancellation;
using WFX.API.Class.ReasonForSealByDateDelay;
using WFX.API.Class.WFXProposal;
using WFX.Common.DataAccessLayer.Factory;
using WFX.Common.DataAccessLayer.IModel;
using WFX.Common.DataAccessLayer.IRepository;
using WFX.Common.DataAccessLayer.IUnitOfWork;
using WFX.Common.DataAccessLayer.WFXDTOClass;
using WFX.Common.Methods;

namespace WFXWebAPIFA
{
    public class Startup
    {
        public IConfiguration Configuration { get; }
        public IHostEnvironment Environment { get; }
        public Startup(IConfiguration configuration, IHostEnvironment env)
        {
            Configuration = configuration;
            string appsettingsPatch = env.IsDevelopment() ? (AppContext.BaseDirectory) : (Directory.GetParent(Directory.GetParent(AppContext.BaseDirectory)!.FullName)!.FullName + @"/WFXConfiguration");
            var builder = new ConfigurationBuilder()
               .SetBasePath(appsettingsPatch)
               .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
               .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true)
               .AddEnvironmentVariables();
            if (env.IsDevelopment())
            {
                // This reads the configuration keys from the secret store.
                // For more details on using the user secret store see http://go.microsoft.com/fwlink/?LinkID=532709
                //builder.AddUserSecrets();
            }
            Configuration = builder.Build();
            Environment = env;
        }



        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddFrameworkServices(Configuration);
            services.AddCustomServices(Configuration);
            services.ConfigureAuthentication(Configuration);
            services.AddProjectGroupServices(Configuration);
            services.AddMRPListServices(Configuration);
            services.AddWFXClsOrderTracking(Configuration);
            services.AddWFXClsContract(Configuration);
            services.AddWFXClsBuyer(Configuration);
            services.AddWFXClsBuyerDepartment(Configuration);
            services.AddWFXClsOC(Configuration);
            services.AddWFXClsOCOrderLog(Configuration);
            services.AddClsWfxAdvanceLicenseList(Configuration);
            services.ADDWFXReasonForSealByDateDelay(Configuration);
            services.AddWFXReasonForOrderCancellation(Configuration);
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app)
        {
            if (Environment.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "WEBAPI v1"));
            }

            app.UseMiddleware<WFXErrorHandlingMiddleware>();
            app.UseStaticFiles();
            app.UseRouting();
            app.UseCors("CorsPolicy");
            app.UseHttpsRedirection();
            app.UseAuthentication();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
            //if (env.IsDevelopment())
            //{
            //    app.UseDeveloperExceptionPage();
            //}

            //app.UseHttpsRedirection();

            //app.UseRouting();

            //app.UseAuthorization();

            //app.UseEndpoints(endpoints =>
            //{
            //    endpoints.MapControllers();
            //});
        }
    }
    public static class ServiceCollectionExtensions
    {
        public static void AddFrameworkServices(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddControllers(config =>
            {
                var policy = new AuthorizationPolicyBuilder()
                                 .RequireAuthenticatedUser()
                                 .Build();

                config.Filters.Add(new AuthorizeFilter(policy));
            }).AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.PropertyNamingPolicy = null;
            });

            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "WEBAPI", Version = "v1" });
            });

            string sqlConnectionString = configuration.GetConnectionString("WFXBase");
            services.AddDbContext<DBContext>(options => options.UseSqlServer(sqlConnectionString), ServiceLifetime.Scoped);
            services.AddScoped<DbContext>(provider => provider.GetService<DBContext>());
            services.AddTransient<IDbConnection>(db => new SqlConnection(sqlConnectionString));

            services.AddCors(options =>
            {
                options.AddPolicy("CorsPolicy",
                    builder => builder.AllowAnyOrigin()
                        .AllowAnyMethod()
                        .AllowAnyHeader());
            });

            services.AddMemoryCache();
            services.AddOptions();
            services.AddSingleton(configuration);
        }
        public static void AddDatabaseUtilityCustomServices(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(WFXDatabaseUtility));
        }

        public static void AddCustomServices(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped<IUnitOfWorkAsync, UnitOfWork>();
            services.AddScoped(typeof(IWFXModel<>), typeof(WFXModel<>));
            services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
            //services.AddScoped<DbContext, DBContext>();
            services.AddScoped<UserContext>();
            //services.AddScoped<ActionFilter>();
            services.AddHttpContextAccessor();

            //services.AddCommonCustomServices(configuration);
            services.AddDatabaseUtilityCustomServices(configuration);

        }
        public static void AddProjectGroupServices(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXProjectGroup<>));
        }

        public static void AddMRPListServices(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXMRPList<>));
        }

        public static void AddWFXClsOrderTracking(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(WFXClsOrderTracking<>));
        } 
        public static void AddWFXClsContract(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXContract<>));
        }
        public static void AddWFXClsBuyer(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXBuyer<>));
        }
        public static void AddWFXClsBuyerDepartment(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXBuyerDepartment<>));
        }
        public static void AddWFXClsOC(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXOC<>));
        }
        public static void ADDWFXReasonForSealByDateDelay(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXReasonForSealByDateDelay<>));
        }
        public static void AddWFXReasonForOrderCancellation(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXReasonForOrderCancellation<>));
        }
        public static void AddWFXClsOCOrderLog(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWFXOCOrderLog<>));
        }
        public static void AddClsWfxAdvanceLicenseList(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped(typeof(ClsWfxAdvanceLicenseList<>));
        }
        public static void ConfigureAuthentication(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = false,
                    ValidateAudience = false,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = configuration.GetValue<string>("AppSettings:apiServerURL"),
                    ValidAudience = configuration.GetValue<string>("AppSettings:applicationURL"),
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration.GetValue<string>("AppSettings:Token")))
                };
            });
        }
    }
}
