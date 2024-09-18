/**********************************************************************
  Name: EDGE_CSVFileProcessBatchWrapper
=======================================================================
  Purpose: Wrapper Class to hold successcount, errorcount, successFile, errorFile
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
	1.0        Kapil Baliyan     07-03-2019        Initial Development
***********************************************************************/
public with sharing class EDGE_CSVFileProcessBatchWrapper {
    
    public integer rowCount;
    public integer successRowCount;
    public integer failureRowCount;
    public string csvSuccessFileString;
    public string csvErrorFileString;
    public string msg;
    
    public EDGE_CSVFileProcessBatchWrapper(){
        rowCount = 0;
        successRowCount = 0;
        failureRowCount = 0;
        csvSuccessFileString = '';
        csvErrorFileString = '';
        msg = '';
    }
}