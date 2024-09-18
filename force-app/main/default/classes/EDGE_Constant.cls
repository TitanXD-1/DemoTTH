/**
* @Name: EDGE_Constant

* @Req: 


* @History                                                            
                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*  1.0    Preyanka Ghosh     01/03/2019      Initial Development
*  1.1    Monalisa Halder    01/03/2019      Adding Constant for Territory Batches  
*  1.2    Anuja              18/03/2019      Constant for GUID field value population
*  1.0    Preyanka Ghosh     10/05/2019      Group UP/Down variable
*  2.0    Anand Uppalapati   08/03/2022      Added constant for Distribution Kpi
*  3.0    Joshraj Sen        20/05/2022      Added constant for Temporarily Closed
**/
public class EDGE_Constant {
    
    public static String EDGE_TARGETMEMBER_WAITINGACTIVATION ='Waiting Activation';
    public static String EDGE_SUCCESS_STATUS ='Success';
    public static String EDGE_ERROR_STATUS ='Error';
    
     /*  Constant Stings for Territory Batch Classes */          
    public static final String WAITING_ACTIVATION = 'Waiting Activation';
    public static final String WAITING_REMOVAL = 'Waiting Removal';
    public static final String ACTIVE  = 'Active';
    public static final String TEMPORARILYCLOSED='Temporarily Closed';
    public static final String REMOVED = 'Removed';
    public static final String SALES= 'Sales';
    public static final String ASSET= 'Asset';
    
    
    
    /* Constant for GUID field value population */
    public static final String EXTERNALID_GUID_FIELD_NAME = 'GUID__c';
    
    /***Public Group Suffix ***/
    public static final String EDGE_GROUP_UP = '_Up';
    public static final String EDGE_GROUP_DOWN = '_Down';
    
    /**Order Constant String**/
    public static final String ORDER_SUBMITTED = 'Submitted';
    public static final String ORDER_WAREHOUSE = 'Warehouse';
    public static final String ORDER_SHED = 'Shed';
    public static final String ORDER_READY_FOR_ORDER = 'Ready for Order';
    public static final String ORDER_APPRV_IN_PROGRESS = 'Approval In Progress';
    public static final String ORDER_HELD = 'Order Held';
    
    /**Return Beer Tag Constant String**/
    public static final String SAP_Success = 'SAP Success';
    public static final String SAP_Failure = 'SAP Failure';
    public static final String Salesforce_Failure = 'Salesforce Failure';



    /*D1 constant**/
    public static Boolean HAS_ACCOUNT_INSERT_RUN = false;

         /**Quality Case Trigger Helper Constant String**/
    public static final String ONHOLD_QUALITYCASE = 'On Hold';
    public static final String OPEN_QUALITYCASE = 'Open';
    public static final String PENDING_QUALITYCASE = 'Pending';
    public static final String CLOSED_QUALITYCASE = 'Closed';
    
    public static final String EDGE_NO_OF_VISITS = 'Number of Visits';
    public static final String EDGE_CASETASK_SLA = 'Case Task vs SLA';
    public static final String EDGE_CASETASK_TOTAL = 'Case Task vs Total';
    public static final String EDGE_UNIQUE_OUTLETS = 'Unique Outlets';
    
    
    public static final String EDGE_NO_OF_VISITS_KEY = '_Number_Of_Visits';
    public static final String EDGE_CASETASK_SLA_KEY = '_Case_Task_SLA';
    public static final String EDGE_CASETASK_TOTAL_KEY = '_Case_Task_Total';
    public static final String EDGE_UNIQUE_OUTLETS_KEY = '_Unique_Outlets';
    
    /**Outlet KPI Achievement Batch Constanst**/
    public static final String SALES_KPI_TYPE = 'Coverage for Sales';
    public static final String QUALITY_KPI_TYPE = 'Coverage for Quality';
    public static final String ACTIVATION_KPI_TYPE = 'Coverage for Activation Specialist';
    public static final String COVERAGE_COMPLIANCE_STR = 'Coverage Compliance';
    
    public static final String Distribution = 'Distribution__c'; //ES20-12266
}