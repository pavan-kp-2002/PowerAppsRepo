using System;
using Microsoft.Crm.Sdk.Messages;
using Microsoft.Xrm.Sdk;
using Proxy;

namespace RepoPlugin
{

    [CrmPluginRegistration(MessageNameEnum.Create,SfStudent.EntityLogicalName,StageEnum.PostOperation,ExecutionModeEnum.Synchronous,"","PostCreate Auto Rollup Calculation",1,IsolationModeEnum.Sandbox)]
    [CrmPluginRegistration(MessageNameEnum.Update,SfStudent.EntityLogicalName,StageEnum.PostOperation,ExecutionModeEnum.Synchronous,SfStudent.Fields.SfUniversity,"PostUpdate Auto Rollup Calculation",1,IsolationModeEnum.Sandbox,Image1Name ="PreImage",Image1Attributes =SfStudent.Fields.SfUniversity,Image1Type =ImageTypeEnum.PreImage)]
    [CrmPluginRegistration(MessageNameEnum.Delete,SfStudent.EntityLogicalName,StageEnum.PostOperation,ExecutionModeEnum.Synchronous,"", "PostDelete Auto Rollup Calculation", 1, IsolationModeEnum.Sandbox, Image1Name = "PreImage", Image1Attributes = SfStudent.Fields.SfUniversity, Image1Type = ImageTypeEnum.PreImage)]
    public class AutoRollUpCalculationPlugin : IPlugin
    {
        public void Execute(IServiceProvider serviceProvider)
        {
            var context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            var factory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            var service = factory.CreateOrganizationService(context.UserId);


            SfStudent target = null;
            if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is Entity targetEntity)
            {
                target = targetEntity.ToEntity<SfStudent>();
            }

            SfStudent preImage = null;
            if(context.PreEntityImages.Contains("PreImage") && context.PreEntityImages["PreImage"] is Entity preEntity)
            {
                preImage = preEntity.ToEntity<SfStudent>();
            }

            EntityReference oldUniversity = null;
            EntityReference newUniversity = null;

            switch (context.MessageName)
            {
                case "Create":
                    newUniversity = target?.SfUniversity;
                    break;

                case "Delete":
                    oldUniversity = preImage?.SfUniversity;
                    break;

                case "Update":
                    if (context.InputParameters.Contains("Target") && ((Entity)context.InputParameters["Target"]).Attributes.Contains(SfStudent.Fields.SfUniversity));
                    {
                        oldUniversity = preImage?.SfUniversity;
                        newUniversity = target?.SfUniversity;
                    }
                    break;
            }

            if((oldUniversity == null && newUniversity != null))
            {
                RecalculateRollup(service, newUniversity.Id);

            }else if(oldUniversity != null && newUniversity == null)
            {
                RecalculateRollup(service, oldUniversity.Id);
            }else if((oldUniversity != null && newUniversity != null) && oldUniversity.Id != newUniversity.Id)
            {
                RecalculateRollup(service, oldUniversity.Id);
                RecalculateRollup(service, newUniversity.Id);
            }
        }

        private void RecalculateRollup(IOrganizationService service, Guid universityId)
        {
            var request = new CalculateRollupFieldRequest
            {
                Target = new EntityReference(SfUniversity.EntityLogicalName, universityId),
                FieldName = SfUniversity.Fields.SfTotalStudents
            };
            service.Execute(request);
        }
    }
}