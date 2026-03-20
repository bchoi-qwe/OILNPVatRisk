Step 1 is to model WTI price as something seperate. Essentially, this is because while Spreads mean-revert due to operational logic, WTI does not.

using the research from https://openresearchsoftware.metajnl.com/articles/10.5334/jors.537

and https://cloud.r-project.org/web/packages/NFCP/vignettes/NFCP.html

as well as modifing simOU and simGBM, a simSchwartzSmith function is created. The unknown values can be found using the NFCP package.

