# **Editing Default Configuration**

Relevant Scripts and Functions: `defaults.m`, `defaults.mat`, `create_defaults_matfile.m`, `recover_defaults_mfile`

Most of the inputs/prompts in the codebase have a default fallback option. These prompts are skippable (as indicated in the prompt message) by entering a blank for Command Window prompts, or pressing the **Cancel** button for UI prompts. For inputs skipped as such, the default file locations/settings are defined in `defaults.mat` (located in project root directory).

To change the defaults, you may do so globally or locally. Editing `defaults.m` in the toolbox source directory counts as a global change, while editing `defaults.m` in the project root directory upon creating a project with `project_setup.m` counts as a local change. The `defaults.m` file is used to generate `defaults.mat`, which is loaded into the toolbox scripts/functions as needed.

- If the global version of `defaults.m` is changed, all new projects after these changes will use the new settings.
- If the local version of `defaults.m` is changed, only the corresponding project will use the new settings.

> WARNING: When editing the local version, DO NOT CHANGE anything related to paths (directories, basenames, extensions)! This can potentially lead to I/O problems.

In order to generate a new `defaults.mat` with edited settings within a project folder, head to the project root and run `create_defaults_matfile` in the command window, which will create a fresh copy of `defaults.mat` using the local `defaults.m`.

On the other hand, if you want to replace a project's local `defaults.m` with a fresh copy of the global `defaults.m` in the toolbox path, head to the project root and run `recover_defaults_mfile` in the command window. This will create a fresh copy of `defaults.m` using the global version stored at the toolbox path.

```
>> recover_defaults_mfile   % if replacing `defaults.m` with global version
>> create_defaults_matfile  % generate new `defaults.mat` using local `defaults.m`
```