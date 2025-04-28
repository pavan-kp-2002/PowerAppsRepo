using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xrm.Sdk;

namespace RepoPlugin
{
    [CrmPluginRegistration(MessageNameEnum.Create,"sf_student",StageEnum.PreOperation,ExecutionModeEnum.Synchronous,"sf_age","PreCreate Validate Age",1,IsolationModeEnum.Sandbox)]
    [CrmPluginRegistration(MessageNameEnum.Update,"sf_student",StageEnum.PreOperation,ExecutionModeEnum.Synchronous,"sf_age","PreUpdate Validate Age",1,IsolationModeEnum.Sandbox)]
    public class ValidateAgePlugin : IPlugin
    {
        private const int MINAGE = 0;
        private const int MAXAGE = 150;
        public void Execute(IServiceProvider serviceProvider)
        {
            IPluginExecutionContext context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is Entity entity)
            {
                if (entity.LogicalName != "sf_student")
                {
                    return;
                }

                if(entity.Attributes.Contains("sf_age"))
                {
                    int age = entity.GetAttributeValue<int>("sf_age");

                    if(age < MINAGE || age > MAXAGE)
                    {
                        throw new InvalidPluginExecutionException("Age must be between {MINAGE} and {MAXAGE}");
                    }
                }
                    
            }

        }
    }
}
