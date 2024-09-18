/*
* @Name: ECM_EandSPDFTableComponentController
* @Purpose: Typecast table data from String to tableWrapper & handles back-end operations of 
* @History:                                                                                                                       
* VERSION        AUTHOR            DATE              DETAIL
* 1.0         Pratap Sen                         Initial Development
*/
public class ECM_EandSPDFTableComponentController {
    public String tableDataString {get;set;}
    public ECM_EandSTableGenerateController.tableWrapper tableDataWrapper{get;set;}
    public List<ECM_EandSTableGenerateController.colCell> columns {get;set;}
    public ECM_EandSPDFTableComponentController(){
        
    }
    /*
    * Name : gettableData
    * @description : getter Method to fetch typeCasted tableData as it is binded with Assigned to Attribute which executes after constructor
    * @return :ECM_EandSTableGenerateController.tableWrapper - Table Wrapper typecasted from String
    * @param : void
    */ 
    public ECM_EandSTableGenerateController.tableWrapper gettableData(){
        columns = new List<ECM_EandSTableGenerateController.colCell>();
        if(tableDataString != null && tableDataString != ''){
            tableDataWrapper = (ECM_EandSTableGenerateController.tableWrapper)JSON.deserialize(tableDataString,ECM_EandSTableGenerateController.tableWrapper.class);
       if(tableDataWrapper.colNames != null){
            for(String nm : tableDataWrapper.colNames){
                columns.add(new ECM_EandSTableGenerateController.colCell(nm));
            }
       }
        }
       return tableDataWrapper;
    }
}