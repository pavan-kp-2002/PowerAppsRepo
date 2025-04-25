using System;
using Microsoft.Uii.Common.Entities;
using Microsoft.Xrm.Tooling.PackageDeployment.CrmPackageExtentionBase;

namespace CCLLC.Cds.DeploymentPackage
{   
    public abstract class CCLLCImportExtension : ImportExtension
    {
        /// <summary>
        /// Called When the package is initialized. 
        /// </summary>
        public override void InitializeCustomExtension()
        {
            // Validate the state of the runtime settings object.  
            if (RuntimeSettings != null)
            {
                PackageLog.Log(string.Format("Runtime Settings populated.  Count = {0}", RuntimeSettings.Count));
                foreach (var setting in RuntimeSettings)
                {
                    PackageLog.Log(string.Format("Key={0} | Value={1}", setting.Key, setting.Value.ToString()));
                }

                // Check to see if skip checks is present.  
                if (RuntimeSettings.ContainsKey("SkipChecks"))
                {
                    bool bSkipChecks = false;
                    if (bool.TryParse((string)RuntimeSettings["SkipChecks"], out bSkipChecks))
                        OverrideDataImportSafetyChecks = bSkipChecks;
                }
            }
            else
                PackageLog.Log("Runtime Settings not populated");
        }

        /// <summary>
        /// Called Before Import Completes. 
        /// </summary>
        /// <returns></returns>
        public override bool BeforeImportStage()
        {          
            return true;
        }

        public override void PreSolutionImport(string solutionName, bool solutionOverwriteUnmanagedCustomizations, bool solutionPublishWorkflowsAndActivatePlugins, out bool overwriteUnmanagedCustomizations, out bool publishWorkflowsAndActivatePlugins)
        {
            // always overwrite unmanaged customizations
            overwriteUnmanagedCustomizations = true;

            // always publish workflows and activate plugins
            publishWorkflowsAndActivatePlugins = true;
        }

        /// <summary>
        /// Called for each UII record imported into the system
        /// This is UII Specific and is not generally used by Package Developers
        /// </summary>
        /// <param name="app">App Record</param>
        /// <returns></returns>
        public override ApplicationRecord BeforeApplicationRecordImport(ApplicationRecord app)
        {
            return app;  // do nothing here. 
        }

        /// <summary>
        /// Called during a solution upgrade while both solutions are present in the target CRM instance. 
        /// This function can be used to provide a means to do data transformation or upgrade while a solution update is occurring. 
        /// </summary>
        /// <param name="solutionName">Name of the solution</param>
        /// <param name="oldVersion">version number of the old solution</param>
        /// <param name="newVersion">Version number of the new solution</param>
        /// <param name="oldSolutionId">Solution ID of the old solution</param>
        /// <param name="newSolutionId">Solution ID of the new solution</param>
        public override void RunSolutionUpgradeMigrationStep(string solutionName, string oldVersion, string newVersion, Guid oldSolutionId, Guid newSolutionId)
        {

            base.RunSolutionUpgradeMigrationStep(solutionName, oldVersion, newVersion, oldSolutionId, newSolutionId);
        }

        /// <summary>
        /// Called after Import completes. 
        /// </summary>
        /// <returns></returns>
        public override bool AfterPrimaryImport()
        {
            return true; // Do nothing here/ 
        }

    }
}

