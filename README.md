#**Basic process for creating a new solution based on the solution template follows:**
## 1. Create an empty Solution in a Sandbox environment.
    - Set the name to be "[Project Name] [App Name]" (ex: "IRIS Core")
    - Set "In Time Tec" as the publisher.
      - Should be a pre-existing publisher.
      - Prefix should be itt_
    - Set the version number to 0.0.0.1
## 2. Create Repo for the new Cds Solution (Requires elevated permissions)
## 3. Clone Repo to local machine.
## 4. Clone ‘solution_template’ to local machine
## 5. Using File Explorer, copy all files from the solution_template folder to the new Cds Solution folder except the .vs and .git folders
## 6. Using File Explorer rename the CdsSolutionTemplate.sln file to match the name of the new Cds Solution, do not change the .sln suffix. _(ex: iris_core.sln)_
## 7. Open the new Cds Solution using Visual Studio
## 8. Switch to “Folder View” in Visual Studio
## 9. Using Visual Studio, setup the template with the Cds Solution name
    - Open Search/Replace tool (Ctrl-H).
    - Enter [solutionname] into the search box (top field in the Search/Replace tool.
    - Enter the new Cds Solution name in the replace box (bottom field in the Search/Replace tool.) ex: "IRISCore"
    - Set search to Match Case.
    - Change scope to Entire Solution.
    - Click “Replace All” button.
    - Click “Yes” on dialog.
    - Note 13 replacements when search/replace is finished.
## 10. Using Visual Studio, setup the plugin project
    - Open Search/Replace tool (Ctrl-H).
    - Enter PluginAssemblyName into the search box (top field in the Search/Replace tool.)
    - Enter an assembly name based on the new Cds Solution name in the replace box (bottom field in the Search/Replace tool.) ex: "IRISCorePlugins"
    - Set search to Match Case.
    - Change scope to Entire Solution.
    - Click “Replace All” button.
    - Click “Yes” on dialog.
    - Note 18 replacements when search/replace is finished.
## 11. Export the solution from the sandbox created in step 1 into the solution and commit the solution.xml file.
