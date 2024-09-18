/*
* @Name: ECM_CreateContractController
* @description: This is Class for fetch required data for components "ECM_CreateContractWizard" and ECM_CreateContract
* @History                                                            

VERSION    AUTHOR                DATE	.				DETAIL
1.0     Amit, Veerendra        20/01/2020			Initial Development
Pradeep Kumar Reddy
1.1		Keshav					14/02/2020			ECM-200 :   SFDC_GLO_OBJECT_Logic_Visible agreement types
1.2		Anivesh					14/04/2020			            submitForApproval
1.3	    Saurav Prasad			19/10/2020			ECM-3042:   Territory Update only for Spain
1.4     Manikandan.T			05/03/2021      	ECM-4077:   New wrapper to include user profile in the get Contract method
1.5		Keshav					09/03/2021      	ECM-3968:   Accrual Reporting for outlet & Group Changes_SFDC_US6_Accrual
1.6     Pravalika               23/03/2021      	ECM-4153:   Accrual Reporting for Group Changes_SFDC_US6_Accrual
1.7		Chandrakanth Suram		08/04/2021		 	ECM-3990:   Added Validation for Email_for_contracts_payments__c field
1.8     Veerendra               08/04/2021      	ECM-1475:   Agreement type limited to Venue type/Local segmentation_SFDC_Logic_GLO_Create new contract
1.9		Chandrakanth Suram		12/04/2021			ECM-4205:   Included few fields in the contract query as part of US
2.0     Veerendra Billakurthi   05/05/2021      	ECM-4354:   Market setting to enable or Disable contract creation for All markets_GLOBAL_SFDC_Tech debt
2.1     Pravalika               18/05/2021      	ECM-4411:   Fields to be Made dynamic Contract Management(Screen1) wizard_Europe_SFDC_Pricelist enhancements
2.2		Chandrakanth			03/06/2021			ECM-4194:   Delegations Contract Approvals_SFDC_GLO_Contract Creation 
2.3		Keshav					23/06/2021      	ECM-4531:   Deployment_Error Message for Contract creation duplicate on draft and active
2.4     Veerendra               12/07/2021      	ECM-4635:   Error triggering while Submitting the Contract
2.5     Saurav Paul             19/07/2021      	ECM-4398:   Product strategy hard coding removal_SFDC_Tech debt
2.6		Anivesh Muppa			26/07/2021			ECM-4573:   Inculde market setting field to validate on user submission
2.7		Anuja Chattopadhyay 	26/07/2021			ECM-4627:   Screen 3 field Logic _SFDC_Ireland MVP
2.8		Anivesh Muppa			10/08/2021			ECM-4452:   Add mandatory fields validation 
2.9		Saurav Paul				12/08/2021			ECM-4691:   Screen4-ability to set one payment frequenc 
3.0     Saurav Prasad           14/09/2021      	ECM-4575:   Allow Zero Investment on Screen 4_Global
3.1     Saurav Prasad           24/09/2021      	ECM-4677:   Sales Driver Display Mandatory_SFDC_GLO_Sales Drivers
3.2     Pratap Sen              30/09/2021      	ECM-4813:   Updated Query in paymentFrequencyvalues to add Volume UoM for Beer in screen3 of contract creation
3.2     Sayan Mullick           01/10/2021      	ECM-4820:   Updated Query in selectedAgreementType with field ECM_Sales_Driver_Default_Appearance__c 
3.3     Manikandan.T            01/10/2021      	ECM-4817:   Modified the method getDefPaymentFreqAndBudgeting to include field Sales driver Budgeting
ECM-4817:   Created new wrapper called productDetailsWrapper and new methods: getproductData and saveInvestmentAmount
3.4     Manikandan.T            28/10/2021      	ECM-4881:   Modifed the paymentSchedulevalues method to include the condition for 'Single Yearly payments'
3.5     Anshu Prakash			29/10/2021			ECM-4889:   Logic for payment frequency- “Single Yearly Payments”
3.6		Anivesh Muppa		    8/11/2021	    	ECM-4908:   Logic for the Information field of SD on Screen 4 Contract creation_Single Yearly Payment
3.7		Saurav Prasad			28/12/2021			ECM-4973:   POC_Group Contract Accessibility_SFDC_GLO
3.8     Pratap Sen              31/12/2021      	ECM-4993:   Tech Debt_Remove Spanish hardcoding_GLO - updated contract item query in loadvalues()
3.9	    Keshav					13/01/2022			ECM-4644:   Attach Contract PDF to Approvals mail_GLO	
4.0     Pratap Sen              14/01/2022      	ECM-5093:   New Product Category in screen 1_AU
4.1     Saurav Prasad			28/01/2022			ECM-5090:	Logic for Approval Mail Attachment_GlO 	
4.2     Anivesh Muppa			01/02/2022			ECM-5182:	Fix for the bug 
4.3     Pratik Somani			10/02/2022			ECM-5159:	Screen 4 Contract Recalling_Validations_SFDC_AU
4.4		Saurav Prasad			21/02/2022			ECM-5220:	Logic_New Field In Agreement Type for the new screen-"Activation Spend"
4.5		Anivesh Muppa 			21/02/2022			ECM-5210:   Changes are added to save the Activation Spend screen related SD 
4.6     Saurav Paul             25/02/2022          ECM-5237:   Updation of products on Screen 4(Sales Driver) on Addition/Removal on the Screen 2(Select Products)
4.7		Anivesh Muppa			02/03/2022			ECM-5287:   Fix for Activation spend
4.8     Pratap Sen              08/03/2022          ECM-5252:   Added Logic for new fields of screen 5 for Activation Spend in loadvalues()
4.9	    Anivesh Muppa			25/03/2022		    ECM-5366:   added validation for on submit of contract as per the story 
5.0     Vinay Tummala           11/04/2022          ECM-5239:   Data Removal in SD Item Object due to change in PF fields in Screen 4_SFDC_EU
5.1     Tanishq Banerjee        05/05/2022          ECM-5443:   New fields in the Contract Objects
5.2     Anshu Prakash           06/05/2022          ECM-5442:   Formula Modification_SFDC_EU
5.3		Saurav Prasad			09/05/2022			ECM-5585:	Notification for Contract Approval_SFDC_Approval request for sales manager
5.4		Pratik 			        09/05/2022			ECM-5439:	Activation spend record saving in Sales Driver Item Details Object 
5.5     Anshu & Tanishq         23/05/2022          ECM-5497:   Screen 5 - Previous Contract Actuals Section
5.6     Anshu & Tanishq         06/03/2022          ECM-5620:   Screen 5 - KPI Calculations
5.7     Anshu & Tanishq         06/03/2022          ECM-5692:   E&S Foundation Market Setting_SFDC_AU_E&S
5.8     Vinay Tummala           07/06/2022          ECM-5649:   SFDC to handle the Approval request Email to be sent to Extra Approver_Approval request for sales manager
5.9		Kunal Parmar			10/06/2022			ECM-5622: 	getCreate method to get all the event for the contract.
ECM-5622: 	deleteEvents method to delete the events deleted from the 1st screen using the bin icon.
ECM-5622: 	Method to get the list of event & insert it
6.0     Anshu & Tanishq         17/06/2022          ECM-5762:   QA Defect_investment for Activation Spend SD is showing under the Activation Spend subgroup of the Sales Diver
6.1     Pratap & Subhrojit      23/06/2022          ECM-4846:   Logic for "Product Growth Drivers" - filterd PGD based on Growth Driver Exclusions
6.2     Anshu  & Tanishq	    24/06/2022			ECM-5538:   Display of UoMs for RTD & Draught Cocktails on different screens/pages
6.3		Saurav Prasad			06/07/2022			ECM-5790:	Validations for Addendum “Forecast Volume“ Screen_SFDC_EU
6.4		Anshu  & Tanishq		08/07/2022			ECM-5802:	Cancel Addendum for Active Contract_SFDC_EU
6.5     Anand & Prasanth        19/07/2022          ECM-5924:   Product UoM on Screen 3
6.6		Saurav Prasad			19/07/2022			ECM-5864:	UI Sales Driver Screen for Addendum_SFDC_EU
6.7		Saurav Prasad			21/07/2022			ECM-5865:	Submit & Save for Later option on Addendum Sales Drivers Screen_SFDC_EU
6.8     Vinay Tummala           21/07/2022          ECM-5793:   Logic for new products in Addendum Sales Drivers Screen_SFDC_EU
6.9		Suvendu Roy      		21/07/2022			ECM-5890:	Submit & Save for Later option on Addendum Sales Drivers Screen_SFDC_EU
7.0		Saurav Prasad			01/08/2022			ECM-5867:	Approval flow for Addendum (Prim+Contract)_SFDC_EU
7.1		Saranya L				02/08/2022			ECM-5907:	Update KPI values for Contract KPI
7.2     Pratap Sen              04/08/2022          ECM-6012:   Logic to add Forecast Volume per PF in contract items of Addendum
7.3		Saurav Prasad			16/08/2022			ECM-6032:	Approval flow for Addendum (Prim+Contract+SD+SDI)_SFDC_EU
7.4		Saurav Prasad			23/08/2022			ECM-6069:	QA Defect : Logic change for the addendum Extra Approvals with type=Contract
7.5     Anand Uppalapati        09/01/2022          ECM-6075:   Addendum PDF in Addendum Approval Email_SFDC_EU
7.6     Suvendu Roy             09/01/2022          ECM-6074:   Logic for "Type" field on Template Agreement_Addendum_SFDC_EU
7.7		Saurav Prasad			12/09/2022			ECM-6129:	UAT_GB_Migrated Contract Addendum '0' investment in SDID
7.8     Tanishq Banerjee        26/09/2022          ECM-6154:   Logic to capture lumpsum Investment at Product level_SFDC_EU
7.9     Vinay Tummala           29/09/2022          ECM-6160:   Select Multiple Product Growth Drivers (UI+Logic)_Forecast Vol Screen_SFDC_EU
8.0     Pratap Sen              24/10/2022          ECM-6264:   Added logic for sending parent contract attachments & made sendEmailToUser @future
8.1		Anuja Chattopadhyay		11/11/2022			ECM-6310:   Payment schedule section to be non-editable_Addendum_SFDC_EU
8.2     Tanishq Banerjee        29/11/2022          ECM-6404:   Screen 4 error
8.3     Suvendu Roy             11/12/2022          ECM-6432:   New fields on Activation spend Sales Driver
8.4     Pratik Somani           22/12/2022          ECM-6602:   New Field "Total A&P (including Indirect)"on CI & DTG_SFDC_EU
8.5		Saurav Prasad			06/03/2023			CUS-123	:	FASTTRACK-Logic for the Legal Compliance Field 
8.6		Saurav Prasad			15/05/2023			CUS-173 :	Contract_Legal_Beer Tap%_Logic for % of Outlets Tap Space Required)
8.7		Suvendu Roy 			15/05/2023			CUS-346 :	Validation on the Last Page of Contract Creation (for % of Outlets Tap Space Required )
8.8		Saurav Prasad 			26/06/2023			140553	:	Ability to create Multiple drafts for the same Account and Agremeent Type
8.8		Shivam Chauhan			25/08/2023			144840	:	QA: While re-submitting a contract Sales rep user gets an error message and not able to re-submit
8.9     SaiKiran                11/02/2023          146040  :   Extending contract approval emails to Activation Specialist's manager
9.0     Anamika Shukla          22/12/2023          148913  :   CRG: Remove CRG agreement from Commercial Contracts_SFDC 
9.1		Saurav Prasad			05/02/2024			148916	:	CRG: Contract Approval email template_SFDC
9.2     Joshraj Sen             26/02/2024          151301  :   Added Profile Name in the getUser Query
9.3     Saurav Prasad           26/02/2024          151029  :   Test the Business Roles with CRG permissions end to end_SFDC
9.4   Saurav Prasad/Joshraj Sen 04/03/2024          151399  :   Removed Attachments for Cold Room Grant Contracts
9.5     Joshraj Sen             08/03/2024          151678  :   Emai is not being sent 
9.6		 Shivam Chauhan		    20/03/2024		    151377	:	CRG Enhancements_No validation for number of attachments in "Approval mail attachments"_ SFDC 
9.7   Joshraj Sen/Saurav Prasad 19/04/2024          152811  :   Generates the Content Version from the Market Setting
9.8		Saurav Prasad			30/08/2024			155930	:	Fast Track Product filter on Sales Driver & Activation Spend Screen_Outlet Contract_SFDC
9.9		Saurav Prasad			06/09/2024			156533	:	QA: As Sales rep user, when user moves from 'Sales Driver' screen to 'Activation Spend' screen and again come back to 'Sales Driver' screen selected products get deselected.
10.0	Saurav Prasad			06/09/2024			156646	:	UAT: As Sales rep user, when user moves from 'Sales Driver' screen to 'Activation Spend' screen and again come back to 'Sales Driver' screen selected products get deselected.
11.1    Sakshi Shah             06/09/2024          155794  :   Agreement Type Sorting Sales Rep / Activation Specialist_Group
11.2	Dipanjan Das			06/09/2024			156040	:	Agreement Type Sorting Sales Rep / Activation Specialist_Outlet
*/ 


public without sharing class ECM_CreateContractController {
    /*
* @description : This method fetches required data to be used/checked in contract creation screens
* @return : wrapper userAndContractInfo with contract details,contract item details,current user info & screen-5 KPI graph values
* @param : contract Id
*/
    @AuraEnabled
    public static userAndContractInfo getContract(String contractid){
        //Start- Added for ECM-4077
        Map<String,List<ECM_Contract_Item__c>> pkupOptnConItemMap = new Map<String,List<ECM_Contract_Item__c>>();
        userAndContractInfo info= new userAndContractInfo();
        //End- Added for ECM-4077
        contractwithcontractitems records= new contractwithcontractitems();
        List<GraphPercentValWrapper> graphVal = new List<GraphPercentValWrapper>();
        Map<string,string> fieldsformappingrecords= new  Map<string,string>{'Draught Discounts' => 'ECM_Draught_Spirits_Discount_Level__c',
            'Pouring Discounts' => 'ECM_Spirits_Pouring_Discount_Level__c',
            'Premium Discounts' => 'ECM_Spirits_Premium_Discount_Level__c',
            'Reserve Discounts' => 'ECM_Spirits_Reserve_Discount_Level__c',
            'RTD Discount' => 'ECM_RTD_Discount_Level__c',
            'Spirits Discounts' => 'ECM_Spirits_Discount_Level__c',
            'Non Alcoholic Discounts' => 'ECM_Distilled_NonAlchlic_Discount_Level__c'};
                Map<String,contract> mapStringRecordvalue = new Map<string,contract>();
        
        //list<Discountrecord> discountsrecordsfromcontract= new list<Discountrecord>();
        set<id> marketAssortmentProductids = new set<id>();
        //CUS-173 - added "ECM_Agreement_Type__r.ECM_of_Outlets_Tap_Space_Required__c" in query
        contract conrecord=[SELECT Id, ECM_Agreement_Type__r.ECM_Beer_Tap_Term_Confirmation__c, ECM_Beer_Tap_Term_Confirmed__c, ECM_Additional_Clause__c,ECM_Agreement_Type__r.ECM_Display_Additional_Clause__c,ECM_EU_Total_Trade_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_A_P_Investment__c,ECM_Total_GP__c,ECM_GP_ROI__c,ECM_CAP_ROI__c,ECM_of_the_total_investment_vs_NSV__c,ECM_of_A_P_vs_NSV__c,ECM_of_A_P_vs_NSV_Inc_Indirect_Inv__c,ECM_Variable_share__c,ECM_Fixed_share__c,ECM_Total_TI_Investment__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,
                            ECM_Total_SKU_Specific_Rebate_Over_Term__c,ECM_Total_Others_Over_Term__c,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c,ECM_Total_Training_Over_Term__c,ECM_Total_Upfront_Payment_Loan_Over_Term__c,ECM_Total_A_P_investments__c,ECM_Overall_investments__c,accountId,Name,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                            StartDate,recordTypeId,ECM_Banner__c,ECM_Banner__r.Name,Venue_Type__c,ECM_Channel__c,BillingState,ECM_RTD_Sales_driver__c,ECM_Generated_NSV__c,ECM_Additional_information_to_support__c,
                            ECM_Spirits_Sales_driver__c,ECM_Spirits_Pouring_Sales_driver__c,ECM_Spirits_Premium_Sales_driver__c,ECM_Territory__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Hybrid_CustInvest_Total_PercentGP__c,
                            ECM_Spirits_Reserve_Sales_driver__c,ECM_Draught_Spirits_Sales_driver__c,ECM_Distilled_NonAlchlic_Sales_driver__c,ECM_Applicable_for_all_Outlets__c,ECM_Agreement_Type__c,ECM_Agreement_Type__r.Geography__c,CreatedBy.Name,Account.Name,
                            ECM_RTD_Discount_Level__c,ECM_Draught_Spirits_Discount_Level__c,ECM_Spirits_Discount_Level__c,ECM_Overall_Investment_Amount__c,OwnerId ,ECM_Recalled__c,ECM_Cloned__c,
                            ECM_Spirits_Pouring_Discount_Level__c,ECM_Spirits_Premium_Discount_Level__c,ECM_Distilled_NonAlchlic_Discount_Level__c,Recordtype.Name,Account.Local_Segment1__r.Name,
                            ECM_Spirits_Reserve_Discount_Level__c,ECM_Additional_info_to_support_decision__c,ECM_Agreement_Type__r.Geography__r.Name,ECM_OnPremise_Total_A_P_PerYear__c,ECM_Payment_Frequency_type__c,ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c,ECM_Payment_Frequency_type__r.ECM_End_Date__c,ECM_Selected_Payment_Schedule_AU__c,account.Country__r.Name,ECM_Payment_Schedule_Date_AU__c,
                            ECM_Guarantor1_Address__c,ECM_Guarantor1_email__c,ECM_Guarantor1_Name__c,ECM_Guarantor1_Number__c,Account.Country_Code__c,
                            ECM_Guarantor2_Address__c,ECM_Guarantor2_email__c,ECM_Guarantor2_Name__c,ECM_Guarantor2_Number__c, Account.Hybrid__c, Account.Parent_Outlet__c,ECM_Agreement_Type__r.ECM_Generate_Contract_Name__c,
                            ECM_Agreement_Type__r.ECM_Activation_Spend__c,ECM_Total_Brand_Marketing_A_P__c,ECM_Total_Customer_Marketing_A_P__c,ECM_Total_NSV__c,ECM_Previous_Contract__c, 
                            ECM_Primary_Spirit_Distributor__c, ECM_Secondary_Spirit_Distributor__c, ECM_Primary_Beer_Distributor__c,ECM_Forecast_KPI_Calculated__c,ECM_Amended__c,ECM_Parent_Contract__c,
                            ECM_Agreement_Type__r.ECM_of_Outlets_Tap_Space_Required__c
                            FROM contract WHERE Id=:contractid]; //added ECM_Total_NSV__c for the BUG-ECM-5421
        
        //Start added as part of ECM-5788 
        List<ECM_Addendum__c> addendumRecord = new List<ECM_Addendum__c>();
        addendumRecord = [SELECT Id FROM ECM_Addendum__c WHERE 
                          ECM_Contract__c=:contractid 
                          AND ECM_Status__c='Draft' WITH SECURITY_ENFORCED LIMIT 1];
        
        //End added as part of ECM-5788 
        mapStringRecordvalue.put(conrecord.ECM_Channel__c,conrecord);
        //155930 - ECM_Product__r.ECM_Product__r.Sub_Category_Formula__c in Query
        list<ECM_Contract_Item__c> contractitemslist=[Select Id,ECM_Product_Name__c,ECM_CAP_ROI_EU__c,ECM_Retro_investment__c,ECM_GP_ROI_EU__c,ECM_Gross_margin__c,ECM_Gross_Profit__c, ECM_Total_GP_EU__c,ECM_NSV__c,ECM_Product__r.Product__c,ECM_Product__r.ECM_Pickup_Option__c,ECM_Product__r.Product__r.Name,ECM_Product__r.ECM_Pickup_Option__r.Name, 
                                                      ECM_First_Pour__c,ECM_Mandatory_Back_Bar__c,ECM_Exclusive__c,ECM_Volume_hybrid_original__c,ECM_volume_hybrid_override__c,ECM_Generated_NSV_EU__c,
                                                      ECM_MAT_original__c,ECM_MAT_override__c,ECM_TSDD_Original__c,ECM_TSDD_Override__c,ECM_TotalAdditional_Discount__c,
                                                      ECM_TotalSKU_SpecificRebate__c,ECM_FinalLUC_Current__c,ECM_FinalLUC_Target__c,ECM_LUC_Discount__c,ECM_Investment__c,
                                                      ECM_Product__r.Product_Name__c,ECM_Product__r.Product__r.Sub_Category_Formula__c,ECM_Addendum__c,ECM_Addendum__r.ECM_Status__c 
                                                      from ECM_Contract_Item__c where ECM_Contract__c=: contractid];
        
        //Boolean displayAdditionalClause = conrecord.ECM_Agreement_Type__r.ECM_Display_Additional_Clause__c;
        
        for(ECM_Contract_Item__c conItems : contractitemslist){
            marketAssortmentProductids.add(conItems.ECM_Product__c);
            if(String.isNotBlank(conItems.ECM_Product__r.ECM_Pickup_Option__r.Name)){
                String pkUpOptnName  = conItems.ECM_Product__r.ECM_Pickup_Option__r.Name.substringBefore('[');
                if(pkupOptnConItemMap.containsKey(pkUpOptnName)){
                    pkupOptnConItemMap.get(pkUpOptnName).add(conItems);
                }else{
                    pkupOptnConItemMap.put(pkUpOptnName, new List<ECM_Contract_Item__c>{conItems});
                }
            }
        }
        if(!pkupOptnConItemMap.isEmpty()){
            graphVal = calculateMapValues(pkupOptnConItemMap);
        }
        System.debug(LoggingLevel.DEBUG,'NSVvalue-->'+conrecord.ECM_Total_NSV__c);
        list<ECM_Product_Agreement__c> products=[select id,Product_Name__c,ECM_Preferred__c, ECM_Market_Assortment_Product__c,
                                                 ECM_Market_Assortment_Product__r.Product__c,ECM_Market_Assortment_Product__r.Product__r.Name, ECM_Contract_Type__c,
                                                 ECM_Lead_Brand__c,ECM_Max_TI_limit_per_min_UoM_value__c,ECM_Max_TI_limit_per_9LC_EU_value__c,
                                                 ECM_Market_Assortment_Product__r.ECM_Pickup_Option__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c 
                                                 from ECM_Product_Agreement__c 
                                                 where ECM_Market_Assortment_Product__c in:marketAssortmentProductids AND 
                                                 ECM_Contract_Type__c =: conrecord.ECM_Agreement_Type__c  WITH SECURITY_ENFORCED];
        records.productAgrements=products;
        records.con=conrecord;
        //ECM-5788 
        records.addendum = addendumRecord.size()>0?addendumRecord[0]:null;
        records.discountrecords = returndefalutvalues(conrecord,fieldsformappingrecords,mapStringRecordvalue,null);
        records.ContractItems=contractitemslist;
        records.outletContracts = getContractOutlets(contractId);
        
        If(conrecord.ECM_Banner__c != null){
            records.bannerrecord=[select id,Name from Pick_Up_Options__c where id=:conrecord.ECM_Banner__c];
        }
        else{
            records.bannerrecord=null;
        }
        //Start- Added for ECM-4077
        user currentuserInfo=[select id,name,profileId,profile.Name from user where id=:userinfo.getUserId() WITH SECURITY_ENFORCED Limit 1];
        info.contractInfo=records;
        info.userinfo=currentuserInfo;
        //End- Added for ECM-4077
        info.graphPerctWrapper = graphVal;
        //system.debug('=='+JSON.serialize(info));
        System.debug(LoggingLevel.DEBUG,'=='+JSON.serialize(info)); 
        
        return info;
    }
    
    /*
* @description : This method fetches account details to verify that we have a real account
* @return : wrapper accountWrapper with account data and person responsible of the account
* @param : account Id
*/
    @AuraEnabled
    public static accountWrapper getAccountById(String accId) {
        accountWrapper accWr=new accountWrapper();
        //get account. All we really want is the name, to verify that we have a real account.
        Account act = new Account();
        if(accId != null){
            act = [Select id,Name,operator__r.ECM_Legal_Name__c,Person_Responsible__r.Manager.DelegatedApproverId,ECM_Legal_Name__c,Person_Responsible__c,Operator__r.Person_Responsible__c,Independent_of_Operator__c,
                   Direct_Customer__c,Global_Segment__c,Global_Sub_Segment__c,Local_Segment1__c,Local_Segment2__c,Outlet_Visit_Prioritisation_Grade__c,Outlet_Visit_Prioritisation_Grade__r.Name,Local_Segment1__r.Name,
                   BillingState,SAP_Sold_to__c,VAT_Number__c,New_VAT__c,SAP_Ship_to__c,Sales_Org__c,Person_Responsible__r.ManagerId,Person_Responsible__r.DelegatedApproverId,Hybrid__c,Global_Channel__c,Parent_Outlet__c,
                   Email_for_contracts_payments__c from Account where id=:accId WITH SECURITY_ENFORCED];
        }
        
        accWr.personResponsible = [Select id,Name,ECM_Legal_Name__c,operator__r.ECM_Legal_Name__c,Person_Responsible__c,Person_Responsible__r.ManagerId,Person_Responsible__r.DelegatedApproverId from Account where RecordType.Name='Owner/Operator' AND Person_Responsible__c =:userinfo.getUserId()];
        accWr.acc = act;
        
        return accWr;
    }
    
    /*
* @description : This method fetches market settings details to validate & auto-populate screen-1 data on outlet selection
*                - Added for ECM-4411
* @return : List of lightningTableWrapper
* @param : account Id
*/
    @AuraEnabled
    public static List<lightningTableWrapper> getMarketSettings(String AccountIds) {
        String objectName = 'Account';
        List<String> selectfields = new List<String>();
        system.debug(LoggingLevel.DEBUG,'accId-->'+AccountIds);
        Set<Id> geoCountry = new Set<Id>();
        Map<String, String> fieldConversion = new Map<String, String>();
        Map<String, String> pickValMap = new Map<String, String>();
        //List<String> fieldlistdum = new List<String>();
        //Map<String,String> labelToApiName = new Map<String,String>();
        List<ObjValues> objvalList = new List<ObjValues>();
        List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
        //Map<String, String> labelToApiMap = new Map<String, String>();
        lightningTableWrapper ltw = new lightningTableWrapper();
        //string queryStr;
        
        try{
            Account accObj;
            accObj= [Select Id,Name,Country__r.Name from Account where id=:AccountIds WITH SECURITY_ENFORCED];
            geoCountry.add(accObj.Country__c);
            system.debug(LoggingLevel.DEBUG,'geoCountry'+geoCountry);
            
            Schema.DescribeSObjectResult objSchema = Market_Setting__c.sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getmap();
            List<Schema.Picklistentry>fld =fieldmap.get('ECM_Attribute_Visibility_Screen1__c').getDescribe().getpicklistValues();
            System.debug(LoggingLevel.DEBUG,'fld'+fld);
            
            //String type='Account';
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(objectName);
            Map<String, Schema.SObjectField> fieldsMap = leadSchema.getDescribe().fields.getMap();
            
            for(Schema.Picklistentry pl : fld)
            {
                pickValMap.put(pl.getValue(),pl.getLabel());
                
            }
            System.debug(LoggingLevel.DEBUG,'pickValMap'+pickValMap );
            Market_Setting__c marketObj = [select id,ECM_Attribute_Visibility_Screen1__c from Market_Setting__c where Geography__c IN : geoCountry WITH SECURITY_ENFORCED];
            
            if(marketObj.ECM_Attribute_Visibility_Screen1__c!=null){
                selectfields = marketObj.ECM_Attribute_Visibility_Screen1__c.split(';'); 
            }
            system.debug(LoggingLevel.DEBUG,'selectfields-->'+selectfields);
            for (String field : selectfields){ 
                if(pickValMap!= null && pickValMap.containsKey(field ) && !System.Label.ECM_Excluded.contains(field)){
                    fieldConversion.put(field,pickValMap.get(field ));
                } 
                
            }
            String queryString = 'select id,';
            SObjectType r = ((SObject)(Type.forName('Schema.'+objectName).newInstance())).getSObjectType(); 
            for(String str : fieldConversion.keyset()){
                // System.debug('@@str' +str);
                //String fieldName = str;
                DescribeSObjectResult d = r.getDescribe();
                if(d.fields.getMap().containsKey(str)) {
                    if(String.ValueOf(d.fields.getMap().get(str).getDescribe().getType()) == 'REFERENCE'){
                        String fieldName =   str.replace('__c','__r.name');
                        queryString = queryString+fieldName+',';   
                    }
                    else{
                        queryString = queryString+ str+',';    
                    }
                }
            }
            queryString=queryString.removeEnd(',') +' from Account Where Id=\''+accObj.id+'\'';
            system.debug(LoggingLevel.DEBUG,'queryString'+queryString);
            accObj = database.query(queryString);
            
            for (String field : selectfields){ 
                ObjValues objval = new ObjValues();
                if(fieldConversion.containsKey(field)){
                    objval.header = fieldConversion.get(field);
                    
                    Schema.DisplayType fielddataType = fieldsMap.get(field).getDescribe().getType();
                    if(fielddataType != Schema.DisplayType.Reference){
                        objval.values = String.valueOf(accObj.get(field)); 
                    }
                    else{
                        field= field.replace('__c','__r');
                        Map<String, Object> fieldsToValue = accObj.getPopulatedFieldsAsMap();
                        system.debug(LoggingLevel.DEBUG,'fieldsToValue_1-->'+field);
                        system.debug(LoggingLevel.DEBUG,'fieldsToValue_2-->'+fieldsToValue);
                        system.debug(LoggingLevel.DEBUG,'fieldsToValue_3-->'+fieldsToValue.get(field));
                        if(fieldsToValue.get(field)!=null){
                            Object temp= fieldsToValue.get(field);
                            String value=JSON.serialize(temp);
                            system.debug(LoggingLevel.DEBUG,'fieldsToValue_4-->'+Value);
                            Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(Value);
                            system.debug(LoggingLevel.DEBUG,'fieldsToValue_5-->'+meta);
                            if(meta.get('Name')!=null){
                                objval.values=(String)meta.get('Name');
                            }
                        }
                    }
                }
                objvalList.add(objval);
            }
            system.debug(LoggingLevel.DEBUG,'objvalList>'+objvalList);
            ltw.tablerows = objvalList;
            listLgtnTableWraps.add(ltw);
            
        } 
        catch (Exception contractException) {
            System.debug(LoggingLevel.DEBUG,'Class:ECM_CreateContractController\nmethod:getMarketSettings\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
            
        }
        return listLgtnTableWraps;
        
    }
    
    /*
* @description : This method handles logic for submit for approval
* @return : objectWrapper
* @param : contract id
* @param : contract items wrapper in string
*/
    @AuraEnabled
    Public static objectWrapper submitForApproval(string ContractRec ,string contractItemsList, string outletContractList){
        Contract contractRecord;
        List<ECM_Contract_Item__c> contractItems = (List<ECM_Contract_Item__c>)JSON.deserialize(contractItemsList, List<ECM_Contract_Item__c>.class);
        try{  
            ContractRecord = savecontractanditems(ContractRec ,contractItemsList,outletContractList);
        }
        catch(Exception ex){ 
            System.debug(LoggingLevel.DEBUG,'ECM_CreateContractController line 82'+ex.getMessage());
        }
        objectWrapper wrap = new objectWrapper();
        if(ContractRecord.CreatedBy == null){//For test class
            ContractRecord = [SELECT id,accountId,Name,ContractNumber,Contract_End_Date__c,ECM_Duration__c,Status,EndDate,account.Country__r.code__c,Account.Country_Code__c,
                              StartDate,recordTypeId,ECM_Territory__c,ECM_Payment_Frequency_type__r.ECM_End_Date__c,ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c,
                              ECM_Agreement_Type__c,CreatedBy.Name,Account.Name,ECM_Overall_Investment_Amount__c,ECM_Overall_Investment_Figure__c,
                              Recordtype.Name,ECM_Amended__c,ECM_Parent_Contract__c FROM contract WHERE Id=:ContractRecord.Id WITH SECURITY_ENFORCED];
        }
        /*List<Outlet_Contract__c> outletsSelected = [SELECT Id,Outlet__c,Outlet__r.Name,Outlet__r.ECM_Legal_Name__c FROM Outlet_Contract__c 
WHERE Contract__c =: ContractRecord.Id AND Outlet__r.ECM_Legal_Name__c = NULL];*/
        AggregateResult cycleCount = [SELECT MAX(ECM_No_of_Approval_Cycles__c) FROM ECM_Approval_Log__c where ECM_Contract__c=:ContractRecord.Id WITH SECURITY_ENFORCED];
        integer approvalcount = integer.valueOf(cycleCount.get('expr0')==Null?0:cycleCount.get('expr0'));
        string errormessage='';
        string emailId = '';
        string delegatedUser = System.Label.ECM_Delegated_Approver;
        User recipentUserEmail = new User();
        string agreementId = ContractRecord.ECM_Agreement_Type__c;
        accountWrapper accwrap = getAccountById(ContractRecord.AccountId);
        wrap.acc = accwrap.acc;
        ECM_Contract_Type__c ecmContractType = [SELECT id,ECM_Aggrement_Duration__c,Geography__r.Code__c,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Automatic_approval_amount_threshold__c ,
                                                ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Contract_Approval_mail_to_Customer__c,
                                                ECM_Mandatory_Fields_Check__c FROM ECM_Contract_Type__c where Id=: agreementId WITH SECURITY_ENFORCED];
        String outletRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String groupRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Territory__c territoryDetails = new Territory__c();
        system.debug(LoggingLevel.DEBUG,'country code ='+ContractRecord.Account.Country_Code__c);
        //changes related to ECM-4573
        Market_Setting__c marketObjs= [SELECT Id, Name__c,Geography__r.Code__c,ECM_Mandatory_field_for_Contract__c,ECM_Contract_Creation_Page__c FROM Market_Setting__c where Geography__r.Code__c =:ContractRecord.Account.Country_Code__c and ECM_Contract_Management_Market__c=true limit 1];
        
        if(ContractRecord.ECM_Territory__c != Null){
            TerritoryDetails = getTerritory(ContractRecord.ECM_Territory__c);            
        }
        wrap.Upfront = ecmContractType.ECM_Contract_Approval_mail_to_Customer__c?1:0;
        try {
            //Changes related to ECM-4452
            if(!String.isBlank(ecmContractType.ECM_Mandatory_Fields_Check__c) && ecmContractType.ECM_Mandatory_Fields_Check__c.equals('Prior To Submitting Contract For Approval')){
                //added as per ECM-5366
                if(ecmContractType.ECM_Contract_Approval_mail_to_Customer__c){                
                    if(String.isBlank(accwrap.acc.Email_for_contracts_payments__c)){
                        errormessage = System.Label.ECM_Email_for_contracts_payments;
                    }
                }
                
                
                //changes related to ECM-4573
                if(!String.isBlank(marketObjs.ECM_Mandatory_field_for_Contract__c)){
                    if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('SAP Sold to')){ 
                        if(string.isBlank(accwrap.acc.SAP_Sold_to__c)){
                            errormessage += ':'+System.Label.ECM_SAP_Number_Validation;//'customer SAP number is missing from customer record, cannot submit for approval';
                        }
                    }
                    if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('VAT number')){
                        if(String.isBlank(accwrap.acc.New_VAT__c)) {
                            errormessage += System.Label.ECM_VAT_number;//':Tax registration number is missing from customer record, cannot submit for approval';
                        }
                    }
                    if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Legal Name')){ 
                        if(String.isBlank(accwrap.acc.ECM_Legal_Name__c)) {
                            errormessage += System.Label.ECM_Legal_Name_Validation;
                        }
                    }
                    if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('SAP Ship to')){
                        if(String.isBlank(accwrap.acc.SAP_Ship_to__c)){
                            errormessage += System.Label.ECM_SAP_Ship_To ;
                        }
                    }
                    if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Customer email for Contract')){
                        if(String.isBlank(accwrap.acc.Email_for_contracts_payments__c)){
                            errormessage += System.Label.ECM_Email_for_contracts_payments_Validation ;
                        }
                    }
                    if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Sales org')){ 
                        if(String.isBlank(accwrap.acc.Sales_Org__c)){
                            errormessage += System.Label.ECM_Sales_Org ;
                        }
                    }
                    if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Tax Identification number')){ 
                        if(String.isBlank(accwrap.acc.VAT_Number__c)){
                            errormessage += System.Label.ECM_Tax_Registration_Number_Validation;
                        }
                    }
                }
                //End of ECM-4573
            }
            
            //Enhancement as part of ECM-3990 US
            if(errormessage==''){
                system.debug(LoggingLevel.DEBUG,'=='+errormessage);
                if(ContractRecord.ECM_Overall_Investment_Figure__c < ecmContractType.ECM_Automatic_approval_amount_threshold__c){
                    ContractRecord.status = 'Approved';// earlier Approved';
                    errormessage ='Approved';// erlier Approved';
                }else if((ContractRecord.ECM_Overall_Investment_Figure__c == ecmContractType.ECM_Automatic_approval_amount_threshold__c) || (ContractRecord.ECM_Overall_Investment_Figure__c > ecmContractType.ECM_Automatic_approval_amount_threshold__c) || (ContractRecord.ECM_Overall_Investment_Figure__c==Null)){
                    ContractRecord.status = 'In Approval Process';
                    //create Approval Log                    
                    ECM_Approval_Log__c approvLog = new ECM_Approval_Log__c();
                    approvLog.ECM_Time_Date_Log__c	 = system.now();
                    approvLog.Name = ContractRecord.ContractNumber;
                    approvLog.ECM_No_of_Approval_Cycles__c = approvalcount+1;
                    approvLog.RecordTypeId =Schema.getGlobalDescribe().get('ECM_Approval_Log__c').getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
                    //146040 -> start
                    if(outletRecordTypeID == ContractRecord.RecordTypeId && TerritoryDetails!=Null && TerritoryDetails.Activation_Specialist__r.ManagerId!=Null){
                        if(TerritoryDetails.Activation_Specialist__r.Manager.DelegatedApproverId == Null){
                            recipentUserEmail = getUser(TerritoryDetails.Activation_Specialist__r.ManagerId);
                            EmailId = recipentUserEmail.Email;
                            approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?recipentUserEmail.Title:'';
                        }else{
                            //Delegation Approval Log
                            recipentUserEmail = getUser(TerritoryDetails.Activation_Specialist__r.Manager.DelegatedApproverId);
                            EmailId = recipentUserEmail.Email;
                            approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?DelegatedUser+' '+recipentUserEmail.Title:'';
                        }
                    }//146040 -> end  
                    //Start of ECM-4194
                    if(outletRecordTypeID == ContractRecord.RecordTypeId && TerritoryDetails!=Null && TerritoryDetails.Primary_Sales_Rep__r.ManagerId!=Null){
                        if(TerritoryDetails.Primary_Sales_Rep__r.Manager.DelegatedApproverId == Null){
                            recipentUserEmail = getUser(TerritoryDetails.Primary_Sales_Rep__r.ManagerId);//[Select id, Name, Email from User Where Id=:TerritoryDetails.Primary_Sales_Rep__r.ManagerId];
                            EmailId = recipentUserEmail.Email;
                            approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?recipentUserEmail.Title:'';
                        }else{
                            //Delegation Approval Log
                            recipentUserEmail = getUser(TerritoryDetails.Primary_Sales_Rep__r.Manager.DelegatedApproverId);
                            EmailId = recipentUserEmail.Email;
                            approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?DelegatedUser+' '+recipentUserEmail.Title:'';
                        }
                    }else if(groupRecordTypeID == ContractRecord.RecordTypeId && accwrap.acc.Person_Responsible__c != Null && accwrap.acc.Person_Responsible__r.ManagerId != Null){
                        if(accwrap.acc.Person_Responsible__r.Manager.DelegatedApproverId == Null){
                            recipentUserEmail = getUser(accwrap.acc.Person_Responsible__r.ManagerId);//[Select id, Name, Email from User Where Id=:accwrap.acc.Person_Responsible__r.ManagerId];
                            EmailId = recipentUserEmail.Email;
                            approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?recipentUserEmail.Title:'';
                        }else{
                            //Delegation Approval Log
                            recipentUserEmail = getUser(accwrap.acc.Person_Responsible__r.Manager.DelegatedApproverId);
                            EmailId = recipentUserEmail.Email;
                            approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?DelegatedUser+' '+recipentUserEmail.Title:'';
                            
                        }
                    }
                    //End of ECM-4194
                    ContractRecord.status = EmailId!=''?'In Approval Process':'Draft';
                    approvLog.ECM_Status__c = ContractRecord.status=='In Approval Process'?'Requested':ContractRecord.status=='Approved'?'Approved':'Rejected';
                    approvLog.Name= EmailId!=''?EmailId:approvLog.Name;
                    approvLog.ECM_Type__c = 'Contract';
                    approvLog.ECM_Contract__c = ContractRecord.Id;
                    insert approvLog;
                    
                    if(EmailId !=''){  
                        //ECM-5585
                        sendPushNotificationForApprovalLog(approvLog.Id,recipentUserEmail.Id);
                        //send email to user email id
                        //ECM-6718
                        System.debug(LoggingLevel.DEBUG,'Condition @'+(System.Label.ECM_GAS_Market_CountryCodes.contains(ContractRecord.Account.Country_Code__c)));
                        //144840 Commented Decision statement because all market will use async Email.
                        //if(System.Label.ECM_GAS_Market_CountryCodes.contains(ContractRecord.Account.Country_Code__c)){
                        aSyncsendEmailToUser(recipentUserEmail.Id,ContractRecord.Id,approvLog.Id);
                        /*}else{
sendEmailToUser(recipentUserEmail, ContractRecord, approvLog); 
}*/
                        
                    }else{  
                        System.debug('Email Id '+EmailId);
                        errormessage += System.label.ECM_ApproverRecordMissing;
                    }
                }            
                
            }
            /*update ContractRecord;
system.debug(errormessage+'contract record'+ ContractRecord.Status );
wrap.customerCityStreetName = errormessage;
wrap.customerName = ContractRecord.Status;*/
            
            Integer months;
            if(String.isNotBlank(ContractRecord.ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c)){
                months = Integer.valueOf(ContractRecord.ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c); 
            }
            if(contractItems.size()>0)
            {
                for(ECM_Contract_Item__c conItemObj : contractItems){
                    if(months>0 && conItemObj.ECM_Volume__c>0 && ContractRecord.ECM_Duration__c>0)
                    {
                        conItemObj.ECM_Volume_Target_per_PF__c = ((conItemObj.ECM_Volume__c / ContractRecord.ECM_Duration__c)*months).setScale(2);
                    }else if(ContractRecord.ECM_Payment_Frequency_type__r.ECM_End_Date__c)
                    {
                        conItemObj.ECM_Volume_Target_per_PF__c = (conItemObj.ECM_Volume__c);
                    }
                }
            }
            upsert contractItems;
            update ContractRecord;
            system.debug(LoggingLevel.DEBUG,errormessage+'contract record'+ ContractRecord.Status );
            wrap.customerCityStreetName = errormessage;
            wrap.customerName = ContractRecord.Status;
            
            return wrap;
            
        } catch (Exception ex) {
            system.debug(LoggingLevel.DEBUG,'Exception='+ex.getMessage());
            // return errormessage;
            throw new AuraHandledException( System.label.ECM_SomeWentWorng + ex.getMessage());            
        }        
        
    }
    //Start of ECM-6718
    @future(callout = true)
    public static void aSyncsendEmailToUser(Id usrId, Id conRecId, Id apprvLogId){
        User rcpUsr = getUser(UsrId);
        Contract conRec = [SELECT id,accountId,Name,ContractNumber,Contract_End_Date__c,ECM_Duration__c,Status,EndDate,account.Country__r.code__c,Account.Country_Code__c,
                           StartDate,recordTypeId,ECM_Territory__c,ECM_Payment_Frequency_type__r.ECM_End_Date__c,ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c,
                           ECM_Agreement_Type__c,CreatedBy.Name,Account.Name,ECM_Overall_Investment_Amount__c,ECM_Overall_Investment_Figure__c,
                           Recordtype.Name,Recordtype.DeveloperName,ECM_Amended__c,ECM_Parent_Contract__c FROM contract WHERE Id=:conRecId WITH SECURITY_ENFORCED];
        ECM_Approval_Log__c approvLog = [SELECT Id,  Name, RecordTypeId, ECM_Approver_s_Position__c, ECM_Comment__c, ECM_Contract__c,
                                         ECM_No_of_Approval_Cycles__c, ECM_Status__c, ECM_Time_Date_Log__c, ECM_Approval_Rejection_Channel__c, 
                                         ECM_Sales_Driver__c, ECM_Addendum__c, ECM_Type__c FROM ECM_Approval_Log__c 
                                         WHERE ID=:apprvLogId WITH SECURITY_ENFORCED];
        sendEmailToUser(rcpUsr, conRec, approvLog);
    }
    //End of ECM-6718
    /*
* @description : Handles logic for sending contract approval mail & saves mail attachments in system
* @param : String - wrapper of Recipient user & Approval log
* @param : Id - contract Id
*/
    public static void sendEmailToUser(User rcpUsr, Contract conRec, ECM_Approval_Log__c apprvLog){
        system.debug(LoggingLevel.DEBUG,'recipent & approval log in sendEmailToUser '+rcpUsr+' '+apprvLog);
        system.debug(LoggingLevel.DEBUG,'Con in sendEmailToUser '+conRec);
        
        //151029
        String crgRecordTypeId = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByDeveloperName().get('CRG_Cold_Room_Grant').getRecordTypeId();
        
        //Start of ECM-6302 : Decide email parameters based upon approval for contract or (not amended)Addendum
        Id whatId = (apprvLog.ECM_Addendum__c != null)? apprvLog.ECM_Addendum__c : conRec.Id;
        //148916 - Added conditions for CRG
        String templateName = (apprvLog.ECM_Addendum__c != null)? 'Addendum Contract Approval Email' :
        conRec.Recordtype.DeveloperName =='CRG_Cold_Room_Grant'?'CRG Contract Approval Template':'Contract Approval Template';
        EmailTemplate emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                       FROM EmailTemplate
                                       WHERE name =:templateName WITH SECURITY_ENFORCED];
        
        //Prepare Email content
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{rcpUsr.Email};
            email.setTargetObjectId(rcpUsr.Id);
        email.setWhatId(whatId);
        email.setOrgWideEmailAddressId([SELECT Id,Address FROM OrgWideEmailAddress WHERE Address =: Label.ECM_ContractApproverOrgWideEmail].Id);
        email.setTemplateID(emailTemplate.Id);
        email.setSaveAsActivity(false);
        email.setReplyTo(Label.ECM_ContractApproverManagerEmailId);
        //email.setReplyTo('joshraj.sen@diageo.com');
        email.setToAddresses(toAddresses);
        List<Messaging.EmailFileAttachment> allAttachments = new List<Messaging.EmailFileAttachment>();
        
        //Prepare excel of contract details
        Messaging.EmailFileAttachment attchExcl = new Messaging.EmailFileAttachment();
        Messaging.SendEmailResult[] mailRslt;
        blob excel;
        If(!Test.isRunningTest() && conRec.recordTypeId != crgRecordTypeId){//151399
            excel = blob.valueOf(ECM_contractexcel.generateExcel(conRec.Id));
        }else{
            excel = blob.valueOf('Test Data');
        }
        attchExcl.setBody(excel);
        attchExcl.setFileName('Contract Details.xls');
        
        //Add contract details Excel
        if(apprvLog.ECM_Addendum__c == null && conRec.recordTypeId != crgRecordTypeId){//151399
            allAttachments.add(attchExcl);
        }
        
        //ECM-5090 : Add contract attached file with content type 'Approval Attachment mail'
        if(conRec.recordTypeId == crgRecordTypeId){//151377
            List<Messaging.EmailFileAttachment> approvalMailAttachmentList = ECM_ApprovalLogUtility.getApprovalMailAttachmentCRG(conRec.Id);
            if(!approvalMailAttachmentList.isEmpty()){
                allAttachments.addAll(approvalMailAttachmentList);
            }
        }else{
            Messaging.EmailFileAttachment approvalMailAttachment = ECM_ApprovalLogUtility.getApprovalMailAttachment(conRec.Id,null);
            if(approvalMailAttachment != null && apprvLog.ECM_Addendum__c == null){//151399 //removed '&& conRec.recordTypeId != crgRecordTypeId' //151377
                allAttachments.add(approvalMailAttachment);
            }
        }
        
        //ECM-4644 : Add contract PDF if 'Contract pdf to Approval Mails' is checked in MS
        Market_Setting__c marSetRec = new Market_Setting__c();
        marSetRec = [SELECT Id, Name, Geography__r.Code__c, ECM_Contract_pdf_to_Approval_Mails__c 
                     FROM Market_Setting__c
                     WHERE Geography__r.Code__c =: conRec.Account.Country_Code__c  WITH SECURITY_ENFORCED];
        
        //Add contract PDF when method is called for contract approval & checkbox is true in MS
        Messaging.EmailFileAttachment attPdf;
        Messaging.EmailFileAttachment attPdfAddnm;
        if(!conRec.ECM_Amended__c && marSetRec.ECM_Contract_pdf_to_Approval_Mails__c && apprvLog.ECM_Addendum__c == null && conRec.recordTypeId != crgRecordTypeId){//151399
            String status = 'Draft';
            Messaging.EmailFileAttachment attachPdf = ECM_ApprovalLogUtility.contractPdf(conRec, Status, null);
            attPdf = attachPdf;
            if(attachPdf !=null){
                allAttachments.add(attachPdf); 
            }
        }
        //Add Addendum PDF when method is called for Addendum Approval or for Amended Contract Approval
        if((apprvLog.ECM_Addendum__c != null || conRec.ECM_Amended__c) && conRec.recordTypeId != crgRecordTypeId){//151399
            Messaging.EmailFileAttachment attachAddnmPdf = ECM_ApprovalLogUtility.addendumPdf(conRec, null, apprvLog.ECM_Addendum__c);
            attPdfAddnm = attachAddnmPdf;
            if(attachAddnmPdf !=null){
                allAttachments.add(attachAddnmPdf);
            }
        }
        List<Messaging.EmailFileAttachment> parentAttch = new List<Messaging.EmailFileAttachment>();
        //Add contract files for addendum approval
        if(marSetRec.ECM_Contract_pdf_to_Approval_Mails__c && apprvLog.ECM_Addendum__c != null && conRec.recordTypeId != crgRecordTypeId){ //151399
            parentAttch = ECM_ApprovalLogUtility.fetchParentDocs(conRec.Id);
            if(!parentAttch.isEmpty()){
                allAttachments.addAll(parentAttch); 
            }
        }
        //ECM-6264 : Add Parent Contract files for amended contracts
        if(marSetRec.ECM_Contract_pdf_to_Approval_Mails__c && 
           conRec.ECM_Amended__c && conRec.ECM_Parent_Contract__c != null && apprvLog.ECM_Addendum__c == null &&
           conRec.recordTypeId != crgRecordTypeId){//151399
               parentAttch = ECM_ApprovalLogUtility.fetchParentDocs(conRec.ECM_Parent_Contract__c);
               if(!parentAttch.isEmpty()){
                   allAttachments.addAll(parentAttch); 
               }
           }
        //Add all attachments in email & send mail 
        if(!allAttachments.isEmpty()){
            email.setFileAttachments(allAttachments);
        }
        System.debug(LoggingLevel.DEBUG,'@email in sendEmailToUser '+email);      
        mailRslt = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});//151678
        if(conRec.recordTypeId != crgRecordTypeId){//151399
            //Save All email related attachments in Contract/Approval log : ECM-5553,ECM-5649,ECM-6074
            Set<Id> cVersionIds = new Set<Id>();
            List<ContentDocumentLink> cDocLinkList = new List<ContentDocumentLink>();
            List<ContentVersion> cVersionList = new List<ContentVersion>();
            
            //Delete Existing 'Contract Details' Excel from Contract (in case Contract is resubmitted so remove old Excel if exists)
            List<String> conIdLst = new List<String>();
            List<ContentDocumentLink> objConDocLink = [SELECT Id,ContentDocument.title,LinkedEntityId,ContentDocument.FileExtension 
                                                       FROM ContentDocumentLink
                                                       WHERE LinkedEntityId=:conRec.Id AND ContentDocument.title = 'Contract Details' WITH SECURITY_ENFORCED];
            System.debug(LoggingLevel.Debug,'@@@ objConDocLink : ' + objConDocLink);    
            if(objConDocLink.size()>0){
                for(ContentDocumentLink con : objConDocLink){
                    conIdLst.add(con.ContentDocumentId); 
                }
                if(conIdLst.size()>0){
                    System.debug(LoggingLevel.DEBUG,'@@TestContentDoc'+Limits.getQueries());
                    delete [SELECT Id,Title FROM ContentDocument WHERE Id IN: conIdLst];
                }
            }
            
            //Save Version data of 'Contract Details' Excel to be added in Contract
            Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
            ContentVersion cVersion = new ContentVersion();
            if(String.isNotEmpty(recordIdContentVersion)){
                cVersion.RecordTypeId = recordIdContentVersion;
            }
            cVersion.Content_Type__c = 'Investment Details';
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = 'Contract Details.xls';//File name with extention
            cVersion.Title = 'Contract Details';//Name of the file
            cVersion.VersionData = excel;//File content
            cVersionList.add(cVersion);
            
            System.debug('@@@ cVersionList : ' + cVersionList); 
            System.debug('@@@ attPdf : ' + attPdf); 
            //Save Version data of Contract PDF to be added in Approval Log
            if(attPdf != null){
                ContentVersion cVersionPdf = new ContentVersion();
                if(String.isNotEmpty(recordIdContentVersion)){
                    cVersionPdf.RecordTypeId = recordIdContentVersion;
                }
                cVersionPdf.Content_Type__c = 'Contracts';
                cVersionPdf.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cVersionPdf.PathOnClient = System.Label.ECM_Contract_Approval_Email_PDF_Name;//File name with extention
                cVersionPdf.Title = System.Label.ECM_Contract_Approval_Email_PDF_Name;//Name of the file
                cVersionPdf.VersionData = attPdf.body;//File content
                cVersionList.add(cVersionPdf);
            }
            System.debug('@@@ attPdfAddnm : ' + attPdfAddnm); 
            //Save Version data of Addendum PDF to be added in Approval Log
            if(attPdfAddnm != null){
                Id recordIdContentVersionAddnm = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Addendum').getRecordTypeId();
                ContentVersion cVersionPdfAddnm = new ContentVersion();
                if(String.isNotEmpty(recordIdContentVersionAddnm)){
                    cVersionPdfAddnm.RecordTypeId = recordIdContentVersionAddnm;
                }
                cVersionPdfAddnm.Content_Type__c = 'Contracts';
                cVersionPdfAddnm.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cVersionPdfAddnm.PathOnClient = System.Label.ECM_Addendum_Approval_File_Name;//File name with extention
                cVersionPdfAddnm.Title = System.Label.ECM_Addendum_Approval_File_Name;//Name of the file
                cVersionPdfAddnm.VersionData = attPdfAddnm.body;//File content
                cVersionList.add(cVersionPdfAddnm);
            }
            System.debug('@@@ cVersionList : ' + cVersionList); 
            //Save the Content Verison, get the ContentDocumentId to insert files
            try{
                System.debug(LoggingLevel.DEBUG,'@@TestContentVersionbeforeInsert'+Limits.getQueries());
                insert cVersionList;
                System.debug(LoggingLevel.DEBUG,'@@TestContentVersionAfterInsert'+Limits.getQueries());
                for(ContentVersion cVrsn : cVersionList){
                    cVersionIds.add(cVrsn.Id);
                }
                for(ContentVersion contentDoc : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN:cVersionIds WITH SECURITY_ENFORCED]){
                    ContentDocumentLink cDocLink = new ContentDocumentLink();
                    cDocLink.ContentDocumentId = contentDoc.ContentDocumentId;//Add ContentDocumentId
                    cDocLink.LinkedEntityId = (contentDoc.Id == cVersion.Id)? conRec.Id : apprvLog.Id;//Add attachment parentId
                    cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                    cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                    cDocLinkList.add(cDocLink);
                }
                System.debug(LoggingLevel.DEBUG,'@@TestContentDocbeforeInsert'+Limits.getQueries());
                insert cDocLinkList;
                System.debug(LoggingLevel.DEBUG,'@@TestContentDocAfterInsert'+Limits.getQueries());
            }
            catch(Exception ex){
                System.debug(LoggingLevel.DEBUG,'@@@method:sendEmailToUser\nException in attachmentSave ' + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            }
            System.debug('@@@cDocLinkList : ' + cDocLinkList);
        }
    }
    
    /*
* @description : fetches user details
* @return : User
* @param : user Id
*/
    @AuraEnabled
    public static User getUser(String userId){        
        return [SELECT Id, Name,Profile.Name, FirstName, Email, Title FROM User WHERE Id =: userId WITH SECURITY_ENFORCED];
    }
    
    /*
* @description : fetches Territory details
* @return : Territory__c
* @param : Territory Id
*/
    @AuraEnabled
    public static Territory__c getTerritory(String territoryId){        
        return [SELECT Id, Name, Primary_Sales_Rep__c, Primary_Sales_Rep__r.Name, Primary_Sales_Rep__r.ManagerId, Primary_Sales_Rep__r.Manager.Email,
                Primary_Sales_Rep__r.DelegatedApproverId,Primary_Sales_Rep__r.Manager.DelegatedApproverId,
                Activation_Specialist__c, Activation_Specialist__r.name, Activation_Specialist__r.ManagerId, Activation_Specialist__r.Manager.Email, 
                Activation_Specialist__r.DelegatedApproverId, Activation_Specialist__r.Manager.DelegatedApproverId FROM Territory__c WHERE Id =: territoryId WITH SECURITY_ENFORCED];//Added Activation Specialist manager in query - 146040
    }
    
    /*
* @description : this method contains & validates logic for contract creation and generates related records 
on next from screen-1
* @return : Contract
* @param : Contract contract record
* @param : Id contract recordType Id
* @param : Id Territory Id
* @param : Id agreement type Id
* @param : List of Account
*/
    @AuraEnabled
    public static Contract createContract(Contract con,String accId, String recordTypeId,String territoryId,String contractTypeId,List<Account> customerList ){
        con.AccountId=accId;
        con.status='Draft';
        con.recordTypeId = recordTypeId;
        con.ECM_Territory__c=territoryId;
        
        //ECM_Contract_Type__c aggrementrecord = new ECM_Contract_Type__c();
        
        Account acc=[select Country__c,Country__r.Name,ECM_Legal_Name__c from Account where id=:accId];
        //ECM-4468 - Deployment_Territory name population for Group contracts_SFDC_Tech debt
        Id grouprecordTypeId =Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();    
        if(con.RecordTypeId==GrouprecordTypeId){
            //Update Territory for Spain - ECM-3042
            List<Territory_Member__c> tM;
            TM=[SELECT End_Date__c,Id,Start_Date__c,Territory__c,Type__c,User__c 
                FROM Territory_Member__c 
                WHERE Type__c = 'Primary' 
                AND User__c=:UserInfo.getUserId()
                AND ((End_Date__c>=Today  OR End_Date__c = Null)
                     AND Start_Date__c<=Today) WITH SECURITY_ENFORCED];
            if(!TM.isEmpty()){
                con.ECM_Territory__c=TM[0].Territory__c;
            }
        }   
        con.ECM_Agreement_Type__c=contractTypeId;
        //con.ECM_Contract_Type__c=contractTypeId; /*ECM-2253*/
        //con.ECM_Banner__c=selectedLookUpRecord.id;
        
        Date startDate = con.StartDate;
        Date endDate = con.Contract_End_Date__c;
        Integer startDateMonth = startDate.month();
        Integer endDateMonth = endDate.month();
        Integer startDateYear = startDate.year();
        Integer endDateYear = endDate.year();
        String fiscalYear = '';
        system.debug(LoggingLevel.DEBUG,'startDateMonthsss'+startDateMonth+endDateMonth);
        for(integer i=startDateYear; i<= endDateYear; i++){
            integer dateYear = i;
            //string s1=string.valueof(dateYear).right(2);
            if(i==startDateYear){
                if(startDateMonth<7){
                    fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                }
            }
            if(i==endDateYear){
                if(startDateYear == endDateYear){
                    if(startDateMonth<7 && endDateMonth >= 7){
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth >= 7 && endDateMonth >= 7){
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
                else if(startDateYear+1 == endDateYear){
                    if(startDateMonth < 7 && endDateMonth < 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth >= 7 && endDateMonth < 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth >= 7 && endDateMonth >= 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth < 7 && endDateMonth >= 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
                else{
                    if(endDateMonth >= 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    else{
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
            }
            if(i != startDateYear && i != endDateYear){
                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
            }
        }
        // system.debug('contract id'+con.Id);
        con.ECM_Fiscal_Years__c = fiscalYear.removeEndIgnoreCase('/');
        // system.debug('contract id'+con);
        upsert con;
        
        system.debug(LoggingLevel.DEBUG,'contract record-->'+con);
        system.debug(LoggingLevel.DEBUG,'@@@CustomerList-->'+customerList);
        
        if(customerList.size()>0){
            List<Account> acclist = new List<Account>();
            acclist = [Select Id,Name from Account where Id IN: customerList WITH SECURITY_ENFORCED];
            
            //Boolean noOutletContract = true;
            set<String> newAccLst = new set<String>();
            Contract contObj = new Contract();
            contObj = [ Select Id, AccountId, Status, RecordTypeId, RecordType.Name FROM Contract WHERE ID =: con.Id AND Status='Draft' WITH SECURITY_ENFORCED Limit 1];
            system.debug(LoggingLevel.DEBUG,'contObj-->'+contObj);
            if(contObj != null){
                List<Outlet_Contract__c> outConObj = new List<Outlet_Contract__c>();
                List<Outlet_Contract__c> outConDelLst = new List<Outlet_Contract__c>();
                List<Outlet_Contract__c> outConInsertLst = new List<Outlet_Contract__c>();
                outConObj = [SELECT Id,Name,Activation_Date__c,Contract__c,Deactivation_Date__c,Outlet__c,Status__c FROM Outlet_Contract__c WHERE Contract__c =: contObj.Id ];
                system.debug(LoggingLevel.DEBUG,'outConObj-->'+outConObj);
                
                if(outConObj.isEmpty()){
                    for(Account outConInLst : acclist){
                        
                        Outlet_Contract__c outCont = new Outlet_Contract__c();
                        outCont.Status__c = 'Active';
                        outCont.Contract__c = contObj.Id;
                        outCont.Outlet__c = outConInLst.Id;
                        outConInsertLst.add(outCont);
                        
                    }
                    insert outConInsertLst;
                    system.debug(LoggingLevel.DEBUG,'no deletion only insert-->'+outConInsertLst);
                }else if(outConObj.size()>0){
                    Map<String,String> outContMap = new Map<String,String>();//outletContract Map
                    for(Outlet_Contract__c outContIds : outConObj)
                    {
                        outContMap.put(outContIds.Outlet__c,outContIds.Id);
                    }                    
                    Map<String,String> accMap = new Map<String,String>();//Account Map
                    for(Account accIds : acclist)
                    {
                        accMap.put(accIds.Id,accIds.Name);
                        // Logic for scenario where A&B customerlist is received and OutletContract aleady has a record with outlet A and only insert outlet with B
                        if(!outContMap.containsKey(accIds.Id))
                        {
                            newAccLst.add(accIds.Id);
                        }
                    }
                    for(Outlet_Contract__c outContLst : outConObj)
                    {
                        if(!accMap.containsKey(outContLst.Outlet__c))
                        {
                            outConDelLst.add(outContLst);
                        }
                        system.debug(LoggingLevel.DEBUG,'outConDelLst-->'+outConDelLst);
                    }
                }
                
                if(outConDelLst.size()>0){    
                    Delete outConDelLst;//Delete OutletContract Records
                }
                if(newAccLst.size()>0){   
                    system.debug(LoggingLevel.DEBUG,'newAccLst-->'+newAccLst);
                    for(String accIds : newAccLst){					
                        Outlet_Contract__c outCont = new Outlet_Contract__c();
                        outCont.Status__c = 'Active';
                        outCont.Contract__c = contObj.Id;
                        outCont.Outlet__c = accIds;
                        outConInsertLst.add(outCont);						
                    }
                    insert outConInsertLst;
                    system.debug(LoggingLevel.DEBUG,'outConInsertLst-->'+outConInsertLst);
                }
            }
        }else{
            Contract contObj = new Contract();
            contObj = [ Select Id, AccountId, Status, RecordTypeId, RecordType.Name FROM Contract WHERE ID =: con.Id AND Status='Draft' WITH SECURITY_ENFORCED Limit 1];
            List<Outlet_Contract__c> outConDelLst = new List<Outlet_Contract__c>();
            outConDelLst = [SELECT Id,Name,Activation_Date__c,Contract__c,Deactivation_Date__c,Outlet__c,Status__c FROM Outlet_Contract__c WHERE Contract__c =: contObj.Id ];
            system.debug(LoggingLevel.DEBUG,'main else outConDelLst-->'+outConDelLst);
            if(outConDelLst.size()>0){ 
                system.debug(LoggingLevel.DEBUG,'delete scenario when no account is selected'+outConDelLst);
                Delete outConDelLst;
            }
        }
        /* ECM-3968 & ECM-4153 */
        List<Outlet_Contract__c> outConLst = new List<Outlet_Contract__c>();
        List<String> outSelectedLst = new List<String>();
        List<String> outletSelectedLegalLst = new List<String>();
        List<String> territoryLst = new List<String>();
        List<String> territoryRegLst = new List<String>();
        outConLst = [SELECT Id,Name,Contract__c,Outlet__r.Name,Outlet__c,Outlet__r.ECM_Legal_Name__c,Outlet__r.Primary_Sales_Territory__r.Name,Outlet__r.Primary_Sales_Territory_Region__r.Name 
                     FROM Outlet_Contract__c 
                     WHERE Contract__c =: con.Id and Outlet__c!=null and (Contract__r.recordtype.name='Group' OR Contract__r.recordtype.name='Outlet') WITH SECURITY_ENFORCED];
        if(outConLst.size()>0){
            for(Outlet_Contract__c outConObj : outConLst){
                outSelectedLst.add(outConObj.Outlet__r.Name);
                if(outConObj.Outlet__r.ECM_Legal_Name__c != NULL){
                    outletSelectedLegalLst.add(outConObj.Outlet__r.ECM_Legal_Name__c);
                }
                if(outConObj.Outlet__r.Primary_Sales_Territory__c!=null){
                    TerritoryLst.add(outConObj.Outlet__r.Primary_Sales_Territory__r.Name);
                }
                if(outConObj.Outlet__r.Primary_Sales_Territory_Region__c!=null){
                    TerritoryRegLst.add(outConObj.Outlet__r.Primary_Sales_Territory_Region__r.Name);
                }
            }
            //making a single string with comma seprated from above list
            String outlets = String.join(outSelectedLst, ', ');
            String outletLegalNm = String.join(outletSelectedLegalLst, ', ');//ECM-5316
            String territory = String.join(TerritoryLst, ', ');
            String territoryReg = String.join(TerritoryRegLst, ', ');
            
            con.Territory__c=Territory;
            con.ECM_Territory_Hierarchy__c=TerritoryReg;
            con.ECM_Outlets_selected__c = Outlets;
            if(con.RecordTypeId==GrouprecordTypeId){
                con.ECM_Outlets_selected_Legal_Name__c = outletLegalNm;
            }
            else{
                con.ECM_Outlets_selected_Legal_Name__c = acc.ECM_Legal_Name__c;
            }
            
            update con;
        }
        return con; 
    }
    
    /*
* @description : Method to get all the events for the contract
* @param : List of ECM_Event__c
* Ticket : ECM-5622
*/
    @AuraEnabled
    public static List<ECM_Event__c> getEvents(String conId){
        return [SELECT Id, ECM_Event_Name__c, ECM_Event_Date__c FROM ECM_Event__c WHERE ECM_Contract__c =: conId WITH SECURITY_ENFORCED];
    }
    
    /*
* @description : Menthod to create events entered on the 1st screen
* @param : List of ECM_Event__c
* Ticket : ECM-5622
*/
    @AuraEnabled
    public static void createEvents(String eventList){
        if(String.isNotBlank(eventList)){
            List<ECM_Event__c> evntData = (List<ECM_Event__c>)JSON.deserialize(eventList, List<ECM_Event__c>.class);
            System.debug(LoggingLevel.DEBUG,'Create Event List : '+evntData);
            if(evntData.size() > 0 && Schema.sObjectType.ECM_Event__c.isCreateable()
               && Schema.sObjectType.ECM_Event__c.isUpdateable()){
                   Database.upsert(evntData ,ECM_Event__c.ECM_Event_Unique_Id__c);
               }
        }
        
    }
    
    /*
* @description : Menthod to delete events deleted on the 1st screen using bin icon.
* @param : List of ECM_Event__c
* Ticket : ECM-5622
*/
    @AuraEnabled
    public static void deleteEvents(String deleteEventList){
        set<String> setExternalId = new set<String>();
        List<ECM_Event__c> delList = new List<ECM_Event__c>();
        if(String.isNotBlank(deleteEventList)){
            System.debug(LoggingLevel.DEBUG,'Initial Delete Event List : '+deleteEventList);
            List<ECM_Event__c> parsedEventData = (List<ECM_Event__c>)JSON.deserialize(deleteEventList, List<ECM_Event__c>.class);
            for(ECM_Event__c eve : parsedEventData){
                setExternalId.add(eve.ECM_Event_Unique_Id__c);
            }
            if(setExternalId != null){
                delList = [Select id, ECM_Event_Unique_Id__c from ECM_Event__c where ECM_Event_Unique_Id__c in : setExternalId];
            }
            if(delList.size() > 0){
                Database.delete(delList, false);
            }
        }
    }
    
    /*
* @description : removes contract items on unchecking previously saved product in screen 2
* @param : List of ECM_Contract_Item__c
*/
    @AuraEnabled
    public static void deleteOldContractItems(List<ECM_Contract_Item__c> contractItemList){
        delete contractItemList;
    }
    
    /*
* @description : Method to change the status of the Addendum from Draft to Cancelled
* @param : Contract
* Story : ECM-5802
*/
    @AuraEnabled
    public static void cancelAddendum(String addendumId){
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        List<ECM_Sales_Driver_Item_Detail__c> sdidList = new List<ECM_Sales_Driver_Item_Detail__c>();
        
        if(addendumId!=null){
            ECM_Addendum__c addendum = new ECM_Addendum__c(Id=addendumId,ECM_Status__c = 'Cancelled');
            update addendum;
        }
        
        for(ECM_Contract_Item__c conItem:[SELECT Id,ECM_Addendum__c FROM ECM_Contract_Item__c 
                                          WHERE ECM_Addendum__c=:addendumId WITH SECURITY_ENFORCED]){
                                              conItemList.add(conItem);  
                                          }
        //ECM-5865
        for(ECM_Sales_Driver_Item_Detail__c sdid:[SELECT Id,ECM_Addendum__c FROM ECM_Sales_Driver_Item_Detail__c
                                                  WHERE ECM_Addendum__c=:addendumId WITH SECURITY_ENFORCED]){
                                                      sdidList.add(sdid);
                                                  }
        if(!conItemList.isEmpty() && Schema.sObjectType.ECM_Contract_Item__c.isDeletable()){
            Delete conItemList;
        }
        //ECM-5865
        if(!sdidList.isEmpty() && Schema.sObjectType.ECM_Sales_Driver_Item_Detail__c.isDeletable()){
            Delete sdidList;
        }
    }
    
    /*
* @description : Method to change the status of the Addendum to Draft or In approval
* @param : Contract and a boolean value 
* Story : ECM-5890
*/
    @AuraEnabled
    public static void changeAddendumStatus(String addendumId, Boolean isSubmit){
        
        if(addendumId!=null){
            ECM_Addendum__c addendum = new ECM_Addendum__c();
            addendum = [SELECT Id,ECM_Contract__c,ECM_Status__c FROM ECM_Addendum__c WHERE Id=:addendumId];
            addendum.ECM_Status__c = isSubmit?'In approval':'Draft';
            
            //ECM-5867
            ECM_Approval_Log__c approvLog = new ECM_Approval_Log__c();
            //154315 - added ECM_Parent_Contract__c
            Contract contractRecord=[SELECT Id,accountId,Name,ContractNumber,Contract_End_Date__c,ECM_Duration__c,Status,EndDate,account.Country__r.code__c,Account.Country_Code__c,
                                     StartDate,recordTypeId,ECM_Territory__c,ECM_Amended__c,ECM_Payment_Frequency_type__r.ECM_End_Date__c,ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c,
                                     ECM_Agreement_Type__c,CreatedBy.Name,Account.Name,ECM_Overall_Investment_Amount__c,ECM_Overall_Investment_Figure__c,ECM_Parent_Contract__c,
                                     Recordtype.Name FROM Contract WHERE Id=:addendum.ECM_Contract__c WITH SECURITY_ENFORCED];
            
            User recipentUserEmail = new User();
            string emailId = '';
            if(isSubmit){
                Decimal newContractItemsInvestment = 0;//Retro Investment + A&P Investment + Trade Investment lump sum
                //ECM-6069
                Decimal newAnPInvestment =0;
                Decimal newTiInvestment =0;
                Id sdidSDRecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
                ECM_Contract_Type__c ecmContractType = [SELECT Id,ECM_Aggrement_Duration__c,Geography__r.Code__c,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Automatic_approval_amount_threshold__c ,
                                                        ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Contract_Approval_mail_to_Customer__c,
                                                        ECM_Mandatory_Fields_Check__c FROM ECM_Contract_Type__c where Id=: contractRecord.ECM_Agreement_Type__c WITH SECURITY_ENFORCED];
                for(ECM_Contract_Item__c conItem:[SELECT ECM_Retro_investment__c,ECM_AnP_investment__c,ECM_Trade_investments__c
                                                  FROM ECM_Contract_Item__c WHERE ECM_Contract__c=:contractRecord.Id AND ECM_Addendum__c=:addendum.Id]){
                                                      newContractItemsInvestment+=  conItem.ECM_Retro_investment__c!=Null?conItem.ECM_Retro_investment__c:0;
                                                  }
                //ECM-6069
                for(ECM_Sales_Driver_Item_Detail__c sdItemRec : 
                    [SELECT Id,ECM_Budget_Type__c,ECM_Investment_Amount__c,ECM_Product__c,
                     ECM_Sales_Driver_Item__r.Contract__c,RecordTypeId,ECM_Addendum__c
                     FROM ECM_Sales_Driver_Item_Detail__c
                     WHERE ECM_Sales_Driver_Item__r.Contract__c =: contractRecord.Id 
                     AND ECM_Budget_Type__c!=NULL AND ECM_Product__c!=NULL
                     AND RecordTypeId =:sdidSDRecId AND ECM_Addendum__c=:addendumId]){
                         Decimal sdItemInv = (sdItemRec.ECM_Investment_Amount__c != Null)? sdItemRec.ECM_Investment_Amount__c : 0;
                         if(sdItemRec.ECM_Budget_Type__c.contains('A&P')){
                             newAnPInvestment += sdItemInv;
                         }                  
                         else if(sdItemRec.ECM_Budget_Type__c.contains('TI')){
                             newTiInvestment += sdItemInv;                          
                         }
                     }
                newContractItemsInvestment += (newAnPInvestment + newTiInvestment);
                //End of ECM-6069
                //ECM-6032 commenting this line as part of story
                //newContractItemsInvestment += contractRecord.ECM_Overall_Investment_incl_Indirect_Inv__c!=Null?contractRecord.ECM_Overall_Investment_incl_Indirect_Inv__c:0;
                if(newContractItemsInvestment.setScale(2) < ecmContractType.ECM_Automatic_approval_amount_threshold__c ){
                    addendum.ECM_Status__c = 'Approved';
                }
                else if(newContractItemsInvestment.setScale(2) == ecmContractType.ECM_Automatic_approval_amount_threshold__c ||
                        newContractItemsInvestment.setScale(2) > ecmContractType.ECM_Automatic_approval_amount_threshold__c ){
                            
                            String outletRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
                            String groupRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
                            accountWrapper accwrap = getAccountById(ContractRecord.AccountId);
                            AggregateResult cycleCount = [SELECT MAX(ECM_No_of_Approval_Cycles__c) FROM ECM_Approval_Log__c 
                                                          WHERE ECM_Contract__c=:ContractRecord.Id  WITH SECURITY_ENFORCED];
                            integer approvalcount = integer.valueOf(cycleCount.get('expr0')==Null?0:cycleCount.get('expr0'));
                            Territory__c territoryDetails = new Territory__c();
                            if(contractRecord.ECM_Territory__c != Null){
                                territoryDetails = getTerritory(ContractRecord.ECM_Territory__c);            
                            }
                            string delegatedUser = System.Label.ECM_Delegated_Approver;
                            
                            
                            String approverPosition = '';
                            Id userId;
                            //146038 -> start
                            if(outletRecordTypeID == ContractRecord.RecordTypeId && TerritoryDetails!=Null && TerritoryDetails.Activation_Specialist__r.ManagerId!=Null){
                                userId = territoryDetails.Activation_Specialist__r.Manager.DelegatedApproverId == Null?TerritoryDetails.Activation_Specialist__r.ManagerId:territoryDetails.Activation_Specialist__r.Manager.DelegatedApproverId;
                                recipentUserEmail = getUser(userId);
                                approverPosition = territoryDetails.Activation_Specialist__r.Manager.DelegatedApproverId == Null?
                                    (recipentUserEmail!=Null?recipentUserEmail.Title:''):
                                (recipentUserEmail!=Null?delegatedUser+' '+recipentUserEmail.Title:'');
                                    
                                    }//146038 -> end  
                            else if(outletRecordTypeID == contractRecord.RecordTypeId && territoryDetails!=Null && territoryDetails.Primary_Sales_Rep__r.ManagerId!=Null){
                                
                                userId = territoryDetails.Primary_Sales_Rep__r.Manager.DelegatedApproverId == Null?TerritoryDetails.Primary_Sales_Rep__r.ManagerId:territoryDetails.Primary_Sales_Rep__r.Manager.DelegatedApproverId;
                                recipentUserEmail = getUser(userId);
                                approverPosition = territoryDetails.Primary_Sales_Rep__r.Manager.DelegatedApproverId == Null?
                                    (recipentUserEmail!=Null?recipentUserEmail.Title:''):
                                (recipentUserEmail!=Null?delegatedUser+' '+recipentUserEmail.Title:'');
                                    
                                    }
                            else if(groupRecordTypeID == contractRecord.RecordTypeId && accwrap.acc.Person_Responsible__c != Null && accwrap.acc.Person_Responsible__r.ManagerId != Null){
                                
                                userId = accwrap.acc.Person_Responsible__r.Manager.DelegatedApproverId == Null?accwrap.acc.Person_Responsible__r.ManagerId:accwrap.acc.Person_Responsible__r.Manager.DelegatedApproverId;
                                recipentUserEmail = getUser(userId);
                                approverPosition = accwrap.acc.Person_Responsible__r.Manager.DelegatedApproverId == Null?
                                    (recipentUserEmail!=Null?recipentUserEmail.Title:''):
                                (recipentUserEmail!=Null?delegatedUser+' '+recipentUserEmail.Title:'');
                                    
                                    }
                            emailId = recipentUserEmail.Email;
                            
                            //create Approval Log                    
                            approvLog.ECM_Time_Date_Log__c	 = system.now();
                            approvLog.ECM_No_of_Approval_Cycles__c = approvalcount+1;
                            approvLog.RecordTypeId =Schema.getGlobalDescribe().get('ECM_Approval_Log__c').getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
                            approvLog.ECM_Approver_s_Position__c = approverPosition;
                            
                            approvLog.ECM_Status__c = 'Requested';
                            approvLog.Name= EmailId!=''?EmailId:ContractRecord.ContractNumber;
                            approvLog.ECM_Type__c = 'Contract';
                            approvLog.ECM_Contract__c = ContractRecord.Id;
                            approvLog.ECM_Addendum__c = addendum.Id;
                            insert approvLog;
                            
                        }
            }
            update addendum;
            System.debug(LoggingLevel.DEBUG,'@@@addendum'+addendum);
            if(EmailId !=''){
                //154315 - made it aSync
                aSyncsendEmailToUser(recipentUserEmail.Id, contractRecord.Id, approvLog.Id); 
            }else{
                System.debug(LoggingLevel.DEBUG,'approver record is missing');
            }
            //End of ECM-5867
        }
        
    }  
    
    /*
* @description : this method fetches list of agreement type available for user business role
* @return : List of ECM_Contract_Type__c
*/
    @AuraEnabled
    public static list<ECM_Contract_Type__c> getContractTypes(){
        User_Business_Role__c usb=[SELECT Id,name,user__r.name,Business_Role__c,Business_Role__r.name from User_Business_Role__c where user__c =: userinfo.getUserId() WITH SECURITY_ENFORCED];
        List<ECM_Role_Agreement__c> eraList = [SELECT Id,name,Agreement_Type__r.name,Agreement_Type__c,Business_Role__c from ECM_Role_Agreement__c where Business_Role__c =: usb.Business_Role__c WITH SECURITY_ENFORCED];
        List<ECM_Contract_Type__c> ecmContractType = new list<ECM_Contract_Type__c>();
        if(eraList.size()>0){
            set<Id> agreementTypeIds = new set<Id>();
            for(ECM_Role_Agreement__c era : eraList){
                agreementTypeIds.add(era.Agreement_Type__c);
            }
            if(agreementTypeIds.size()>0){
                //ECM-1475
                //148913 - Added "Cold Room Grant" in Query
                ecmContractType = [SELECT id,CRG_Cold_Room_Grant__c,Geography__r.Code__c,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Aggrement_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Number_of_Retro_Months__c,ECM_Activation_Spend__c FROM ECM_Contract_Type__c where ECM_Visible__c = true AND CRG_Cold_Room_Grant__c = false AND ECM_Local_Segment1__c=null AND Id IN: agreementTypeIds WITH SECURITY_ENFORCED Order By Name]; //To sort the agreement types alphabetically for group contract 
            }
        }
        return ecmContractType; 
        
    }
    
    /*
* @description : this method fetches list of agreement type based upon the local segment of account - ECM-1475
* @return : List of ECM_Contract_Type__c
* @param : account Id
*/
    @AuraEnabled
    public static list<ECM_Contract_Type__c> getContractTypesOutlet(String accountId){
        System.debug(LoggingLevel.DEBUG,'AgreementType '+accountId);
        List<ECM_Contract_Type__c> ecmContractType = new list<ECM_Contract_Type__c>();
        if(!(String.isBlank(accountId))){
            Account accObj = new Account();
            accObj = [SELECT Id,Independent_of_Operator__c,Name,Operator__c,Local_Segment1__c FROM Account where Id =: accountId WITH SECURITY_ENFORCED];
            User_Business_Role__c usb=[SELECT Id,name,user__r.name,Business_Role__c,Business_Role__r.name from User_Business_Role__c where user__c =: userinfo.getUserId() WITH SECURITY_ENFORCED];
            List<ECM_Role_Agreement__c> eraList = [SELECT Id,name,Agreement_Type__r.name,Agreement_Type__c,Business_Role__c from ECM_Role_Agreement__c where Business_Role__c =: usb.Business_Role__c WITH SECURITY_ENFORCED];
            if(eraList.size()>0){
                set<Id> agreementTypeIds = new set<Id>();
                for(ECM_Role_Agreement__c era : eraList){
                    agreementTypeIds.add(era.Agreement_Type__c);
                }
                //148913 - Added "Cold Room Grant" in Query
                if(agreementTypeIds.size()>0 && accObj!= null){
                    if(!(String.isBlank(accObj.Operator__c))){ 
                        ecmContractType = [SELECT id,CRG_Cold_Room_Grant__c,ECM_E_S_Event_Date_Gap__c,Geography__r.Code__c,ECM_Aggrement_Duration__c,ECM_Local_Segment1__c,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Number_of_Retro_Months__c,ECM_Activation_Spend__c FROM ECM_Contract_Type__c where ECM_Visible__c = true AND ECM_Allow_Independent__c = true AND CRG_Cold_Room_Grant__c = false AND( ECM_Local_Segment1__c=null OR ECM_Local_Segment1__c=:accObj.Local_Segment1__c) AND Id IN: agreementTypeIds WITH SECURITY_ENFORCED];
                    }
                    else if(accObj.Independent_of_Operator__c){
                        ecmContractType = [SELECT id,CRG_Cold_Room_Grant__c,ECM_E_S_Event_Date_Gap__c,Geography__r.Code__c,Name,ECM_Aggrement_Duration__c,ECM_Local_Segment1__c,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Number_of_Retro_Months__c,ECM_Activation_Spend__c FROM ECM_Contract_Type__c where ECM_Visible__c = true AND CRG_Cold_Room_Grant__c = false AND( ECM_Local_Segment1__c=null OR ECM_Local_Segment1__c=:accObj.Local_Segment1__c) AND Id IN: agreementTypeIds WITH SECURITY_ENFORCED];
                    }
                }
            }
            
        }
        system.debug(LoggingLevel.DEBUG,ecmContractType);
        ecmContractType.sort(); // 156040 - Sorting the List of Agreement Types
        return ecmContractType;
        
    }
    @AuraEnabled 
    public static Map<String, String> getPickUpOptionsPicklistvalues(){
        Map<String, String> options = new Map<String, String>();
        for (Pick_Up_Options__c p: [SELECT Id, Name, Geography__r.Name, Status__c, Type__c FROM Pick_Up_Options__c 
                                    where Status__c='Active' AND Geography__r.Name='Australia' AND Type__c ='Local-Segment1' WITH SECURITY_ENFORCED]) {
                                        //Put Picklist Value & Label in Map
                                        options.put(p.Id, p.Name);
                                    }
        return options;
    } 
    @AuraEnabled
    public static list<sObject> getListOfAccounts(){
        String loggedInUser = UserInfo.getUserId();
        System.debug(LoggingLevel.INFO,loggedInUser);
        String objectName = 'Account';
        List < sObject > returnList = new List < sObject > ();
        
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5  --only works for group account 
        String groupRecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        System.debug(LoggingLevel.INFO,groupRecordTypeID);
        //ECM-5363 - Added ECM_Legal_Name__c, for scenario when only one operator is assigned to user
        String sQuery =  'select id, Name,Independent_of_Operator__c,ECM_Legal_Name__c from ' +ObjectName + ' where Person_Responsible__c=:loggedInUser AND recordTypeId=:groupRecordTypeID order by createdDate DESC ';
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    @AuraEnabled
    public static list<Discountrecord> setdefaultvalues_Discount(contract cont){
        /* contract cObjMap = (contract) JSON.deserializeUntyped(cont);*/
        /*List<string> fieldsforsoql=new list<string>{
'ECM_Draught_Discounts__c','ECM_Pouring_Discounts__c',
'ECM_Premium_Discounts__c','ECM_Reserve_Discounts__c',
'ECM_RTD_Discount__c','ECM_Spirits_Discounts__c'};*/
        Map<string,string> fieldsformappingrecords= new  Map<string,string>{'Draught Discounts' => 'ECM_Draught_Discounts__c',
            'Non Alcoholic Discounts' => 'ECM_Non_Alcoholic_Discounts__c',
            'Pouring Discounts' => 'ECM_Pouring_Discounts__c',
            'Premium Discounts' => 'ECM_Premium_Discounts__c',
            'Reserve Discounts' => 'ECM_Reserve_Discounts__c',
            'RTD Discount' => 'ECM_RTD_Discount__c',
            'Spirits Discounts' => 'ECM_Spirits_Discounts__c'};
                //Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('ECM_Set_Default_values_for_AU_Channel__mdt').getDescribe().fields.getMap();
                list< Discountrecord> disrec=new list<Discountrecord>();
        Map<String,ECM_Set_Default_values_for_AU_Channel__mdt> map_string_defaultvalue = new Map<string,ECM_Set_Default_values_for_AU_Channel__mdt>();
        
        for(ECM_Set_Default_values_for_AU_Channel__mdt defaultvalue:[SELECT MasterLabel, 
                                                                     ECM_Draught_Discounts__c,ECM_Pouring_Discounts__c,
                                                                     ECM_Premium_Discounts__c,ECM_Reserve_Discounts__c,
                                                                     ECM_RTD_Discount__c,ECM_Spirits_Discounts__c,ECM_Non_Alcoholic_Discounts__c
                                                                     from ECM_Set_Default_values_for_AU_Channel__mdt]){
                                                                         map_string_defaultvalue.put(defaultvalue.MasterLabel,defaultvalue);
                                                                         
                                                                     }
        disrec=returndefalutvalues(cont,fieldsformappingrecords,Null,map_string_defaultvalue);
        return disrec;
    }
    @AuraEnabled
    public static list<Discountrecord> returndefalutvalues(contract cont, Map<string,string> fieldsformappingrecords,Map<String,contract> map_string_defaultvalue_con , Map<String,ECM_Set_Default_values_for_AU_Channel__mdt> map_string_defaultvalue_mdt ){
        list< Discountrecord> disrec=new list<Discountrecord>();
        Map<String,Pick_Up_Options__c> map_Pick_Up_Options_name_record = new Map<string,Pick_Up_Options__c>();
        id discountrecordtypeid=Schema.Sobjecttype.Pick_Up_Options__c.getRecordTypeInfosByName().get('Discount Level').getRecordTypeId();
        
        for(Pick_Up_Options__c pickupoptions :[SELECT Name, Id from Pick_Up_Options__c where Recordtypeid =: Discountrecordtypeid WITH SECURITY_ENFORCED] ){
            if(map_string_defaultvalue_con !=Null){
                map_Pick_Up_Options_name_record.put(pickupoptions.id,pickupoptions);
            }
            else{
                map_Pick_Up_Options_name_record.put(pickupoptions.name,pickupoptions);
            }
        }
        for(String ft : fieldsformappingrecords.keyset()){
            Discountrecord disrec1=new Discountrecord();
            disrec1.nameofdiscount=ft;
            string channel=cont.ECM_Channel__c;
            string fld;
            if(map_string_defaultvalue_con !=Null){
                fld =string.valueof(map_string_defaultvalue_con.get(channel).get(fieldsformappingrecords.get(ft)));
                
            }else{
                fld =string.valueof(map_string_defaultvalue_mdt.get(channel).get(fieldsformappingrecords.get(ft)));
                
            }
            disrec1.pickuprecord=map_Pick_Up_Options_name_record.get(fld);
            disrec.add(disrec1);
        }
        
        return disrec;
    }
    @AuraEnabled
    public static void cancelContract(String con){        
        Contract conStat =[select id, Status FROM Contract where id=:con WITH SECURITY_ENFORCED];
        conStat.Status = 'Cancelled';
        update conStat;      
    }
    //ECM-4354- changes Start
    @AuraEnabled
    public static Market_Setting__c getUserCountry(){
        user us = [SELECT Id,Available_Countries__c,Default_Country__c  FROM User where id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        String userCountry ;
        if(us.Available_Countries__c != null){
            if(us.Available_Countries__c.contains(';')) {				  
                userCountry = us.Default_Country__c;
            }else{
                userCountry = us.Available_Countries__c;
            }
        }
        Market_Setting__c marketObjs= [SELECT Id, Name__c,Geography__r.Code__c,ECM_Contract_Creation_Page__c,ECM_Attribute_Visibility_Screen1__c,Enable_Agreement_Guide__c FROM Market_Setting__c where Geography__r.Code__c =: userCountry and ECM_Contract_Management_Market__c=true and (ECM_Contract_Creation_Page__c !=''or ECM_Contract_Creation_Page__c != null) limit 1];
        //return marketObjs.ECM_Contract_Creation_Page__c;
        return marketObjs;
    }
    //ECM-4354- changes End
    
    
    //ECM-5692
    @AuraEnabled
    public static boolean getEandSContract(){
        User us = [SELECT Id,Available_Countries__c,Default_Country__c  FROM User WHERE Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];       
        Boolean flag = false;
        String userCountry ;
        List<ECM_Technical_Market_Setting__mdt> techMarketObjs = new List<ECM_Technical_Market_Setting__mdt>();
        techMarketObjs = [SELECT ECM_Country__c,ECM_E_S_Contracts__c FROM ECM_Technical_Market_Setting__mdt WHERE ECM_E_S_Contracts__c = true WITH SECURITY_ENFORCED];
        if(us.Available_Countries__c != null){
            if(us.Available_Countries__c.contains(';')) {				  
                userCountry = us.Default_Country__c;
            }else{
                userCountry = us.Available_Countries__c;
            }
            for(ECM_Technical_Market_Setting__mdt techMarketSett : techMarketObjs){
                if(techMarketSett.ECM_Country__c == userCountry){
                    flag=true;
                    break;
                }
            }
        }
        return flag;		
    }
    
    @AuraEnabled 
    public static Map<String, String> getChannelPicklistvalues(){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Contract.ECM_Channel__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            //Put Picklist Value & Label in Map
            options.put(p.getValue(), p.getLabel());
        }        
        return options;
    }
    @AuraEnabled 
    public static Map<String, String> getPicklistvalues(string Objectname ,string Fieldname){
        Map<String, String> options = new Map<String, String>();
        // Get the describe for the object
        DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(Objectname).getDescribe();
        // Get the field dynamically
        DescribeFieldResult fieldResult = objResult.fields.getMap().get(Fieldname).getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            //Put Picklist Value & Label in Map
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
    @AuraEnabled
    public static List<ECM_Market_Settings__c> statesAndProvinces(){
        List<ECM_Market_Settings__c> statesList = [SELECT Id, Name,ECM_Country__c FROM ECM_Market_Settings__c WITH SECURITY_ENFORCED];
        return statesList;
    }
    @AuraEnabled
    public static AccountWrapperList getAccountRecords(Integer initialRows,String filter){
        AccountWrapperList accountWrapper= new AccountWrapperList();
        try{
            //accountWrapper.accountsList = [SELECT ID,Name FROM Account ORDER BY Name ASC LIMIT :initialRows OFFSET 0];
            list<objectWrapper> objWrapper = new list<objectWrapper>();
            for(account acc : [SELECT ID, BillingCity,BillingCountry,BillingState,Name,Global_Channel__c,Hybrid__c,Parent_Outlet__c FROM Account WHERE Operator__c=:filter  WITH SECURITY_ENFORCED ORDER BY Name ASC LIMIT :initialRows OFFSET 0]){
                objectWrapper wrap = new objectWrapper();
                wrap.Id = acc.Id;
                wrap.customerName = acc.Name;
                wrap.customerCityStreetName = acc.Name + ' + '+ acc.BillingCity+ ' + '+acc.BillingCountry;
                wrap.acc = acc;
                if(acc.Hybrid__c !=false){
                    objWrapper.add(wrap);
                }else if(acc.Global_Channel__c !='Off Trade'){
                    objWrapper.add(wrap);  
                }
                
            }
            accountWrapper.accountsList = objWrapper;
            //accountWrapper.fullAccountsList = [SELECT ID,Name,BillingStreet,BillingCity,BillingState FROM Account WHERE Operator__c=:filter];
            
            list<objectWrapper> allObjWrap = new list<objectWrapper>();
            for(account acc : [SELECT ID, BillingCity,BillingCountry,BillingState,Name,Hybrid__c,Global_Channel__c,Parent_Outlet__c FROM Account WHERE Operator__c=:filter WITH SECURITY_ENFORCED]){
                objectWrapper wrap = new objectWrapper();
                wrap.Id = acc.Id;
                wrap.customerName = acc.Name;
                wrap.customerCityStreetName = acc.Name + ' + '+ acc.BillingCity+ ' + '+acc.BillingCountry;
                wrap.acc = acc;
                if(acc.Hybrid__c !=false){
                    allObjWrap.add(wrap);
                }else if(acc.Global_Channel__c !='Off Trade'){
                    allObjWrap.add(wrap);  
                }
                // allObjWrap.add(wrap);  
            }
            accountWrapper.fullAccountsList = allObjWrap;
            accountWrapper.totalRecords = [SELECT COUNT() FROM Account WHERE Operator__c=:filter];
            accountWrapper.message = System.label.ECM_AccountAreLoaded;
            accountWrapper.success = true;
        }
        catch(Exception e){
            accountWrapper.message = e.getMessage();
            accountWrapper.success = false;
        }
        return accountWrapper;
        
    }
    //To return additional records based on offset
    @AuraEnabled
    public static List<objectWrapper> loadAccountRecords(Integer rowLimit,Integer rowOffset,String filter){
        list<objectWrapper> objWrapper = new list<objectWrapper>();
        for(account acc : [SELECT ID, BillingCity,BillingCountry,BillingState,Name,Hybrid__c,Parent_Outlet__c FROM Account WHERE Operator__c=:filter WITH SECURITY_ENFORCED ORDER BY Name ASC LIMIT :rowLimit OFFSET :rowOffset]){
            objectWrapper wrap = new objectWrapper();
            wrap.Id = acc.Id;
            wrap.customerName = acc.Name;
            wrap.customerCityStreetName = acc.Name + ' + '+ acc.BillingCity+ ' + '+acc.BillingCountry;
            wrap.acc = acc;
            objWrapper.add(wrap);
        }
        return objWrapper;
    }
    @AuraEnabled
    public static string validation_for_Agreement_Type(contract con,string accountid ,String recordTypeId){
        string result = 'create';
        if(recordtypeid ==null || recordTypeId ==''){
            recordTypeId= con.recordTypeId;
        }
        list < contract > conrecordWithApprovedorActive = new list < contract > ();
        list < contract > conrecordWithDraft = new list < contract > ();
        ECM_Contract_Type__c aggrementrecord = new ECM_Contract_Type__c();
        Account accObj = new Account();
        Market_Setting__c marketObj = new Market_Setting__c();
        //Map<String,String> marMap = new Map<String,String>();
        if (con.ECM_Agreement_Type__c != null && accountid != null) {
            conrecordWithApprovedorActive = [select id, accountid, status, StartDate, Contract_End_Date__c from contract where ECM_Agreement_Type__c =: con.ECM_Agreement_Type__c and recordtypeid =:recordTypeId and id !=: con.id and accountid =: accountid and(status =: 'Active'
                                                                                                                                                                                                                                                                   or status =: 'In Approval process') WITH SECURITY_ENFORCED];
            system.debug(LoggingLevel.DEBUG,'agree=='+con.ECM_Agreement_Type__c);
            system.debug(LoggingLevel.DEBUG,'recordTypeId='+recordTypeId);
            system.debug(LoggingLevel.DEBUG,'accountid='+accountid);
            conrecordWithDraft = [select id, accountid, status, StartDate, Contract_End_Date__c from contract where ECM_Agreement_Type__c =: con.ECM_Agreement_Type__c and accountid =: accountid and id !=: con.id and recordtypeid =:recordTypeId and status =: 'Draft' WITH SECURITY_ENFORCED];
            system.debug(LoggingLevel.DEBUG,'==='+conrecordWithDraft);
            // workitem - 140553 : Added ECM_Allow_Multiple_drafts__c in query
            aggrementrecord = [SELECT id, ECM_Allow_Multiple_Agreements__c,
                               ECM_Allow_Multiple_drafts__c,
                               Geography__r.Name,Geography__r.Code__c 
                               FROM ECM_Contract_Type__c 
                               WHERE id =: con.ECM_Agreement_Type__c WITH SECURITY_ENFORCED];
            accObj =[select id, Name, Country__r.Code__c from Account where id=: accountid WITH SECURITY_ENFORCED] ;
            //ECM-4531
            marketObj= [SELECT Id, Name__c,Geography__r.Code__c,ECM_Contract_Creation_Page__c FROM Market_Setting__c where Geography__r.Code__c =: accObj.Country__r.Code__c and ECM_Contract_Management_Market__c=true and (ECM_Contract_Creation_Page__c !=''or ECM_Contract_Creation_Page__c != null) limit 1];
            
        }
        if(marketObj.ECM_Contract_Creation_Page__c=='Global'){
            system.debug(LoggingLevel.DEBUG,'agree multi='+aggrementrecord.ECM_Allow_Multiple_Agreements__c);
            system.debug(LoggingLevel.DEBUG,'agree draft='+aggrementrecord.ECM_Allow_Multiple_drafts__c);
            system.debug(LoggingLevel.DEBUG,'draft size='+conrecordWithDraft.size());
            if (conrecordWithApprovedorActive.size() > 0) {
                if (conrecordWithDraft.size() == 0 && aggrementrecord.ECM_Allow_Multiple_Agreements__c) {
                    result = 'create';
                    return result;
                    // workitem - 140553
                }else if (conrecordWithDraft.size() >= 0 && aggrementrecord.ECM_Allow_Multiple_Agreements__c
                          && !aggrementrecord.ECM_Allow_Multiple_drafts__c) {
                              result = 'approverecord';
                              return result;
                          }else if (conrecordWithDraft.size() >= 0 && ! aggrementrecord.ECM_Allow_Multiple_Agreements__c) {
                              for (Contract conapprove: conrecordWithApprovedorActive) {
                                  if (conapprove.Contract_End_Date__c >= con.StartDate) {
                                      result = 'approverecord';
                                      return result;
                                  }
                              }  
                          }/*else if (conrecordWithDraft.size() == 0 && ! aggrementrecord.ECM_Allow_Multiple_Agreements__c) {
for (Contract conapprove: conrecordWithApprovedorActive) {
if (conapprove.Contract_End_Date__c >= con.StartDate) {
result = 'approverecord';
return result;
}
}
}*/
                // workitem - 140553
            } else if (conrecordWithDraft.size() > 0 && !aggrementrecord.ECM_Allow_Multiple_drafts__c) {
                result = 'draftrecord';
                return result;
            }
        }
        else if(marketObj.ECM_Contract_Creation_Page__c=='Australia'){
            if (!aggrementrecord.ECM_Allow_Multiple_Agreements__c) {
                if(conrecordWithDraft.size() > 0){
                    result = 'draftrecord';
                    
                }
                else{
                    result = 'create';
                }
                
            }
            else{
                result = 'create';
                
            }
            return result;
        }
        return result;
    }
    @AuraEnabled
    public static void savecontract(contract con){
        upsert con;
        String pf = [select ECM_Payment_Frequency_Type__r.Name from Contract where id=:con.id Limit 1].ECM_Payment_Frequency_Type__r.Name;
        system.debug(LoggingLevel.DEBUG,'AfterSecondUpdate->'+pf);
    }
    @AuraEnabled
    public static Contract savecontractanditems(string con,string contractItemsList, string outletContractList){
        Contract contractRecord = new Contract();
        try{
            List<ECM_Contract_Item__c> contractItems = (List<ECM_Contract_Item__c>)JSON.deserialize(contractItemsList, List<ECM_Contract_Item__c>.class);
            upsert contractItems;
            contractRecord = (Contract)JSON.deserialize(con, Contract.class);
            upsert contractRecord;
            if(contractRecord.ECM_Agreement_Type__r.ECM_of_Outlets_Tap_Space_Required__c != Null &&
               System.Label.ECM_OutletTapsTable_CountryCode.split(';').contains(contractRecord.Account.Country_Code__c)){
                   List<Outlet_Contract__c> outletContractItems = (List<Outlet_Contract__c>)JSON.deserialize(outletContractList, List<Outlet_Contract__c>.class); //CUS-346 
                   upsert outletContractItems; //CUS-402
               }
            
        }catch(Exception ex){
            system.debug(LoggingLevel.DEBUG,'Error='+ex);  
        }
        return contractRecord;
    }
    /*
* Name : updateKpiValues (ECM-5907)
* @description : This method is used to update Contract Kpi values
* @return : Contract Record
* @param : Contract Rec
*/
    @AuraEnabled
    public static Contract updateKpiValues(string con){
        Contract contractRecord = new Contract();
        if(con!=null){
            contractRecord = (Contract)JSON.deserialize(con, Contract.class);
            ECM_ContractKpiHelper.calculateFieldValues(contractRecord);
        }
        return contractRecord;
    }
    
    /*
* Name : updateContractItems
* @description : This method is used to update the Contract Items with the values provided in component
* @return : List<ECM_Contract_Item__c>
* @param : Contract Item List
*/
    @AuraEnabled
    public static List<ECM_Contract_Item__c> updateContractItems(List<ECM_Contract_Item__c> contractItems){
        update contractItems;
        return contractItems;
    }
    @AuraEnabled
    public static List<ECM_Payment_Agreement__c> paymentFrequencyvalues(string agreementId){
        List<ECM_Payment_Agreement__c> paymentFrequencylist = [SELECT Id, ECM_Agreement_Type__c,ECM_Agreement_Type__r.Volume_UoM_for_Spirits__c,ECM_Agreement_Type__r.ECM_Volume_UoM_for_Beer__c,ECM_Agreement_Type__r.ECM_Volume_UoM_for_RTD__c,ECM_Agreement_Type__r.ECM_Volume_UoM_for_Draught_Cocktails__c,ECM_Payment_Frequency__r.ECM_Volume_target__c,
                                                               ECM_Payment_Frequency__c,toLabel(ECM_Payment_Frequency__r.ECM_Type__c),ECM_Payment_Frequency__r.ECM_Limit_for_prepayment_in_LC__c,ECM_Agreement_Type__r.ECM_Max_Rate_UoM__c FROM ECM_Payment_Agreement__c where ECM_Agreement_Type__c =:agreementId AND ECM_Payment_Frequency__r.ECM_Volume_target__c = true];//ECM-5538
        return paymentFrequencylist;
    }
    
    @AuraEnabled
    public static ECM_Tiering__c getTieringObj(string conItemId){
        try{
            ECM_Tiering__c tieringObj =[Select Id,Name,ECM_Tier_1_volume_limit__c,ECM_Tier_1_rate_per_UoM__c,ECM_Tier_2_volume_limit__c,ECM_Tier2_rate_per_UoM__c,
                                        ECM_Tier_3_volume_limit__c,ECM_Tier_3_rate_per_UoM__c,ECM_Contract_Item__c,ECM_Contract_Item__r.ECM_Product__r.Product_Name__c 
                                        from ECM_Tiering__c where ECM_Contract_Item__c=:conItemId];
            return tieringObj;
        } 
        catch(exception e){
            ECM_Tiering__c tierobj=New ECM_Tiering__c();
            return tierobj;
        }
    }
    @AuraEnabled
    public static void delTieringObjrec(string tierId){
        ECM_Tiering__c tierObj = [Select Id from ECM_Tiering__c where Id=:tierId];
        Delete tierObj;
    }
    @AuraEnabled
    public static ECM_Tiering__c createTieringRecord(string conItemId,Decimal tier1val,Decimal tier1rate,Decimal tier2val,Decimal tier2rate,Decimal tier3val,Decimal tier3rate){
        system.debug(LoggingLevel.DEBUG,'conItemId'+conItemId);
        try{
            ECM_Tiering__c tieringObj =getTieringObj(conItemId);
            if(tieringObj !=null){
                tieringObj.ECM_Tier_1_volume_limit__c =tier1val;
                tieringObj.ECM_Tier_1_rate_per_UoM__c =tier1rate;
                tieringObj.ECM_Tier_2_volume_limit__c =tier2val;
                tieringObj.ECM_Tier2_rate_per_UoM__c =tier2rate;
                tieringObj.ECM_Tier_3_volume_limit__c =tier3val;
                tieringObj.ECM_Tier_3_rate_per_UoM__c =tier3rate;
                tieringObj.ECM_Contract_Item__c =conItemId;
                update tieringObj;
            }
            
            return tieringObj;
        }
        catch(exception e){
            if(tier1val !=null){
                ECM_Tiering__c tierInsertObj=New ECM_Tiering__c();
                tierInsertObj.ECM_Tier_1_volume_limit__c =tier1val;
                tierInsertObj.ECM_Tier_1_rate_per_UoM__c =tier1rate;
                tierInsertObj.ECM_Tier_2_volume_limit__c =tier2val;
                tierInsertObj.ECM_Tier2_rate_per_UoM__c =tier2rate;
                tierInsertObj.ECM_Tier_3_volume_limit__c =tier3val;
                tierInsertObj.ECM_Tier_3_rate_per_UoM__c =tier3rate;
                tierInsertObj.ECM_Contract_Item__c =conItemId;
                insert tierInsertObj;
                return getTieringObj(tierInsertObj.ECM_Contract_Item__c);
            }
            else{
                return null;
            }
            
        }
    }
    @AuraEnabled
    public static List<ECM_Payment_Agreement__c> paymentSchedulevalues(string agreementId){
        List<ECM_Payment_Agreement__c> paymentScheduleList = [SELECT Id, ECM_Agreement_Type__c,ECM_Agreement_Type__r.ECM_Aggrement_Duration__c,ECM_Payment_Frequency__r.ECM_Other_Investment__c,ECM_Payment_Frequency__c,toLabel(ECM_Payment_Frequency__r.ECM_Type__c),ECM_Payment_Frequency__r.ECM_Limit_for_prepayment_in_LC__c FROM ECM_Payment_Agreement__c where ECM_Agreement_Type__c =:agreementId AND ECM_Payment_Frequency__r.ECM_Other_Investment__c = true AND (ECM_Payment_Frequency__r.ECM_Type__c!=:system.label.ECM_Single_Yearly_Payments OR (ECM_Payment_Frequency__r.ECM_Type__c=:system.label.ECM_Single_Yearly_Payments AND ECM_Agreement_Type__r.ECM_Aggrement_Duration__c!='Days'))];  
        return  paymentScheduleList;
    }
    @AuraEnabled
    public static salesdriverswithAgreementType salesdrivers(string agreementId){
        salesdriverswithAgreementType wrap = new salesdriverswithAgreementType();
        String activationRecordTypeID = Schema.getGlobalDescribe().get('ECM_Sales_Driver__c').getDescribe().getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();
        //ECM-4677 - added ECM_Mandatory_For_Related_Agreement_Type__c in the query
        //ECM-5439 - added ECM_Activation_Spend_Sub_Group__c in the query
        //155930 - ECM_Sales_Driver__r.Sales_driver_Product_Filter__c in query
        List<ECM_Sales_Agreement__c> salesdriverslist = [SELECT Id,ECM_Sales_Driver__c,ECM_Mandatory_For_Related_Agreement_Type__c,ECM_Sales_Driver__r.ECM_Automatic_Amount_Split__c ,
                                                         ECM_Sales_Driver__r.ECM_Multi_Use__c,ECM_Sales_Driver__r.ECM_Default__c,ECM_Sales_Driver__r.ECM_Hide_Total_Amount__c, ECM_Agreement_Type__c,
                                                         ECM_Sales_Driver__r.ECM_Applied_To_All__c,ECM_Sales_Driver__r.ECM_Territory_Budget__c,
                                                         ECM_Sales_Driver__r.ECM_Territory_Budget__r.ECM_Type__c, ECM_Sales_Driver__r.name,ECM_Sales_Driver__r.ECM_Is_Range__c,
                                                         ECM_Sales_Driver__r.Geography__r.Name,ECM_Sales_Driver__r.RecordType.name,ECM_Sales_Driver__r.RecordTypeId,
                                                         ECM_Sales_Driver__r.ECM_Activation_Spend_Sub_Group__c,ECM_Sales_Driver__r.ECM_Product_Sub_Category__c,
                                                         ECM_Sales_Driver__r.Sales_driver_Product_Filter__c,ECM_Sales_Driver__r.ECM_Product_Sub_Category__r.Name
                                                         FROM ECM_Sales_Agreement__c 
                                                         where ECM_Agreement_Type__c =:agreementId
                                                         Order by ECM_Mandatory_For_Related_Agreement_Type__c DESC];
        wrap.salesAgreementList = salesdriverslist;
        wrap.ActivationRecordTypeID = ActivationRecordTypeID;
        
        // system.debug('salesAgreementList'+salesdriverslist);
        // ECM-4757 - added ECM_Allow_Zero_Investment_on_Screen_4__c in ECM_Contract_Type__c query
        
        wrap.selectedAgreementType = [Select id,Name,ECM_Aggrement_Duration__c,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Volume_target__c,ECM_Allow_Zero_Investment_on_Screen_4__c,ECM_Sales_Driver_Default_Appearance__c,ECM_Signature_Cocktail_Message__c  FROM ECM_Contract_Type__c Where Id=:agreementId];
        
        wrap.recordType=[SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'ECM_Sales_Driver__c' and Name = 'Investment'];
        return  wrap; 
        
    }
    /*
* @description : Returns a wrapper with screen-3 table data from Contract Items and available options for user input
* @return : contractItemsandAgreementType
* @param : List<ECM_Contract_Item__c>
*/
    @AuraEnabled 
    public static contractItemsandAgreementType get_contractitem_with_exsisiting_baseVol(List<ECM_Contract_Item__c> selectedrecords){
        contractItemsandAgreementType wrapper = new contractItemsandAgreementType();
        list<contractitemswithBasevolandPGD> listContractitemswithBasevolandPGD = new list<contractitemswithBasevolandPGD>(); 
        //map<string,ECM_Contract_Item__c> set_string_selected_contractitem= new map<string,ECM_Contract_Item__c>();
        //map<string,ECM_Contract_Item__c> set_string_exsisiting_contractitem= new map<string,ECM_Contract_Item__c>();
        Map<id,decimal> productBaseVol= new Map<id,decimal>();//new List<Depletions__c>();
        //Set<id> matchingproductrecords = new Set<id>();
        //list<String> growthDriverList= new List<String>();
        Map<Id,String> productGrowthDriverMap = new Map<Id,String>(); //Map of all product Growth Driver Ids and Name - ECM-4846
        Map<String,Map<Id,String>> prodNameWithPGDMap = new Map<String,Map<Id,String>>(); //Map of selected products with all PGD(productGrowthDriverMap) -ECM-4846
        Map<Id,String> conItmIdProdName = new Map<Id,String>();
        
        //ECM-5790
        List<String> addendumStatusCheck = Label.ECM_Addendum_Status_Check.split(';'); // Draft;Approved
        List<String> contractStatusCheck = Label.ECM_ContractStatus_ForAddendumCheck.split(';'); //Draft;Active
        
        //CUS-123
        List<String> legalCompliancePGDList = new list<String>();
        //ECM-5924
        //CUS-123 - added ECM_Product__r.Product__r.Sub_Category_Formula__c in CI query
        if(selectedrecords.size()>0){
            List<ECM_Contract_Item__c> records=[Select Id,ECM_Product_Name__c,ECM_Product__c,ECM_Product__r.Product__c,ECM_Product__r.Product__r.Name,ECM_Product__r.ECM_Pickup_Option__r.Name, ECM_UoM__c, ECM_Volume__c,ECM_Baseline_volume__c,
                                                ECM_First_Pour__c,ECM_Exclusive__c,ECM_Mandatory_Back_Bar__c,ECM_Volume_hybrid_original__c,ECM_volume_hybrid_override__c,ECM_Investment__c, 
                                                ECM_MAT_original__c,ECM_MAT_override__c,ECM_TSDD_Original__c,ECM_TSDD_Override__c,ECM_TotalAdditional_Discount__c,ECM_Price_List_ConItem__c,ECM_Price_List_ConItem__r.ECM_EU_Conversion_Factor__c,ECM_EU_Volume__c,
                                                ECM_TotalSKU_SpecificRebate__c,ECM_FinalLUC_Current__c,ECM_FinalLUC_Target__c,ECM_LUC_Discount__c,ECM_Lead_Brand__c,
                                                ECM_Product__r.Product_Name__c,ECM_Contract__r.AccountId,ECM_Contract__c,ECM_Contract__r.ECM_Agreement_Type__c,ECM_Product_growth_driver__c,ECM_Brand__c,ECM_Category__c,ECM_Product_Category__c,
                                                ECM_Addendum__c,ECM_Addendum__r.ECM_Status__c,ECM_Contract__r.Status,ECM_Contracts_UoM__c,ECM_Product__r.Product__r.Sub_Category_Formula__c  from ECM_Contract_Item__c where id in:selectedrecords];
            
            contract contra=[SELECT id,accountid,Account.Country__c,RecordType.Name,ECM_Agreement_Type__c,ECM_Agreement_Type__r.Geography__c,ECM_Agreement_Type__r.Geography__r.Name,StartDate,ECM_Select_UoM__c,
                             ECM_Payment_Frequency_type__c,ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c,ECM_Payment_Frequency_type__r.ECM_End_Date__c,ECM_Duration__c,ECM_Overall_Investment_Amount__c,
                             Contract_End_Date__c,Account.Hybrid__c, Account.Parent_Outlet__c FROM contract WHERE id =: records[0].ECM_Contract__c WITH SECURITY_ENFORCED]; //ECM-6012 : added PF related fields in query
            wrapper.pickuomvalue = contra;
            
            //ECM-4846 starts - Prepare PGD Map<PGD-Id,PGD-Name> with all available PGD record and assign it against all selected products
            //ECM-6628 bug fix- changed from recordtype.Name to recordtype.DeveloperName in where condition
            for(Pick_Up_Options__c p:[SELECT id,Name,ECM_Legal_Compliance__c FROM Pick_Up_Options__c WHERE Geography__c=:contra.Account.Country__c AND recordtype.DeveloperName =: System.Label.ECM_VolumeTargetApexClass_Product_Growth_driver WITH SECURITY_ENFORCED]){
                productGrowthDriverMap.put(p.Id,p.Name.substringBefore('[').trim());
                //CUS-123
                if(p.ECM_Legal_Compliance__c){
                    legalCompliancePGDList.add(p.Name.substringBefore('[').trim());
                }
            }
            //ECM-6300
            for(ECM_Contract_Item__c ci : records){
                prodNameWithPGDMap.put(ci.ECM_Product__c,new Map<Id,String>(productGrowthDriverMap));
                conItmIdProdName.put(ci.Id,ci.ECM_Product__r.Product_Name__c);
            }
            wrapper.conItmMap = conItmIdProdName;
            //Remove particular PGD from PGD Map associated with a product based on Growth Driver Records present
            for(ECM_Growth_Driver_Exclusions__c it : [SELECT ECM_MAP__c,ECM_MAP__r.Product_Name__c,ECM_Product_Growth_Driver__c FROM ECM_Growth_Driver_Exclusions__c WHERE ECM_Active__c = true
                                                      AND ECM_Product_Growth_Driver__c IN: productGrowthDriverMap.keySet() AND ECM_MAP__c IN: prodNameWithPGDMap.keySet()])
            {
                
                if(prodNameWithPGDMap.containsKey(it.ECM_MAP__c)){
                    Map<Id,String> currMap = prodNameWithPGDMap.get(it.ECM_MAP__c);
                    currMap.remove(it.ECM_Product_Growth_Driver__c);
                    prodNameWithPGDMap.put(it.ECM_MAP__c,currMap);
                }
            } 
            //ECM-4846 ends
            productBaseVol=ECM_Get_Product_Depletions_Basevolume.ECM_Get_Product_Depletions_Basevolume(records,contra,contra.StartDate,false);
            for(ECM_Contract_Item__c items :records){
                contractitemswithBasevolandPGD record= new contractitemswithBasevolandPGD();
                //ECM-6160
                if(items.ECM_Product_growth_driver__c!=null){
                    List<String> drivers = items.ECM_Product_growth_driver__c.split('/'); 
                    if(!drivers.isEmpty()){
                        record.firstProdDriver = drivers[0];
                    }
                }
                //ECM-6160
                record.ContractItem = items;
                record.Basevolume = (productBaseVol.size()>0 && productBaseVol.containskey(items.ECM_Product__r.Product__c))?
                    String.valueOf(productBaseVol.get(items.ECM_Product__r.Product__c)):'0';
                record.productGrowthDriverList = prodNameWithPGDMap.containsKey(items.ECM_Product__c)?
                    prodNameWithPGDMap.get(items.ECM_Product__c).values():new List<String>();//ECM-4846
                //CUS-123
                record.legalCompliancePGD = !legalCompliancePGDList.isEmpty()?legalCompliancePGDList: new List<String>();
                //ECM-5790
                if(contractStatusCheck[1].containsIgnoreCase(items.ECM_Contract__r.Status) && items.ECM_Addendum__c != Null &&
                   addendumStatusCheck[1].containsIgnoreCase(items.ECM_Addendum__r.ECM_Status__c)){
                       record.toBeDisabled = true;
                   }
                else if((contractStatusCheck[0].containsIgnoreCase(items.ECM_Contract__r.Status)) || 
                        (contractStatusCheck[1].containsIgnoreCase(items.ECM_Contract__r.Status) && items.ECM_Addendum__c != Null && 
                         addendumStatusCheck[0].containsIgnoreCase(items.ECM_Addendum__r.ECM_Status__c))){
                             record.toBeDisabled = false;
                         }
                else{
                    record.toBeDisabled = true;
                }
                
                listContractitemswithBasevolandPGD.add(record);
            }
            wrapper.ContractItemwithVolumeAndPGD = listContractitemswithBasevolandPGD;
            wrapper.AgreementType = [SELECT id,Name,ECM_Category_Contracts__c,ECM_Allow_Zero_Investment__c FROM ECM_Contract_Type__c where Id =: contra.ECM_Agreement_Type__c];//ECM-5134
        }
        return wrapper;
    }
    @AuraEnabled
    Public static List<ECM_Contract_Item__c> saveVolumeTargets(string contractItemList, ECM_Contract_Type__c agreementType, Contract ContractRecord, String addenDumId){
        List<ECM_Contract_Item__c> conitem = (List<ECM_Contract_Item__c>)JSON.deserialize(contractItemList,List<ECM_Contract_Item__c>.class);
        //ECM-6012 starts
        if(addenDumId != null && !String.isEmpty(addenDumId)){
            List<ECM_Contract_Item__c> conItemforAddendum = new List<ECM_Contract_Item__c>();
            if(ContractRecord.ECM_Payment_Frequency_Type__c != null) {
                Integer months;
                if(String.isNotBlank(ContractRecord.ECM_Payment_Frequency_Type__r.ECM_Number_of_months_for_recurrence__c)) {
                    months = Integer.valueOf(ContractRecord.ECM_Payment_Frequency_Type__r.ECM_Number_of_months_for_recurrence__c); 
                }
                for(ECM_Contract_Item__c ci : conitem){
                    if(ci.ECM_Addendum__c == addenDumId){
                        if(months>0 && ci.ECM_Volume__c>0 && ContractRecord.ECM_Duration__c>0) {
                            ci.ECM_Volume_Target_per_PF__c = ((ci.ECM_Volume__c / ContractRecord.ECM_Duration__c)*months).setScale(2);
                        } else if(ContractRecord.ECM_Payment_Frequency_type__r.ECM_End_Date__c) {
                            ci.ECM_Volume_Target_per_PF__c = (ci.ECM_Volume__c);
                        }
                    }
                    conItemforAddendum.add(ci);
                }
                conitem = conItemforAddendum;
            }
        }
        //ECM-6012 ends
        if(!conItem.isEmpty()){
            update conitem;
        }
        update contractRecord;
        return conitem;
    }
    /** 
* @description	:	CUS-123 - FASTTRACK-Logic for the Legal Compliance Field 
* @return		:	List<String>
* @param event	:	String
**/    
    @AuraEnabled
    public static List<String> getLeadProductWithSubCategory(String contractId){
        List<String> legalCompliancePGDList = new List<String>();
        List<String> returnList = new List<String>();
        //Fetch Contract
        Contract conRec = [SELECT Id,Account.Country__c FROM Contract WHERE Id =: contractId WITH SECURITY_ENFORCED];
        //Fetch Pickup Options
        for(Pick_Up_Options__c p:[SELECT Id,Name,ECM_Legal_Compliance__c 
                                  FROM Pick_Up_Options__c 
                                  WHERE Geography__c=:conRec.Account.Country__c 
                                  AND recordtype.DeveloperName =: System.Label.ECM_VolumeTargetApexClass_Product_Growth_driver 
                                  AND ECM_Legal_Compliance__c=true WITH SECURITY_ENFORCED]){
                                      legalCompliancePGDList.add(p.Name.substringBefore('[').trim());            
                                  }
        if(!legalCompliancePGDList.isEmpty()){
            //Get contract items
            for(ECM_Contract_Item__c conItem: 
                [SELECT Id,ECM_Product_Name__c,ECM_Product__c,ECM_Product__r.Product__c,
                 ECM_Product__r.Product__r.Name,ECM_Contract__c,ECM_Product_growth_driver__c,
                 ECM_Lead_Brand__c,ECM_Product__r.Product__r.Sub_Category_Formula__c  
                 FROM ECM_Contract_Item__c 
                 WHERE ECM_Contract__c =:conRec.Id 
                 AND ECM_Lead_Brand__c = true
                 AND ECM_Product_growth_driver__c != null
                 AND ECM_Product__r.Product__r.Sub_Category_Formula__c!= null]){
                     List<String> selectedPGD = conItem.ECM_Product_growth_driver__c.split('/');
                     for(Integer i=0;i<selectedPGD.size();i++){
                         if(legalCompliancePGDList.contains(selectedPGD[i])){
                             returnList.add(conItem.ECM_Product__r.Product__r.Sub_Category_Formula__c );
                         }
                     }   
                 }
        }
        System.debug(LoggingLevel.DEBUG,'returnList @'+returnList);
        return returnList;
    }
    /* added parameter String contractId
     * 155930 */
    @AuraEnabled
    Public static List<salesdriverItemWrap> saveSalesDrivers(string listsalesDrivers,string salesdriver,List<ECM_Contract_Item__c> contractItems,String contractId){
        salesdriveritems salesitem = (salesdriveritems)JSON.deserialize(salesdriver, salesdriveritems.class);
        List<salesdriverItemWrap> wrapperList;
        if(listsalesDrivers==Null || listsalesDrivers==''){
            wrapperList = new List<salesdriverItemWrap>();
        }else{
            wrapperList = (List<salesdriverItemWrap>)JSON.deserialize(listsalesDrivers, List<salesdriverItemWrap>.class);
        } 
        
        string recordType=[SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'ECM_Sales_Driver__c' and Name='Check'].Id;
        
        //List<ECM_Sales_Driver_Item__c> salesdriveitmlist = new List<ECM_Sales_Driver_Item__c>();
        List<salesdriverItemDetailsWrap> contractItemWrap = new List<salesdriverItemDetailsWrap>();
        system.debug(LoggingLevel.DEBUG,'contractitems==='+contractitems);
        salesdriverItemWrap saleswrap = new salesdriverItemWrap(); 	
        //string contractId;
        Decimal totalinvestval = 0;
        //ECM-5452
        //155930 - added contractId fetch
        Contract contrObj = [Select id, Name,StartDate,Contract_End_Date__c from Contract where id =:contractId WITH SECURITY_ENFORCED limit 1];
        List<String> fyYearLst = fiscalYearCalculate(contrObj);
        
        if(recordType != salesitem.DriverType && contractitems.size()>0){
            System.debug(LoggingLevel.DEBUG,'$$$-ans'+contractitems.size());
            for(ECM_Contract_Item__c conitem : contractitems){            
                salesdriverItemDetailsWrap recordswrap = new salesdriverItemDetailsWrap();
                recordswrap.productname = conitem;
                recordswrap.investment = 0;//conitem.ECM_Investment__c;
                //155930
                recordswrap.selectedProductcheck = (salesitem.productFilter!='' && salesitem.productFilter!=conitem.ECM_Product__r.Product__r.Sub_Category_Formula__c)?false:true;
                recordswrap.yearLst = fyYearLst;                
                totalinvestval = 0;//conitem.ECM_Investment__c!=Null? totalinvestval+conitem.ECM_Investment__c:0;
                contractItemWrap.add(recordswrap);
            }
            saleswrap.totalInvest = saleswrap.totalInvest==0?totalinvestval:saleswrap.totalInvest;
            saleswrap.saledriveItemDetailsWrapList = contractItemWrap;
            saleswrap.createdtime=system.now();
            
        }
        
        ECM_Sales_Driver_Item__c salesItemRec = new ECM_Sales_Driver_Item__c();//saleswrap.salesDriver;//Drivername DriverRange SalesDriver DriverType Name applied BudjectType
        salesItemRec.ECM_Sales_Driver_Name__c = salesItem.Drivername;
        salesItemRec.ECM_Range__c = salesItem.DriverRange;
        salesItemRec.ECM_Sales_Driver__c = salesItem.SalesDriver; 
        //salesItem.ECM_Budget_Type__c = saleswrap.saledrive.BudjectType;
        salesItemRec.ECM_Total_Investment_Amount__c = 0;
        // salesItemRec.Contract__c = contractDetails.Id;
        saleswrap.salesDriver = salesItemRec;
        saleswrap.saledrive = salesitem;
        //155930
        saleswrap.yearLst = fyYearLst;
        wrapperList.add(saleswrap);
        system.debug(LoggingLevel.DEBUG,'=='+wrapperList);
        return wrapperList;
    }
    //ECM-5793
    @AuraEnabled
    public static List<ECM_Sales_Driver_Item_Detail__c> createSalesDriverItemDetailForAddendum(String conId,String addendumId){
        List<ECM_Contract_Item__c> conItems = new List<ECM_Contract_Item__c>([SELECT Id,ECM_Product__c,ECM_Addendum__c FROM ECM_Contract_Item__c WHERE  ECM_Addendum__c=:addendumId AND ECM_Contract__c=:conId]);
        List<ECM_Sales_Driver_Item_Detail__c> insertSDID = new List<ECM_Sales_Driver_Item_Detail__c>();
        List<ECM_Sales_Driver_Item_Detail__c> deleteSDID = new List<ECM_Sales_Driver_Item_Detail__c>();
        Map<Id,set<ID>> sdidMap = new Map<Id,set<ID>>();
        Id recId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item__c').getDescribe().getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id recIdSdid = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item_Detail__c').getDescribe().getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        for(ECM_Sales_Driver_Item__c sdi:[SELECT Id,(SELECT Id,ECM_Product__c from Sales_Driver_Item_Details__r) from ECM_Sales_Driver_Item__C where Contract__c=:conID and RecordTypeId=:recId WITH SECURITY_ENFORCED]){
            for(ECM_Sales_Driver_Item_Detail__c sdid: sdi.Sales_Driver_Item_Details__r){
                if(sdid.ECM_Product__c == Null){
                    deleteSDID.add(sdid);
                }
                if(!sdidMap.containsKey(sdi.Id)){
                    sdidMap.put(sdi.Id,new set<Id>{sdid.ECM_Product__C});
                }
                else{
                    sdidMap.get(sdi.Id).add(sdid.ECM_Product__C);
                }
            }
            
        }
        //For Duplicate check
        for(Id sdi:sdidMap.keySet()){       
            for(ECM_Contract_Item__c conItem : conItems){
                if(!sdidMap.get(sdi).contains(conItem.Id)){
                    ECM_Sales_Driver_Item_Detail__c salesItem = new ECM_Sales_Driver_Item_Detail__c();
                    salesItem.ECM_Product__c = conItem.Id;
                    salesItem.RecordTypeId = recIdSdid;
                    salesItem.ECM_Sales_Driver_Item__C = sdi;
                    salesItem.ECM_Addendum__c = addendumId;
                    salesItem.ECM_Investment_Amount__c = 0;
                    insertSDID.add(salesItem);
                }
            }
        }
        System.debug(LoggingLevel.DEBUG,'insertSDID : '+insertSDID);
        if(insertSDID.size()>0 && Schema.sObjectType.ECM_Sales_Driver_Item_Detail__c.isCreateable()){
            insert insertSDID;  
        }
        if(!deleteSDID.isEmpty() && Schema.sObjectType.ECM_Sales_Driver_Item_Detail__c.isDeletable()){
            delete deleteSDID;
        }
        return insertSDID;
        
    }
    @AuraEnabled
    public static List<ECM_CreateContractController.salesdriverItemWrap> loadInvestmentsValues(Contract conRecord,List<ECM_Contract_Item__c> selectedrecords,Boolean isAddendum,boolean isNew){
        //changes related to ECM-5210
        //Variables
        Id sdiRecordTypeId;
        Id sdidRecordTypeId;
        String sdRecordTypeName = 'Sales Driver';
        String asRecordTypeName = 'Activation Spend';
        List<String> fyYears = fiscalYearCalculate(conRecord);//ECM-5452
        ECM_Contract_Type__c ecmContractType = [SELECT id,ECM_Activation_Spend__c FROM ECM_Contract_Type__c where id=:conRecord.ECM_Agreement_Type__c WITH SECURITY_ENFORCED limit 1];
        
        if(ecmContractType.ECM_Activation_Spend__c && (conRecord.ECM_Last_saved_page__c==6 || conRecord.ECM_Last_saved_page__c==5)){
            system.debug(LoggingLevel.INFO,'last screen Activation Spend');
            sdiRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item__c').getDescribe().getRecordTypeInfosByName().get(AsRecordTypeName).getRecordTypeId();
            sdidRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item_Detail__c').getDescribe().getRecordTypeInfosByName().get(AsRecordTypeName).getRecordTypeId();
        }else{
            system.debug(LoggingLevel.INFO,'last screen Sales driver');
            sdiRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item__c').getDescribe().getRecordTypeInfosByName().get(SdRecordTypeName).getRecordTypeId();
            sdidRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item_Detail__c').getDescribe().getRecordTypeInfosByName().get(SdRecordTypeName).getRecordTypeId();
        }
        // changes related to ECM-5237
        Map<Id, ECM_Contract_Item__c> conItemMap = new Map<Id, ECM_Contract_Item__c>(selectedrecords);
        Map<Id,Id> sdidConIdMap = new Map<Id,Id>();
        Map<String, List<ECM_Sales_Driver_Item_Detail__c>> sdiAndSDIDMap= new Map<String, List<ECM_Sales_Driver_Item_Detail__c>>();
        //Map<String, List<ECM_Sales_Driver_Item_Detail__c>> sdiAndSDIDNewMap= new Map<String, List<ECM_Sales_Driver_Item_Detail__c>>();
        Map<Id,ECM_Sales_Driver_Item__c> sdiMap;
        List<ECM_Sales_Driver_Item_Detail__c> newSDIDList =  new List<ECM_Sales_Driver_Item_Detail__c>();
        List<ECM_CreateContractController.salesdriverItemWrap> wrapperList = new List<ECM_CreateContractController.salesdriverItemWrap>();
        Boolean isInsert = false;
        //ECM-6337
        List<Id> additionalSDIDs = new List<Id>();
        //ECM-5793
        List<String> addendumStatusCheck = Label.ECM_Addendum_Status_Check.split(';'); // Draft;Approved
        List<String> contractStatusCheck = Label.ECM_ContractStatus_ForAddendumCheck.split(';'); //Draft;Active
        //ECM-5793 
        List<ECM_Sales_Driver_Item_Detail__c> sdidToDelete = new List<ECM_Sales_Driver_Item_Detail__c>();
        for(ECM_Sales_Driver_Item_Detail__c salesDetails:[SELECT Id,Name,ECM_Product__c,ECM_Investment_Amount__c,ECM_Sales_Driver_Item__c,
                                                          ECM_Product__r.ECM_Investment__c,ECM_Sales_Driver_Item__r.Contract__c,ECM_Addendum__c,ECM_Addendum__r.ECM_Status__c,
                                                          ECM_Product__r.ECM_Product_Name__c,ECM_Delivery_Date_Month__c,ECM_Delivery_Date_Year__c,ECM_Activity_Type_Description__c,
                                                          ECM_MustDo__c,ECM_MustDo__r.Name,ECM_Activation_Spend_SubGroup__c,ECM_Activation_Spend_SubGroup__r.Name,
                                                          ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Applied_To_All__c,ECM_Product__r.ECM_Product__r.Product__r.Sub_Category_Formula__c
                                                          FROM ECM_Sales_Driver_Item_Detail__c 
                                                          WHERE ECM_Sales_Driver_Item__r.Contract__c=:conRecord.Id AND RecordTypeId=:sdidRecordTypeId WITH SECURITY_ENFORCED]){
                                                              if(salesDetails.ECM_Product__c != null){
                                                                  if(sdiAndSDIDMap.containskey(salesDetails.ECM_Sales_Driver_Item__c)){
                                                                      sdiAndSDIDMap.get(salesDetails.ECM_Sales_Driver_Item__c).add(salesDetails);
                                                                  }else{ 
                                                                      sdiAndSDIDMap.put(salesDetails.ECM_Sales_Driver_Item__c,new List<ECM_Sales_Driver_Item_Detail__c>{salesDetails});
                                                                  }
                                                                  sdidConIdMap.put(salesDetails.Id,salesDetails.ECM_Product__c);
                                                              } else{
                                                                  sdidToDelete.add(salesDetails);
                                                              }
                                                          }
        //ECM-6602/ECM-6618
        if(!sdidToDelete.isEmpty() && Schema.sObjectType.ECM_Sales_Driver_Item_Detail__c.isDeletable()){
            Delete sdidToDelete;                       
        }
        //Added ECM_Is_Cloned__c as a part of ECM-6310 
        //155930
        sdiMap = new Map<Id,ECM_Sales_Driver_Item__c>([SELECT Id, Name,ECM_Sales_Driver_Name__c,ECM_Range__c,ECM_Sales_Driver__c,ECM_1st_Prepayment_Date__c,
                                                       ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,
                                                       ECM_Investement_Description__c,ECM_Prepayment__c,ECM_Investment_Yr1__c,
                                                       ECM_Investment_Yr2__c,ECM_Investment_Yr3__c,ECM_Payment_Date_Yr1__c,
                                                       ECM_Payment_Date_Yr2__c,ECM_Payment_Date_Yr3__c,ECM_1st_Prepayment_Amount__c,
                                                       ECM_Remaining_Payment_Frequency__c,ECM_Payment_Date__c,ECM_Sales_Driver__r.RecordTypeId,
                                                       ECM_Budget_Type__c,ECM_Sales_Driver__r.Name,
                                                       ECM_Sales_Driver__r.ECM_Applied_To_All__c,ECM_Sales_Driver__r.ECM_Automatic_Amount_Split__c , ECM_Sales_Driver__r.ECM_Hide_Total_Amount__c,
                                                       ECM_Sales_Driver__r.ECM_Multi_Use__c,ECM_Sales_Driver__r.ECM_Default__c,ECM_Is_Cloned__c, 
                                                       ECM_Total_Investment_Amount__c,Contract__c,ECM_Payment_Via_SAP__c,
                                                       ECM_Sales_Driver__r.ECM_Product_Sub_Category__r.Name,
                                                       ECM_Sales_Driver__r.Sales_driver_Product_Filter__c
                                                       FROM ECM_Sales_Driver_Item__c 
                                                       WHERE Contract__c=:conRecord.Id AND RecordTypeId=:sdiRecordTypeId]);
        
        //ECM-5237
        for(ECM_Sales_Driver_Item__c sdiObj : sdiMap.values()){
            for(ECM_Contract_Item__c conItemObj : conItemMap.values()){
                Boolean isOld = false;
                
                if(!sdiAndSDIDMap.isEmpty() && sdiAndSDIDMap.containsKey(sdiObj.Id)){
                    for(ECM_Sales_Driver_Item_Detail__c sdidObj : sdiAndSDIDMap.get(sdiObj.Id)){
                        if(!sdidConIdMap.isEmpty() && sdidConIdMap.containsKey(sdidObj.Id) && sdidConIdMap.get(sdidObj.Id)!= null && sdidConIdMap.get(sdidObj.Id).equals(conItemObj.Id)){
                            isOld = true;
                            break;
                        }
                    }
                    if(((!isOld && !isAddendum)||(test.isRunningTest()))){
                        ECM_Sales_Driver_Item_Detail__c newSDIDObj = new ECM_Sales_Driver_Item_Detail__c(); 
                        newSDIDObj.ECM_Product__c = conItemObj.Id;
                        newSDIDObj.ECM_Sales_Driver_Item__c = sdiObj.Id;
                        newSDIDObj.RecordTypeId = sdidRecordTypeId;
                        newSDIDObj.ECM_Investment_Amount__c = 0;
                        newSDIDList.add(newSDIDObj);
                    }
                }
            }
        }
        if(!newSDIDList.isEmpty()){
            isInsert = true;
            //ECM-6337
            Database.SaveResult[] srList = Database.insert(newSDIDList);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    additionalSDIDs.add(sr.getId());
                }
            }
            sdiAndSDIDMap.clear();
        }
        if(isInsert){
            for(ECM_Sales_Driver_Item_Detail__c salesDetails:[SELECT Id,Name,ECM_Product__c,ECM_Investment_Amount__c,ECM_Sales_Driver_Item__c,
                                                              ECM_Product__r.ECM_Investment__c,ECM_Sales_Driver_Item__r.Contract__c,ECM_Addendum__c,ECM_Addendum__r.ECM_Status__c,
                                                              ECM_Product__r.ECM_Product_Name__c,ECM_Delivery_Date_Month__c,ECM_Delivery_Date_Year__c,ECM_Activity_Type_Description__c,
                                                              ECM_MustDo__c,ECM_MustDo__r.Name,ECM_Activation_Spend_SubGroup__c,ECM_Activation_Spend_SubGroup__r.Name,
                                                              ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Applied_To_All__c,ECM_Product__r.ECM_Product__r.Product__r.Sub_Category_Formula__c
                                                              FROM ECM_Sales_Driver_Item_Detail__c 
                                                              WHERE ECM_Sales_Driver_Item__r.Contract__c=:conRecord.Id AND RecordTypeId=:sdidRecordTypeId AND ECM_Product__c != null WITH SECURITY_ENFORCED]){
                                                                  if(sdiAndSDIDMap.containskey(salesDetails.ECM_Sales_Driver_Item__c)){
                                                                      sdiAndSDIDMap.get(salesDetails.ECM_Sales_Driver_Item__c).add(salesDetails);
                                                                  }else{ 
                                                                      sdiAndSDIDMap.put(salesDetails.ECM_Sales_Driver_Item__c,new List<ECM_Sales_Driver_Item_Detail__c>{salesDetails});
                                                                  }
                                                              } 
        }
        Boolean aplToAll;
        for(ECM_Sales_Driver_Item__c sdiObj : sdiMap.values()){
            List<ECM_CreateContractController.salesdriverItemDetailsWrap> listSalesDetails = new List<ECM_CreateContractController.salesdriverItemDetailsWrap>();
            ECM_CreateContractController.salesdriverItemWrap salesWrap = new ECM_CreateContractController.salesdriverItemWrap();
            ECM_CreateContractController.salesdriveritems salesItem = new ECM_CreateContractController.salesdriveritems();
            salesitem.Name = sdiObj.ECM_Range__c!=Null?sdiObj.ECM_Sales_Driver__r.Name+'-'+sdiObj.ECM_Range__c:sdiObj.ECM_Sales_Driver_Name__c;
            salesItem.SalesDriver = sdiObj.ECM_Sales_Driver__c;
            salesItem.DriverRange = Integer.valueof(sdiObj.ECM_Range__c);
            salesItem.DriverType = sdiObj.ECM_Sales_Driver__r.RecordTypeId;
            salesItem.Drivername = sdiObj.Name;
            salesItem.BudjectType = sdiObj.ECM_Budget_Type__c;
            salesItem.applied = sdiObj.ECM_Sales_Driver__r.ECM_Applied_To_All__c;
            salesItem.MultiUse = sdiObj.ECM_Sales_Driver__r.ECM_Multi_Use__c;
            salesItem.AutomaticAmountSplit = sdiObj.ECM_Sales_Driver__r.ECM_Automatic_Amount_Split__c;
            salesItem.HideTotalAmount = sdiObj.ECM_Sales_Driver__r.ECM_Hide_Total_Amount__c;
            //CUS-123
            salesItem.productSubCategory = sdiObj.ECM_Sales_Driver__r.ECM_Product_Sub_Category__c!=null?
                sdiObj.ECM_Sales_Driver__r.ECM_Product_Sub_Category__r.Name.substringBefore('[').trim():'';
            //155930
            salesItem.productFilter = sdiObj.ECM_Sales_Driver__r.Sales_driver_Product_Filter__c!=null?
                sdiObj.ECM_Sales_Driver__r.Sales_driver_Product_Filter__c:'';
            salesItem.Id = sdiObj.Id;
            saleswrap.saledrive = salesItem;
            saleswrap.salesDriver = sdiObj;
            saleswrap.totalInvest = sdiObj.ECM_Total_Investment_Amount__c;
            saleswrap.paymentId = sdiObj.ECM_Payment_Frequency__r.ECM_Type__c;
            //155930
            saleswrap.yearLst = fyYears;
            
            //saleswrap.paymentFreqDisplayName = sdiObj.get('payFreqTypeLabel').toString();
            if(sdiAndSDIDMap.size()>0 && sdiAndSDIDMap.containskey(sdiObj.Id)){
                for(ECM_Sales_Driver_Item_Detail__c salesdetails : sdiAndSDIDMap.get(sdiObj.Id)){
                    if(salesdetails.ECM_Product__c!=Null){
                        ECM_CreateContractController.salesdriverItemDetailsWrap salesdetailswrap = new ECM_CreateContractController.salesdriverItemDetailsWrap();
                        salesdetailswrap.productname = conItemMap.get(salesdetails.ECM_Product__c);
                        salesdetailswrap.investment = salesdetails.ECM_Investment_Amount__c;//ECM_Product__r.ECM_Investment__c; 
                        aplToAll = salesdetails.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Applied_To_All__c; //ECM-6602/ECM-6618
                        //156533
						//156646 -  productFilter to work on edit & create
                        salesdetailswrap.selectedProductcheck = (!isNew && additionalSDIDs.contains(salesdetails.Id) && salesdetails.ECM_Investment_Amount__c==0 && !aplToAll)
                            || (additionalSDIDs.contains(salesdetails.Id) && salesItem.productFilter!='' && salesdetails.ECM_Investment_Amount__c==0)
                            ?false:true;//ECM-6337 change
                        salesdetailswrap.salesDriverDetails = salesdetails;
                        //Added for ECM-5439->start
                        salesdetailswrap.monthSDID = salesdetails.ECM_Delivery_Date_Month__c;
                        salesdetailswrap.yearSDID = salesdetails.ECM_Delivery_Date_Year__c;
                        salesdetailswrap.yearLst = fyYears;
                        salesdetailswrap.activationSpendSubGroup.Id= salesdetails.ECM_Activation_Spend_SubGroup__c;
                        salesdetailswrap.activationSpendSubGroup.Name= salesdetails.ECM_Activation_Spend_SubGroup__r.Name;
                        salesdetailswrap.mustDoRecord.Id= salesdetails.ECM_MustDo__c;
                        salesdetailswrap.mustDoRecord.Name= salesdetails.ECM_MustDo__r.Name;
                        salesdetailswrap.activationTypeDesc= salesdetails.ECM_Activity_Type_Description__c;
                        //Added for ECM-5439->End
                        //system.debug('details='+salesDriverMap.get(salesdetails.ECM_Product__c).ECM_Investment__c);
                        //ECM-5793
                        if(contractStatusCheck[1].containsignorecase(conRecord.Status) &&
                           (salesdetails.ECM_Addendum__c==null ||
                            (salesdetails.ECM_Addendum__c!=null && 
                             addendumStatusCheck[1].containsIgnoreCase(salesdetails.ECM_Addendum__r.ECM_Status__c)))){
                                 salesdetailswrap.toBeDisabled=true;
                             }
                        else if(contractStatusCheck[1].containsignorecase(conRecord.Status) &&
                                (salesdetails.ECM_Addendum__c==null || 
                                 (salesdetails.ECM_Addendum__c!=null&&
                                  addendumStatusCheck[0].containsIgnoreCase(salesdetails.ECM_Addendum__r.ECM_Status__c)))){
                                      salesdetailswrap.toBeDisabled=false;
                                  }
                        else{
                            salesdetailswrap.toBeDisabled=false;
                        }
                        salesdetailswrap.hasAddendum = salesdetails.ECM_Addendum__c!=null?true:false;
                        salesdetailswrap.hasAddendumId = salesdetails.ECM_Addendum__c!=null?String.valueOf(salesdetails.ECM_Addendum__c):'null';
                        salesdetailswrap.addendumStatus = salesdetails.ECM_Addendum__c!=null?salesdetails.ECM_Addendum__r.ECM_Status__c:'null';
                        System.debug(LoggingLevel.DEBUG,'Addendum  '+conRecord.Status+' '+salesdetails.ECM_Addendum__c);
                        listSalesDetails.add(salesdetailswrap);
                    }
                }
            }
            saleswrap.saledriveItemDetailsWrapList = listsalesdetails;
            wrapperList.add(saleswrap);
        }
        return wrapperList;
    }
    @AuraEnabled
    Public static void removeSalesDriver(string salesdriverId){
        system.debug(LoggingLevel.DEBUG,'test sales'+salesdriverId);
        ECM_Sales_Driver_Item__c salesdriverItem = [select Id, (select Id from Sales_Driver_Item_Details__r) 
                                                    From ECM_Sales_Driver_Item__c where Id=:salesdriverId WITH SECURITY_ENFORCED];
        
        If(salesdriverItem.Sales_Driver_Item_Details__r.Size()>0){
            Delete salesdriverItem.Sales_Driver_Item_Details__r;
        }
        if(salesdriverItem!=Null && Schema.sObjectType.ECM_Sales_Driver_Item__c.isDeletable()){
            delete salesdriverItem;
        }        
        
    }
    //Re-usable method as part of ECM-4908     
    public static string salesdriverDescription(ECM_Sales_Driver_Item__c salesItem){
        string descript='';
        if(salesItem.ECM_Investment_Yr1__c!= Null && salesItem.ECM_Payment_Date_Yr1__c!=Null){
            descript = ' Yr 1- Investment:'+salesItem.ECM_Investment_Yr1__c+' | Payment Date:'+salesItem.ECM_Payment_Date_Yr1__c.format();
        }    
        if(salesItem.ECM_Investment_Yr2__c!= Null && salesItem.ECM_Payment_Date_Yr2__c!=Null){
            descript += ', Yr 2- Investment:'+salesItem.ECM_Investment_Yr2__c+' | Payment Date:'+salesItem.ECM_Payment_Date_Yr2__c.format();
        }
        if(salesItem.ECM_Investment_Yr3__c!= Null && salesItem.ECM_Payment_Date_Yr3__c!=Null){
            descript += ', Yr 3- Investment:'+salesItem.ECM_Investment_Yr3__c+' | Payment Date:'+salesItem.ECM_Payment_Date_Yr3__c.format();
        }
        system.debug(LoggingLevel.DEBUG,'descript '+descript );
        return descript;
    }
    
    @AuraEnabled
    Public static List<salesdriverItemWrap> processSalesDriversToInsert(string listsalesDrivers, Contract contractDetails){
        system.debug(LoggingLevel.DEBUG,'listsalesDrivers'+listsalesDrivers);
        system.debug(LoggingLevel.DEBUG,'Contract Record='+contractDetails);
        List<salesdriverItemWrap> returnwrapperList = new List<salesdriverItemWrap>();
        List<salesdriverItemWrap> wrapperList;
        //Map<string,List<ECM_Sales_Driver_Item_Detail__c>> upsertconItemWithSalesdriverDetails = new  Map<string,List<ECM_Sales_Driver_Item_Detail__c>>();
        Map<string,ECM_Sales_Driver_Item__c> upsertContrctWithSalesdriverDetails = new  Map<string,ECM_Sales_Driver_Item__c>();
        List<ECM_Sales_Driver_Item_Detail__c> listsalesDriverItemDetails = new List<ECM_Sales_Driver_Item_Detail__c>();
        List<ECM_Sales_Driver_Item_Detail__c> listsalesDriverItemDetailsToDelete = new List<ECM_Sales_Driver_Item_Detail__c>();
        Map<string,ECM_Sales_Driver_Item__c> listsalesDriverItems = new Map<string,ECM_Sales_Driver_Item__c>();
        system.debug(LoggingLevel.DEBUG,'==sales'+listsalesDrivers);
        //changes related to ECM-5210
        Id sdiRecordTypeId;
        Id sdidRecordTypeId;
        String sdRecordTypeName = 'Sales Driver';
        String asRecordTypeName = 'Activation Spend';
        ECM_Contract_Type__c ecmContractType = [SELECT id,ECM_Activation_Spend__c FROM ECM_Contract_Type__c where id=:contractDetails.ECM_Agreement_Type__c  WITH SECURITY_ENFORCED limit 1];
        //ECM-5865
        List<ECM_Addendum__c> addendumObj = new List<ECM_Addendum__c>([SELECT Id FROM ECM_Addendum__c WHERE ECM_Contract__c=:contractDetails.Id AND ECM_Status__c='Draft']);
        if(ecmContractType.ECM_Activation_Spend__c &&
           (contractDetails.ECM_Last_saved_page__c==6 || contractDetails.ECM_Last_saved_page__c==4)&&
           addendumObj.isEmpty()){
               system.debug(LoggingLevel.DEBUG,'last screen Activation Spend');
               sdiRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item__c').getDescribe().getRecordTypeInfosByName().get(AsRecordTypeName).getRecordTypeId();
               sdidRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item_Detail__c').getDescribe().getRecordTypeInfosByName().get(AsRecordTypeName).getRecordTypeId();
           }else{
               system.debug(LoggingLevel.DEBUG,'last screen Sales driver');
               sdiRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item__c').getDescribe().getRecordTypeInfosByName().get(SdRecordTypeName).getRecordTypeId();
               sdidRecordTypeId = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item_Detail__c').getDescribe().getRecordTypeInfosByName().get(SdRecordTypeName).getRecordTypeId();
           } 
        //end of changes related to ECM-5210
        /*  system.debug('ECM_Last_saved_page__c'+contractDetails.ECM_Last_saved_page__c);
String SALESDRIVER_RECORDTYPE = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item__c').getDescribe().getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
String SALESDRIVERDETAIL_RECORDTYPE = Schema.getGlobalDescribe().get('ECM_Sales_Driver_Item_Detail__c').getDescribe().getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
*/
        //ECM-4205
        //MAP<Id,ECM_Contract_Item__c> updateConItems = new MAP<Id,ECM_Contract_Item__c>();
        if(listsalesDrivers==Null || listsalesDrivers==''){
            wrapperList = new List<salesdriverItemWrap>();
        }else{
            wrapperList = (List<salesdriverItemWrap>)JSON.deserialize(listsalesDrivers, List<salesdriverItemWrap>.class);
        }
        System.debug(LoggingLevel.DEBUG,'----- wrapperList -----'+wrapperList);
        //set<Id> contractIds = new Set<Id>();  
        //ECM-4889: Added new fields to the query
        Map<Id,ECM_Sales_Driver_Item__c> upsertSalesDriverItems = new Map<Id,ECM_Sales_Driver_Item__c>([select Id, Name,ECM_Sales_Driver_Name__c,ECM_Range__c,ECM_Sales_Driver__c,ECM_1st_Prepayment_Date__c,ECM_Remaining_Payment_Date__c,
                                                                                                        ECM_Sales_Driver__r.ECM_Activation_Spend_Sub_Group__r.Name, ECM_Sales_Driver__r.ECM_Activation_Spend_Sub_Group__r.Id,
                                                                                                        ECM_Investement_Description__c,ECM_1st_Prepayment_Amount__c,ECM_Investment_Yr1__c,ECM_Investment_Yr2__c,ECM_Investment_Yr3__c,ECM_Payment_Date_Yr1__c,ECM_Payment_Date_Yr2__c,ECM_Payment_Date_Yr3__c,ECM_Prepayment__c,ECM_Remaining_Payment_Frequency__c,ECM_Sales_Driver__r.RecordTypeId,ECM_Budget_Type__c,ECM_Payment_Frequency__c,
                                                                                                        ECM_Payment_Frequency__r.ECM_Type__c,ECM_Total_Investment_Amount__c,Contract__c, (select Id,Name,ECM_Product__c,ECM_Investment_Amount__c,ECM_Sales_Driver_Item__c,ECM_Product__r.ECM_Investment__c,
                                                                                                                                                                                          ECM_Product__r.ECM_Product_Name__c from Sales_Driver_Item_Details__r) 
                                                                                                        From ECM_Sales_Driver_Item__c where Contract__c=:contractDetails.Id AND RecordTypeId=:sdiRecordTypeId]);
        system.debug(LoggingLevel.DEBUG,'pre sales '+upsertSalesDriverItems);
        for(salesdriverItemWrap saleswrap : wrapperList){
            system.debug(LoggingLevel.DEBUG,'id is '+saleswrap.salesDriver.Id);
            if(upsertSalesDriverItems.Size()>0 && saleswrap.salesDriver.Id!=Null && upsertSalesDriverItems.containskey( Id.valueOf(saleswrap.salesDriver.Id))){
                ECM_Sales_Driver_Item__c salesItem = saleswrap.salesDriver;
                salesItem.RecordTypeId = sdiRecordTypeId;
                salesItem.ECM_Total_Investment_Amount__c = saleswrap.totalInvest;
                //ECM-5239
                salesItem.ECM_Payment_Date__c = saleswrap.salesDriver.ECM_Payment_Date__c;
                salesItem.ECM_1st_Prepayment_Date__c = saleswrap.salesDriver.ECM_1st_Prepayment_Date__c;
                salesItem.ECM_Remaining_Payment_Date__c = saleswrap.salesDriver.ECM_Remaining_Payment_Date__c;
                salesItem.ECM_Investement_Description__c = saleswrap.salesDriver.ECM_Investement_Description__c;
                salesItem.ECM_Investment_Yr1__c = saleswrap.salesDriver.ECM_Investment_Yr1__c;
                salesItem.ECM_Payment_Date_Yr1__c = saleswrap.salesDriver.ECM_Payment_Date_Yr1__c;
                salesItem.ECM_1st_Prepayment_Date__c = saleswrap.salesDriver.ECM_1st_Prepayment_Date__c;
                salesItem.ECM_Prepayment__c = saleswrap.salesDriver.ECM_Prepayment__c;
                salesItem.ECM_Investment_Yr2__c = saleswrap.salesDriver.ECM_Investment_Yr2__c;
                salesItem.ECM_Payment_Date_Yr2__c = saleswrap.salesDriver.ECM_Payment_Date_Yr2__c;
                salesItem.ECM_Investment_Yr3__c = saleswrap.salesDriver.ECM_Investment_Yr3__c;
                salesItem.ECM_Payment_Date_Yr3__c = saleswrap.salesDriver.ECM_Payment_Date_Yr3__c;
                
                if(salesItem.ECM_Prepayment__c == null){
                    salesItem.ECM_1st_Prepayment_Amount__c =  null;
                }
                
                //ECM-5239 end
                
                //added as part of ECM-4908
                //salesItem.ECM_Investement_Description__c = salesdriverDescription(salesItem);
                //added as part of ECM-5182
                salesItem.ECM_Investement_Description__c = (saleswrap.salesDriver.ECM_Payment_Frequency__r!=Null && saleswrap.salesDriver.ECM_Payment_Frequency__r.ECM_Type__c=='Single Yearly Payments')?salesdriverDescription(salesItem):saleswrap.salesDriver.ECM_Investement_Description__c;
                upsertContrctWithSalesdriverDetails.put(salesItem.Id,salesItem);
                listsalesDriverItems.put(saleswrap.saledrive.Drivername+'-'+saleswrap.saledrive.Id,salesItem);
            }else{
                system.debug(LoggingLevel.DEBUG,'salesItem='+saleswrap);
                system.debug(LoggingLevel.DEBUG,'salesItem='+saleswrap.salesDriver);
                ECM_Sales_Driver_Item__c salesItem = saleswrap.salesDriver;//Drivername DriverRange SalesDriver DriverType Name applied BudjectType
                salesItem.ECM_Sales_Driver_Name__c = saleswrap.saledrive.Name;
                salesItem.RecordTypeId = sdiRecordTypeId;
                salesItem.ECM_Range__c = saleswrap.saledrive.DriverRange;
                salesItem.ECM_Sales_Driver__c = saleswrap.saledrive.SalesDriver; 
                salesItem.ECM_Total_Investment_Amount__c = saleswrap.totalInvest;
                salesItem.Contract__c = contractDetails.Id; 
                //added as part of ECM-4908              
                //salesItem.ECM_Investement_Description__c = salesdriverDescription(salesItem);
                //added as part of ECM-5182, added saleswrap.paymentId & saleswrap.salesDriver as a part of ECM-5432:BUG fix
                salesItem.ECM_Investement_Description__c = (saleswrap.salesDriver.ECM_Payment_Frequency__c!=Null && saleswrap.paymentId!=Null && saleswrap.paymentId=='Single Yearly Payments')?salesdriverDescription(saleswrap.salesDriver):saleswrap.salesDriver.ECM_Investement_Description__c;
                listsalesDriverItems.put(saleswrap.saledrive.Drivername+'-'+saleswrap.saledrive.Id,salesItem);
            }
        }
        System.debug(LoggingLevel.DEBUG,'listsalesDriverItems=='+listsalesDriverItems); 
        //system.debug('listsalesDriverItems=='+listsalesDriverItems);
        Database.upsert(listsalesDriverItems.values());
        System.debug(LoggingLevel.DEBUG,'id of delistsalesDriverItemstails='+listsalesDriverItems.values()); 
        //system.debug('id of delistsalesDriverItemstails='+listsalesDriverItems.values());
        for(salesdriverItemWrap saleswrap : wrapperList){
            salesdriverItemWrap salesdrivewraps = new salesdriverItemWrap();          
            if(upsertSalesDriverItems.Size()>0 && saleswrap.salesDriver.Id!=Null && upsertSalesDriverItems.containskey( Id.valueOf(saleswrap.salesDriver.Id))){
                ECM_Sales_Driver_Item__c salesdriverItem = upsertSalesDriverItems.get( Id.valueOf(saleswrap.salesDriver.Id));
                for(salesdriverItemDetailsWrap salesdetailswrap : saleswrap.saledriveItemDetailsWrapList){
                    if(salesdetailswrap.productname!= Null){
                        if(salesdetailswrap.selectedProductcheck){
                            ECM_Sales_Driver_Item_Detail__c salesDetails = salesdetailswrap.salesDriverDetails;    //ECM_Product__c,ECM_Investment_Amount__c,ECM_Sales_Driver_Item__c         
                            System.debug(LoggingLevel.DEBUG,'===salesdetailswrap.productname.Id==='+salesdetailswrap.productname.Id);
                            salesDetails.ECM_Product__c = salesdetailswrap.productname.Id;
                            salesDetails.ECM_Investment_Amount__c = salesdetailswrap.investment;//productname.ECM_Investment__c;
                            salesdriverItemDetailsWrap salesDriverItemDetails= new salesdriverItemDetailsWrap();
                            salesDriverItemDetails = salesdetailswrap;
                            salesDetails.RecordTypeId = sdidRecordTypeId;
                            //Added for ECM-5439->start
                            if(!String.isBlank(salesdetailswrap.mustDoRecord.Id)){
                                salesDetails.ECM_MustDo__c= salesdetailswrap.mustDoRecord.Id;
                            }
                            if((salesdetailswrap.activationSpendSubGroup.Id == null || salesdetailswrap.activationSpendSubGroup.Id == '')  && (contractDetails.ECM_Last_saved_page__c==6)){
                                salesDetails.ECM_Activation_Spend_SubGroup__c  = salesdriverItem.ECM_Sales_Driver__r.ECM_Activation_Spend_Sub_Group__r.Id;
                            }
                            else{
                                if(!String.isBlank(salesdetailswrap.activationSpendSubGroup.Id)){
                                    salesDetails.ECM_Activation_Spend_SubGroup__c  = salesdetailswrap.activationSpendSubGroup.Id;
                                }
                            }
                            salesDetails.ECM_Delivery_Date_Month__c = salesdetailswrap.monthSDID;//ECM-5452
                            salesDetails.ECM_Delivery_Date_Year__c = salesdetailswrap.yearSDID;
                            salesDetails.ECM_Activity_Type_Description__c= salesdetailswrap.activationTypeDesc;
                            //Added for ECM-5439->End
                            salesdrivewraps.saledriveItemDetailsWrapList.add(salesDriverItemDetails);
                            /*start of ECM-4205
if(updateConItems.containskey(salesdetailswrap.productname.Id)){
Decimal investment = updateConItems.get(salesdetailswrap.productname.Id).ECM_AnP_investment__c+salesdetailswrap.investment;
updateConItems.put(salesdetailswrap.productname.Id,new ECM_Contract_item__c(Id=salesdetailswrap.productname.Id,ECM_AnP_investment__c=investment));

}else{
updateConItems.put(salesdetailswrap.productname.Id,new ECM_Contract_item__c(Id=salesdetailswrap.productname.Id,ECM_AnP_investment__c=salesdetailswrap.investment));                                
}
//End of ECM-4205*/
                            listsalesDriverItemDetails.add(salesDetails);                    
                        }else{
                            ECM_Sales_Driver_Item_Detail__c salesDetails = salesdetailswrap.salesDriverDetails;
                            listsalesDriverItemDetailsToDelete.add(salesDetails);
                            system.debug(LoggingLevel.DEBUG,'==details'+salesdetailswrap);
                        } 
                    }
                    
                }
            }else{
                for(salesdriverItemDetailsWrap salesdetailswrap : saleswrap.saledriveItemDetailsWrapList){
                    if(salesdetailswrap.selectedProductcheck){
                        ECM_Sales_Driver_Item_Detail__c salesDetails = new ECM_Sales_Driver_Item_Detail__c();    //ECM_Product__c,ECM_Investment_Amount__c,ECM_Sales_Driver_Item__c         
                        //salesDetails = salesdetailswrap.salesDriverDetails;
                        salesDetails.ECM_Product__c = salesdetailswrap.productname.Id;
                        salesDetails.ECM_Investment_Amount__c = salesdetailswrap.investment;//productname.ECM_Investment__c; 
                        salesdrivewraps.saledrive = saleswrap.saledrive;
                        salesdrivewraps.salesDriver = saleswrap.salesDriver;
                        salesDetails.RecordTypeId = sdidRecordTypeId;
                        salesDetails.ECM_Sales_Driver_Item__c = listsalesDriverItems.get(saleswrap.saledrive.Drivername+'-'+saleswrap.saledrive.Id).Id;       
                        salesdriverItemDetailsWrap salesDriverItemDetails= new salesdriverItemDetailsWrap();
                        salesDriverItemDetails = salesdetailswrap;
                        
                        //Added for ECM-5439->start
                        if(!String.isBlank(salesdetailswrap.mustDoRecord.Id)){
                            salesDetails.ECM_MustDo__c= salesdetailswrap.mustDoRecord.Id;
                        }
                        if((salesdetailswrap.activationSpendSubGroup.Id == null || salesdetailswrap.activationSpendSubGroup.Id == '') && (contractDetails.ECM_Last_saved_page__c==6)){
                            salesDetails.ECM_Activation_Spend_SubGroup__c  = saleswrap.saledrive.activationSpendId;
                        }
                        else{
                            if(!String.isBlank(salesdetailswrap.activationSpendSubGroup.Id)){
                                salesDetails.ECM_Activation_Spend_SubGroup__c  = salesdetailswrap.activationSpendSubGroup.Id;
                            }
                        }
                        salesDetails.ECM_Delivery_Date_Month__c = salesdetailswrap.monthSDID;
                        salesDetails.ECM_Delivery_Date_Year__c = salesdetailswrap.yearSDID;
                        salesDetails.ECM_Activity_Type_Description__c= salesdetailswrap.activationTypeDesc;
                        //Added for ECM-5439->End
                        
                        salesdrivewraps.saledriveItemDetailsWrapList.add(salesDriverItemDetails);
                        /*start of ECM-4205
if(updateConItems.containskey(salesdetailswrap.productname.Id)){
Decimal investment = updateConItems.get(salesdetailswrap.productname.Id).ECM_AnP_investment__c+salesdetailswrap.investment;
updateConItems.put(salesdetailswrap.productname.Id,new ECM_Contract_item__c(Id=salesdetailswrap.productname.Id,ECM_AnP_investment__c=investment));

}else{
updateConItems.put(salesdetailswrap.productname.Id,new ECM_Contract_item__c(Id=salesdetailswrap.productname.Id,ECM_AnP_investment__c=salesdetailswrap.investment));                                
}   
//End of ECM-4205*/
                        listsalesDriverItemDetails.add(salesDetails);                    
                    }
                    
                }
            }
            returnwrapperList.add(salesdrivewraps);
        }
        if(listsalesDriverItemDetailsToDelete.size()>0 && Schema.sObjectType.ECM_Sales_Driver_Item_Detail__c.isDeletable()){
            Delete listsalesDriverItemDetailsToDelete;
        }
        /*ECM-4205
if(updateConItems.size()>0){
Database.upsert(updateConItems.values());
}*/
        system.debug(LoggingLevel.DEBUG,'Item records='+listsalesDriverItemDetails);  
        if(listsalesDriverItemDetails.size()>0 && Schema.sObjectType.ECM_Sales_Driver_Item_Detail__c.isCreateable()
           && Schema.sObjectType.ECM_Sales_Driver_Item_Detail__c.isUpdateable()){
               Database.upsert(listsalesDriverItemDetails);
           }   
        //system.debug('returnwrapperList  ='+returnwrapperList);
        // savecontract(contractDetails);
        return returnwrapperList;
    }
    
    /*
* @description : This method handles logic for populating values in Previous Contract dropdown on the 
last screen of Contract Creation as a part of ECM-5497
* @return : conWrapper
* @param : contract id
*/  
    //ECM-5620
    @AuraEnabled
    public static ConWrapper displayPrevCon(Contract con){
        Boolean displayCon;
        Boolean outletType;
        Boolean groupType;
        
        List<Contract> prevConListInclYrChck = new List<Contract>();
        Map<Id,String> drpdownMap = new Map<Id,String>();
        List<Contract> conList = [SELECT Id,name,AccountId,ECM_Agreement_Type__c,ContractNumber,Status,StartDate,Contract_End_Date__c,RecordType.Name,ECM_Outlets_selected__c,
                                  ECM_CTD_Overall_Investment__c,ECM_CTD_Total_A_P_Investment__c,ECM_CTD_Total_GP__c,ECM_Total_Indirect_Investment__c,ECM_CTD_CAAP_ROI__c,ECM_CTD_Total_NSV__c,
                                  ECM_Agreement_Type__r.ECM_Activation_Spend__c,ECM_CTD_Overall_Invst_incl_Indirect_Inv__c
                                  FROM Contract WHERE AccountId =: con.AccountId AND ECM_Agreement_Type__c =: con.ECM_Agreement_Type__c AND Contract_End_Date__c <TODAY 
                                  AND Status = 'Closed' WITH SECURITY_ENFORCED]; //ECM-5620
        Integer thresholdDate = System.today().year()-3;
        for(Contract con1:conList){
            if(con1.Contract_End_Date__c.year() >= thresholdDate){
                prevConListInclYrChck.add(con1);
                Integer sy = con1.StartDate.year();
                Integer sm = con1.StartDate.month();
                Integer sd = con1.StartDate.day();
                DateTime dt = DateTime.newInstance(sy,sm,sd);
                Integer ey = con1.Contract_End_Date__c.year();
                Integer em = con1.Contract_End_Date__c.month();
                Integer ed = con1.Contract_End_Date__c.day();
                DateTime edt = DateTime.newInstance(ey,em,ed);
                String str = 'Contract '+con1.ContractNumber+' '+dt.format('MMMM')+' '+con1.StartDate.year()+' - '+edt.format('MMMM')+' '+con1.Contract_End_Date__c.year();
                drpdownMap.put(con1.Id,str);
            }
        }
        
        if(prevConListInclYrChck.size()<=0){
            displayCon = true;
        }else{
            displayCon = false;
        }
        if(con.RecordType.Name == 'Outlet'){
            outletType = true;
            groupType = false;
        }else if(con.RecordType.Name == 'Group'){
            outletType = false;
            groupType = true;
        }
        
        ConWrapper conWrap = new ConWrapper();
        conWrap.displayCon = displayCon;
        conWrap.outletType = outletType;
        conWrap.groupType = groupType;
        conwrap.conList = prevConListInclYrChck;
        conwrap.drpdownMap = drpdownMap;       
        return conWrap;
    }
    //Using this Wrapper to Send the List of Previous Contracts in Last Screen
    public class ConWrapper{
        @AuraEnabled 
        public boolean displayCon {get;set;}
        @AuraEnabled 
        public boolean outletType {get;set;}
        @AuraEnabled 
        public boolean groupType {get;set;}
        @AuraEnabled 
        public List <Contract> conList {get;set;}
        @AuraEnabled 
        public Map <Id,String> drpdownMap {get;set;}                
    }
    
    /*
* Name : loadvalues
* @description : This method loads values to be used in screen-5 calculations
* @return : Wrapper with List<ECM_Contract_Item__c>,Total Brand Marketing A&P and Total Customer Marketing A&P 
* @param : Contract Id
*/
    @AuraEnabled
    public static conItemInvWrapper loadvalues(string contractid){
        Set<ECM_Contract_Item__c> setSDIWB = new Set<ECM_Contract_Item__c>();
        List <ECM_Contract_Item__c> listSDIWB = new List <ECM_Contract_Item__c>();
        List<ECM_Sales_Driver_Item_Detail__c> sdiAndPinvestment = [SELECT Id,ECM_Budget_Type__c,ECM_Investment_Amount__c,ECM_Product__c,
                                                                   ECM_Sales_Driver_Item__r.Contract__c,RecordTypeId,
                                                                   ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Activation_Spend_Sub_Group__r.Name,
                                                                   ECM_Activation_Spend_SubGroup__r.Name,ECM_Sales_Driver_Item__r.ECM_Investement_Description__c,
                                                                   ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name,ECM_Sales_Driver_Item__c,
                                                                   toLabel(ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c),ECM_Sales_Driver_Item__r.ECM_Payment_Via_SAP__c
                                                                   FROM ECM_Sales_Driver_Item_Detail__c
                                                                   WHERE ECM_Sales_Driver_Item__r.Contract__c =: contractid AND ECM_Budget_Type__c!=NULL AND ECM_Product__c!=NULL WITH SECURITY_ENFORCED];//ECM-5762 Added ECM_Activation_Spend_SubGroup__r.Name in query
        Map<Id,Decimal> contractAandPmap = new Map<Id,Decimal>();
        Map<Id,Decimal> contractTImap = new Map<Id,Decimal>();
        Map<Id,Decimal> contractIndirecInvMap = new Map<Id,Decimal>();
        Map<Id,String> contractAnPName = new Map<Id,String>();
        Map<Id,String> contractTIName = new Map<Id,String>();
        Map<Id,String> contractAnPPF = new Map<Id,String>();
        Map<Id,String> contractTIPF = new Map<Id,String>();
        Map<Id,String> contractAnpInfo = new Map<Id,String>();
        Map<Id,String> contractTIInfo = new Map<Id,String>();
        Map<Id,Decimal> contractAnPIndirmap = new Map<Id,Decimal>();//ECM-6602
        
        Decimal totalBrandMarketingAnP = 0;
        Decimal totalCustomerMarketingAnP = 0;
        //ECM-5443
        Decimal totalIndirectTI = 0;
        Decimal totalIndirectAnP = 0;
        Id sdidASRecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();
        Id sdidSDRecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        for(ECM_Sales_Driver_Item_Detail__c sdItemRec : sdiAndPinvestment ){
            //String indirectBudgetType = sdItemRec.ECM_Budget_Type__c.substringBefore('[');
            Decimal sdItemInv = (sdItemRec.ECM_Investment_Amount__c != Null)? sdItemRec.ECM_Investment_Amount__c : 0;
            String sdName = (sdItemRec.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name != Null)?sdItemRec.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.Name : '';
            String pfName = (sdItemRec.ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c != Null)?sdItemRec.ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c : '';
            String infoName = (sdItemRec.ECM_Sales_Driver_Item__r.ECM_Investement_Description__c != Null)?sdItemRec.ECM_Sales_Driver_Item__r.ECM_Investement_Description__c : '';
            //Calculation starts for Investment Record Type of Sales Drivers
            //ECM-5442
            if(sdItemRec.ECM_Budget_Type__c.contains('A&P')){
                //ECM-6602
                if((sdItemRec.RecordTypeId == sdidSDRecId) || ((sdItemRec.RecordTypeId == sdidASRecId) && (sdItemRec.ECM_Sales_Driver_Item__r.ECM_Payment_Via_SAP__c))){
                    if(contractAnPIndirmap.containsKey(sdItemRec.ECM_Product__c)){                  
                        contractAnPIndirmap.put(sdItemRec.ECM_Product__c,sdItemInv + 
                                                (contractAnPIndirmap.get(sdItemRec.ECM_Product__c)!=Null?contractAnPIndirmap.get(sdItemRec.ECM_Product__c):0));
                    }
                    else{ 
                        contractAnPIndirmap.put(sdItemRec.ECM_Product__c,sdItemInv);       
                    }
                }
                //ECM-5443
                if(sdItemRec.RecordTypeId == sdidASRecId){
                    totalIndirectAnP+=sdItemInv;                  
                }
                else if(sdItemRec.RecordTypeId == sdidSDRecId){
                    if(contractAandPmap.containsKey(sdItemRec.ECM_Product__c)){                  
                        contractAandPmap.put(sdItemRec.ECM_Product__c,sdItemInv + 
                                             (contractAandPmap.get(sdItemRec.ECM_Product__c)!=Null?contractAandPmap.get(sdItemRec.ECM_Product__c):0));
                    }
                    else{ 
                        contractAandPmap.put(sdItemRec.ECM_Product__c,sdItemInv);       
                    }//ECM-6154 starts
                    if(contractAnPName.containsKey(sdItemRec.ECM_Product__c)){
                        contractAnPName.put(sdItemRec.ECM_Product__c,sdName + '/' + 
                                            (contractAnPName.get(sdItemRec.ECM_Product__c)!=''?contractAnPName.get(sdItemRec.ECM_Product__c):''));
                    }
                    else{
                        contractAnPName.put(sdItemRec.ECM_Product__c,sdName);
                    }
                    if(contractAnPPF.containsKey(sdItemRec.ECM_Product__c)){
                        contractAnPPF.put(sdItemRec.ECM_Product__c,pfName + '/' + 
                                          (contractAnPPF.get(sdItemRec.ECM_Product__c)!=''?contractAnPPF.get(sdItemRec.ECM_Product__c):''));
                    }
                    else{
                        contractAnPPF.put(sdItemRec.ECM_Product__c,pfName);
                    }
                    if(contractAnpInfo.containsKey(sdItemRec.ECM_Product__c)){
                        contractAnpInfo.put(sdItemRec.ECM_Product__c,infoName + '/' + 
                                            (contractAnpInfo.get(sdItemRec.ECM_Product__c)!=''?contractAnpInfo.get(sdItemRec.ECM_Product__c):''));
                    }
                    else{
                        contractAnpInfo.put(sdItemRec.ECM_Product__c,infoName);
                    }//ECM-6154 ends 
                }                 
            }
            else if(sdItemRec.ECM_Budget_Type__c.contains('TI')){
                //ECM-5443
                if(sdItemRec.RecordTypeId == sdidASRecId){
                    totalIndirectTI+=sdItemInv;                    
                }
                else if(sdItemRec.RecordTypeId == sdidSDRecId){
                    if(contractTImap.containsKey(sdItemRec.ECM_Product__c)){
                        contractTImap.put(sdItemRec.ECM_Product__c,sdItemInv + 
                                          (contractTImap.get(sdItemRec.ECM_Product__c)!=Null?contractTImap.get(sdItemRec.ECM_Product__c):0));
                    }
                    else{ 
                        contractTImap.put(sdItemRec.ECM_Product__c,sdItemInv);  
                    }//ECM-6154 starts
                    if(contractTIName.containsKey(sdItemRec.ECM_Product__c)){
                        contractTIName.put(sdItemRec.ECM_Product__c,sdName + '/' + 
                                           (contractTIName.get(sdItemRec.ECM_Product__c)!=''?contractTIName.get(sdItemRec.ECM_Product__c):''));                        
                    }
                    else{
                        contractTIName.put(sdItemRec.ECM_Product__c,sdName);                
                    }
                    if(contractTIPF.containsKey(sdItemRec.ECM_Product__c)){
                        contractTIPF.put(sdItemRec.ECM_Product__c,pfName + '/' + 
                                         (contractTIPF.get(sdItemRec.ECM_Product__c)!=''?contractTIPF.get(sdItemRec.ECM_Product__c):''));
                    }
                    else{
                        contractTIPF.put(sdItemRec.ECM_Product__c,pfName);
                    }
                    if(contractTIInfo.containsKey(sdItemRec.ECM_Product__c)){
                        contractTIInfo.put(sdItemRec.ECM_Product__c,infoName + '/' + 
                                           (contractTIInfo.get(sdItemRec.ECM_Product__c)!=''?contractTIInfo.get(sdItemRec.ECM_Product__c):''));
                    }
                    else{
                        contractTIInfo.put(sdItemRec.ECM_Product__c,infoName);
                    }//ECM-6154 ends 
                }                 
            }//Calculation starts for Activation Spend Record Type of Sales Drivers
            //ECM-5442            
            if(sdItemRec.RecordTypeId == sdidASRecId){
                if(String.isNotBlank(sdItemRec.ECM_Activation_Spend_SubGroup__r.Name)){
                    if(System.Label.ECM_Brand_Marketing_A_P.contains(sdItemRec.ECM_Activation_Spend_SubGroup__r.Name.substringBefore('['))){ //ECM-5762, //ECM_Activation_Spend_Sub_Group__c.contains('Brand Marketing A&P')
                        totalBrandMarketingAnP += sdItemInv; 
                    }
                    if(System.Label.ECM_Customer_Marketing_A_P.contains(sdItemRec.ECM_Activation_Spend_SubGroup__r.Name.substringBefore('['))){ //ECM-5762, //ECM_Activation_Spend_Sub_Group__c.contains('Customer Marketing A&P')
                        totalCustomerMarketingAnP += sdItemInv;                 
                    }     
                }              
                if(!contractIndirecInvMap.isEmpty() && contractIndirecInvMap.containsKey(sdItemRec.ECM_Product__c)){
                    contractIndirecInvMap.put(sdItemRec.ECM_Product__c,sdItemInv +
                                              (contractIndirecInvMap.get(sdItemRec.ECM_Product__c)!=Null?contractIndirecInvMap.get(sdItemRec.ECM_Product__c):0));
                }
                else{ 
                    contractIndirecInvMap.put(sdItemRec.ECM_Product__c,sdItemInv);  
                }
            }
        }
        String pfTIType = '';
        String[] pfTITypeArr ;
        Integer countTIPF = 0;
        Integer countTI = 0;
        Boolean hideInfo;
        String apInfo;        
        //Calculation Ends for Activation Spend Record Type of Sales Drivers
        for(ECM_Contract_Item__c conIt : [SELECT id,ECM_Product_Name__c,ECM_NSV_After_TI__c,ECM_Product__r.Product_Name__c,ECM_Total_GP_EU__c,ECM_GP_ROI_EU__c,ECM_Baseline_volume__c,ECM_Generated_NSV_EU__c,
                                          ECM_CAP_ROI_EU__c,ECM_NSV__c,ECM_Retro_investment__c,ECM_Gross_margin__c,ECM_AnP_investment__c,ECM_Trade_investments__c,
                                          ECM_Indirect_Investment__c,ECM_Gross_Profit__c,ECM_Contract__c,ECM_Trade_investment__c,ECM_Investment__c,ECM_Volume_Target_per_PF__c, 
                                          ECM_Volume__c,ECM_TI_Sales_Drivers__c,ECM_A_P_Sales_Drivers__c,ECM_TI_Payment_Frequencies__c,ECM_A_P_Payment_Frequencies__c,
                                          ECM_Contract__r.ECM_Agreement_Type__r.ECM_Hide_Information_Section__c,ECM_A_P_Information__c,ECM_TI_Information__c,ECM_TotalAnP_incl_Indirect__c
                                          FROM ECM_Contract_Item__c 
                                          WHERE ECM_Contract__c =: contractid ]){                                              
                                              ECM_Contract_Item__c conWrap = new ECM_Contract_Item__c();
                                              conWrap = conIt;
                                              conWrap.ECM_AnP_investment__c = (contractAandPmap.containskey(conIt.Id))?contractAandPmap.get(conIt.Id).setScale(2):0;
                                              conWrap.ECM_Trade_investments__c = (contractTImap.containskey(conIt.Id))?contractTImap.get(conIt.Id).setScale(2):0;
                                              conWrap.ECM_Indirect_Investment__c = (contractIndirecInvMap.containskey(conIt.Id))?contractIndirecInvMap.get(conIt.Id).setScale(2):0;
                                              conWrap.ECM_TotalAnP_incl_Indirect__c = (contractAnPIndirmap.containskey(conIt.Id))?contractAnPIndirmap.get(conIt.Id).setScale(2):0;//ECM-6602
                                              //ECM-6154 starts                                               
                                              String tiSalesDriv = (contractTIName.containsKey(conIt.Id))?contractTIName.get(conIt.Id):null;//ECM-6404
                                              if(String.isNotBlank(tiSalesDriv)){
                                                  conWrap.ECM_TI_Sales_Drivers__c = tiSalesDriv.length() >= 255 ?tiSalesDriv.substring(0,254):tiSalesDriv;                                                     
                                              }else{
                                                  conWrap.ECM_TI_Sales_Drivers__c = '';
                                              }
                                              String apSalesDriv = (contractAnPName.containsKey(conIt.Id))?contractAnPName.get(conIt.Id):null;//ECM-6404
                                              if(String.isNotBlank(apSalesDriv)){
                                                  conWrap.ECM_A_P_Sales_Drivers__c = apSalesDriv.length() >= 255 ?apSalesDriv.substring(0,254):apSalesDriv;                                                     
                                              }else{
                                                  conWrap.ECM_A_P_Sales_Drivers__c = '';
                                              }													
                                              if(contractTIPF.containsKey(conIt.Id)){                         
                                                  pfTIType = contractTIPF.get(conIt.Id);
                                                  pfTITypeArr = contractTIPF.get(conIt.Id).split('/');
                                                  countTIPF = (!pfTITypeArr.isEmpty())?pfTIType.countMatches(pfTITypeArr[0]):0;
                                                  countTI = (pfTIType!=null)?pfTIType.countMatches('/'):0;
                                                  String tiPfFreq = (countTI == (countTIPF-1))?pfTITypeArr[0]:pfTIType;//ECM-6404
                                                  if(String.isNotBlank(tiPfFreq)){
                                                      conWrap.ECM_TI_Payment_Frequencies__c = tiPfFreq.length() >= 255 ?tiPfFreq.substring(0,254):tiPfFreq;                                                     
                                                  }                                                                                         
                                              }else{
                                                  conWrap.ECM_TI_Payment_Frequencies__c = '';
                                              }
                                              if(contractAnPPF.containsKey(conIt.Id)){
                                                  pfTIType = contractAnPPF.get(conIt.Id);
                                                  pfTITypeArr = contractAnPPF.get(conIt.Id).split('/');
                                                  countTIPF = (!pfTITypeArr.isEmpty())?pfTIType.countMatches(pfTITypeArr[0]):0;
                                                  countTI = (pfTIType!=null)?pfTIType.countMatches('/'):0;
                                                  String apPfFreq = (countTI == (countTIPF-1))?pfTITypeArr[0]:pfTIType;//ECM-6404
                                                  if(String.isNotBlank(apPfFreq)){
                                                      conWrap.ECM_A_P_Payment_Frequencies__c = apPfFreq.length() >= 255 ?apPfFreq.substring(0,254):apPfFreq;                                                     
                                                  }                                                  	
                                              }else{
                                                  conWrap.ECM_A_P_Payment_Frequencies__c = '';
                                              }                                                                                           
                                              hideInfo = conWrap.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Hide_Information_Section__c;                                              
                                              if(contractAnpInfo.containsKey(conIt.Id)){
                                                  apInfo = contractAnpInfo.get(conIt.Id).length() >= 255 ?contractAnpInfo.get(conIt.Id).substring(0,254):contractAnpInfo.get(conIt.Id);
                                                  conWrap.ECM_A_P_Information__c = !(hideInfo)?apInfo:null;
                                              }else{
                                                  conWrap.ECM_A_P_Information__c = '';
                                              }
                                              if(contractTIInfo.containsKey(conIt.Id)){
                                                  apInfo = contractTIInfo.get(conIt.Id).length() >= 255 ?contractTIInfo.get(conIt.Id).substring(0,254):contractTIInfo.get(conIt.Id);
                                                  conWrap.ECM_TI_Information__c = !(hideInfo)?apInfo:null;
                                              }else{
                                                  conWrap.ECM_TI_Information__c = '';
                                              }//ECM-6154 ends 
                                              setSDIWB.add(conWrap);    
                                          }
        if(setSDIWB.size()>0){
            listSDIWB = new List <ECM_Contract_Item__c>(setSDIWB);
            upsert listSDIWB;
        }
        //newChange
        Decimal totalNSV = 0;
        for(ECM_Contract_Item__c conIt:[SELECT ECM_NSV_After_TI__c FROM ECM_Contract_Item__c WHERE ECM_Contract__c =: contractid]){
            totalNSV=totalNSV+(conIt.ECM_NSV_After_TI__c==null?0:conIt.ECM_NSV_After_TI__c);
        }
        List<Contract> conLst = [SELECT Id,ECM_Total_NSV__c FROM Contract WHERE Id=:contractid];
        conLst[0].ECM_Total_NSV__c = totalNSV;
        update conLst;
        List<ECM_Contract_Item__c> conItLst = [SELECT id,ECM_Product_Name__c,ECM_NSV_After_TI__c,ECM_Product__r.Product_Name__c,ECM_Total_GP_EU__c,ECM_GP_ROI_EU__c,ECM_Baseline_volume__c,ECM_Generated_NSV_EU__c,
                                               ECM_CAP_ROI_EU__c,ECM_NSV__c,ECM_Retro_investment__c,ECM_Gross_margin__c,ECM_AnP_investment__c,ECM_Trade_investments__c,
                                               ECM_Indirect_Investment__c,ECM_Gross_Profit__c,ECM_Contract__c,ECM_Trade_investment__c,ECM_Investment__c,ECM_Volume_Target_per_PF__c, 
                                               ECM_Volume__c,ECM_TI_Sales_Drivers__c,ECM_A_P_Sales_Drivers__c,ECM_TI_Payment_Frequencies__c,ECM_A_P_Payment_Frequencies__c,
                                               ECM_Contract__r.ECM_Agreement_Type__r.ECM_Hide_Information_Section__c,ECM_A_P_Information__c,ECM_TI_Information__c,ECM_TotalAnP_incl_Indirect__c
                                               FROM ECM_Contract_Item__c 
                                               WHERE ECM_Contract__c =: contractid];
        conItemInvWrapper invWrap = new conItemInvWrapper();
        invWrap.listSDIWB = conItLst;
        invWrap.totalBrandMarketingAnP = totalBrandMarketingAnP.setScale(2);
        invWrap.totalCustomerMarketingAnP = totalCustomerMarketingAnP.setScale(2);
        invWrap.totalIndirectTI = totalIndirectTI.setScale(2);//ECM-5443
        invWrap.totalIndirectAnP = totalIndirectAnP.setScale(2);
        return invWrap;
    }
    public class ConItemInvWrapper{//ECM-5252
        @AuraEnabled 
        public List <ECM_Contract_Item__c> listSDIWB {get;set;}
        @AuraEnabled 
        public Decimal totalBrandMarketingAnP {get;set;}
        @AuraEnabled
        public Decimal totalCustomerMarketingAnP {get;set;}
        //ECM-5443
        @AuraEnabled
        public Decimal totalIndirectTI {get;set;}
        @AuraEnabled
        public Decimal totalIndirectAnP {get;set;}
    }
    
    
    
    @AuraEnabled
    Public static List<ECM_Sales_Driver_Item__c> SalesdriversAU(string SalesDrivers,string conid){
        system.debug(LoggingLevel.DEBUG,'list'+SalesDrivers);
        system.debug(LoggingLevel.DEBUG,'conid++'+conid);
        List<salesdriveritems> wrapperList = (List<salesdriveritems>)JSON.deserialize(SalesDrivers, List<salesdriveritems>.class);
        // List<Sobject> SalesDriversObj =(List<Sobject>)JSON.deserialize(SalesDrivers,Sobject.class); 
        List<ECM_Sales_Driver_Item__c> insertSalesdriveitmlist = new List<ECM_Sales_Driver_Item__c>();
        Map<Id,ECM_Sales_Driver_Item__c> salesdriveitmlist = new Map<Id,ECM_Sales_Driver_Item__c>([SELECT Id,Contract__c, ECM_Sales_Driver_Name__c,ECM_Sales_Driver__c,
                                                                                                   ECM_Range__c,ECM_Sales_Driver__r.RecordTypeId,ECM_Sales_Driver__r.Name
                                                                                                   from ECM_Sales_Driver_Item__c where Contract__c =:conId]);
        system.debug(LoggingLevel.DEBUG,'wrapperList'+wrapperList);
        for(salesdriveritems salesitem : wrapperList){
            ECM_Sales_Driver_Item__c salesdriveobj = new ECM_Sales_Driver_Item__c();
            if(salesdriveitmlist.size()>0 && string.valueof(salesitem.Id).length()>3 && salesdriveitmlist.containsKey(id.valueof(salesitem.Id)) ){
                salesdriveobj.id = salesitem.Id;
            } 
            //Start- Added for ECM-5159
            else{
                salesdriveobj.Contract__c = conid;
            }
            //end- Added for ECM-5159
            salesdriveobj.ECM_Sales_Driver_Name__c = salesitem.Name!=Null?salesitem.Name:''; 
            salesdriveobj.ECM_Range__c = salesitem.DriverRange!=Null?salesitem.DriverRange:0;
            salesdriveobj.ECM_Sales_Driver__c = salesitem.SalesDriver;
            //salesdriveobj.Contract__c = conid;
            insertSalesdriveitmlist.add(salesdriveobj);
            
        }
        system.debug(LoggingLevel.DEBUG,'SalesDriversObj'+insertSalesdriveitmlist);   
        if(insertSalesdriveitmlist.Size()>0 && Schema.sObjectType.ECM_Sales_Driver_Item__c.isCreateable()
           && Schema.sObjectType.ECM_Sales_Driver_Item__c.isUpdateable()){
               Upsert insertSalesdriveitmlist;
           }
        // update salesdrivedetaillist;
        return insertSalesdriveitmlist;
    }
    @AuraEnabled
    public static list<salesdriveritems> salesdrivervaluesAU(string conId){
        List<salesdriveritems> returnwrapperLists = new List<salesdriveritems>();
        List<ECM_Sales_Driver_Item__c> salesdriveitmlist =  [SELECT Id,Contract__c, ECM_Sales_Driver_Name__c,ECM_Sales_Driver__c,
                                                             ECM_Range__c,ECM_Sales_Driver__r.RecordTypeId,ECM_Sales_Driver__r.Name
                                                             from ECM_Sales_Driver_Item__c where Contract__c =:conId WITH SECURITY_ENFORCED];
        System.debug(LoggingLevel.DEBUG,salesdriveitmlist);                                                     
        for(ECM_Sales_Driver_Item__c salesitem : salesdriveitmlist)
        {
            salesdriveritems salesdrivewrap = new salesdriveritems();
            salesdrivewrap.Id = salesitem.Id;
            if(salesitem.ECM_Range__c==0){
                salesdrivewrap.Name = salesitem.ECM_Sales_Driver__r.Name ;
            }
            else{
                salesdrivewrap.Name = salesitem.ECM_Sales_Driver__r.Name+'|'+salesitem.ECM_Range__c;
            }
            
            salesdrivewrap.DriverRange =  Integer.valueof(salesitem.ECM_Range__c);
            salesdrivewrap.SalesDriver= salesitem.ECM_Sales_Driver__c;
            salesdrivewrap.DriverName=salesitem.ECM_Sales_Driver_Name__c;
            returnwrapperLists.add(salesdrivewrap);   
        }
        
        return returnwrapperLists;
    } 
    //@AuraEnabled
    public static list<objectWrapper>getContractOutlets(String contractId){
        list<objectWrapper>contractOutlets = new list<objectWrapper>();
        for(Outlet_Contract__c o : [Select id,Outlet__r.Name,Outlet__r.BillingCity,Outlet__r.BillingCountry,Outlet__c from Outlet_Contract__c where Contract__c=:contractId WITH SECURITY_ENFORCED]){
            objectWrapper wrap = new objectWrapper();
            wrap.Id = o.Outlet__c;
            wrap.customerName = o.Outlet__r.Name;
            wrap.customerCityStreetName = o.Outlet__r.Name + ' + '+ o.Outlet__r.BillingCity+ ' + '+o.Outlet__r.BillingCountry;
            contractOutlets.add(wrap);
        }
        return contractOutlets;
    }
    @AuraEnabled
    public static Pick_Up_Options__c get_default_Banner_AU(){
        Id bannerRecordtypeId = Schema.Sobjecttype.Pick_Up_Options__c.getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        ECM_Set_Default_values_for_AU_Channel__mdt defaultvalue=[SELECT MasterLabel, ECM_Banner__c from ECM_Set_Default_values_for_AU_Channel__mdt where MasterLabel=:'Banner' WITH SECURITY_ENFORCED];
        Pick_Up_Options__c bannerrecord = [select id,Name from Pick_Up_Options__c where Name=:defaultvalue.ECM_Banner__c and recordtypeid=:bannerRecordtypeId WITH SECURITY_ENFORCED];
        return bannerrecord;
    }
    
    public class AccountWrapperList{
        @AuraEnabled
        public Integer totalRecords = 0;
        @AuraEnabled
        public list<objectWrapper> accountsList = new list<objectWrapper>();
        @AuraEnabled
        public List<objectWrapper> fullAccountsList = new List<objectWrapper>();
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Boolean success;
    }
    // wrapper class
    public class ObjectWrapper{
        @AuraEnabled
        public string Id {get;set;}
        @AuraEnabled
        public string customerName{get;set;}
        @AuraEnabled
        public string customerCityStreetName{get;set;}
        @AuraEnabled
        public decimal Upfront{get;set;}
        @AuraEnabled
        public Account acc{get;set;}
        
    }
    public class DiscountWrapper{
        @AuraEnabled public Discountrecord discountlist{get;set;}
        
    }
    public class Discountrecord{
        @AuraEnabled public Pick_Up_Options__c pickuprecord{get;set;}
        @AuraEnabled public string nameofdiscount{get;set;}
    }
    public class AccountWrapper{
        @AuraEnabled public List<Account> personResponsible{get;set;}
        @AuraEnabled public Account acc{get;set;}
    }
    public class LightningTableWrapper {  
        @AuraEnabled public List<ObjValues> tablerows {get; set;}
        public lightningTableWrapper(){           
            tablerows = new List<ObjValues>();
        }
    }	
    public class ObjValues{
        //@AuraEnabled public list<string> contHeader { get;set; }
        @AuraEnabled public string header{get; set;}
        @AuraEnabled public string values{get; set;}
    }
    public class Contractwithcontractitems{
        @AuraEnabled public list<ECM_Product_Agreement__c> productAgrements{get;set;}
        @AuraEnabled public contract con{get;set;}
        @AuraEnabled public list<Discountrecord> discountrecords{get;set;}
        @AuraEnabled public Pick_Up_Options__c bannerrecord{get;set;}
        @AuraEnabled public list<ECM_Contract_Item__c> ContractItems{get;set;}
        @AuraEnabled public list<objectWrapper> outletContracts{get;set;}
        @AuraEnabled public ECM_Addendum__c addendum{get;set;}
    }
    //Start- Added for ECM-4077
    public class UserAndContractInfo{
        @AuraEnabled public contractwithcontractitems contractInfo{get;set;}
        @AuraEnabled public user userinfo{get;set;}
        @AuraEnabled public List<GraphPercentValWrapper> graphPerctWrapper{get;set;}
    }
    //End- Added for ECM-4077
    public class ContractItemsandAgreementType{
        @AuraEnabled public list<contractitemswithBasevolandPGD> ContractItemwithVolumeAndPGD{get;set;}
        @AuraEnabled public ECM_Contract_Type__c AgreementType{get;set;}
        @AuraEnabled Public Contract pickuomvalue{get;set;}
        @AuraEnabled public Map <Id,String> conItmMap{get;set;} 
    }
    public class ContractitemswithBasevolandPGD{
        @AuraEnabled public ECM_Contract_Item__c ContractItem{get;set;}
        @AuraEnabled public String Basevolume{get;set;}
        @AuraEnabled public List<String> productGrowthDriverList{get;set;}
        @AuraEnabled public String firstProdDriver{get;set;}//ECM-6160
        //ECM-5790
        @AuraEnabled public Boolean toBeDisabled{get;set;}
        //CUS-123
        @AuraEnabled public List<String> legalCompliancePGD{get;set;}
    }
    public class Salesdriveritemswithbudjet{
        @AuraEnabled public ECM_Contract_Item__c ContractItem{get;set;}
        @AuraEnabled public decimal AandP{get;set;}
        @AuraEnabled public decimal TI{get;set;}
    }
    public class SalesdriverswithAgreementType{
        @AuraEnabled public List<ECM_Sales_Agreement__c> salesAgreementList{get;set;}
        @AuraEnabled public ECM_Contract_Type__c selectedAgreementType{get;set;}
        @AuraEnabled public RecordType recordType{get;set;}
        @AuraEnabled public string ActivationRecordTypeID{get;set;} 
        @AuraEnabled public string InvestmentRecordTypeID{get;set;} 
    } 
    public class Salesdriveritems{
        @AuraEnabled public string Drivername{get;set;}  
        @AuraEnabled public integer DriverRange{get;set;}
        @AuraEnabled public string SalesDriver{get;set;} 
        @AuraEnabled public string DriverType{get;set;}
        @AuraEnabled public string Id{get;set;}
        @AuraEnabled public string Name{get;set;} 
        @AuraEnabled public boolean applied{get;set;}
        @AuraEnabled public string BudjectType{get;set;}
        @AuraEnabled public boolean MultiUse{get;set;}
        @AuraEnabled public boolean AutomaticAmountSplit{get;set;}
        @AuraEnabled public string activationSpendId{get;set;} //Added for ECM-5439
        @AuraEnabled public boolean HideTotalAmount{get;set;} //Added for ECM-6432
        @AuraEnabled public string productSubCategory{get;set;}//CUS-123
        @AuraEnabled public string productFilter{get;set;}//155930
    }
    public class SalesdriverItemWrap{
        @AuraEnabled public ECM_Sales_Driver_Item__c salesDriver{get;set;}
        @AuraEnabled public string paymentId{get;set;}
        @AuraEnabled public list<salesdriverItemDetailsWrap> saledriveItemDetailsWrapList{get;set;}
        @AuraEnabled public salesdriveritems saledrive{get;set;} 
        @AuraEnabled public Decimal totalInvest{get;set;} 
        @AuraEnabled public DateTime createdtime{get;set;}
        //155930
        @AuraEnabled public List<String> yearLst{get;set;}
        
        public salesdriverItemWrap(){
            saledrive = new salesdriveritems();
            paymentId = '';
            salesDriver = new ECM_Sales_Driver_Item__c();
            saledriveItemDetailsWrapList = new list<salesdriverItemDetailsWrap>();
            totalInvest = 0;
        }
    }
    public class SalesdriverItemDetailsWrap{
        @AuraEnabled public ECM_Contract_Item__c productname{get;set;}
        @AuraEnabled public decimal investment{get;set;}
        @AuraEnabled public boolean selectedProductcheck{get;set;}
        //@AuraEnabled public Pick_Up_Options__c mustDoRecord{get;set;}
        //@AuraEnabled public Pick_Up_Options__c activationSpendSubGroup{get;set;}
        //@AuraEnabled public SObject testRecord{get;set;}
        //Added for ECM-5439->start
        @AuraEnabled public selectedRecordActivationSpend mustDoRecord{get;set;}
        @AuraEnabled public selectedRecordActivationSpend activationSpendSubGroup{get;set;}
        @AuraEnabled public string monthSDID{get;set;}
        @AuraEnabled public string yearSDID{get;set;}
        @AuraEnabled public string activationTypeDesc{get;set;}
        @AuraEnabled public List<String> yearLst{get;set;}
        @AuraEnabled public boolean toBeDisabled{get;set;}
        //ECM-5864
        @AuraEnabled public Boolean hasAddendum{get;set;}
        @AuraEnabled public String hasAddendumId{get;set;}
        @AuraEnabled public String addendumStatus{get;set;}
        //Added for ECM-5439->End
        @AuraEnabled public ECM_Sales_Driver_Item_Detail__c salesDriverDetails{get;set;}
        public salesdriverItemDetailsWrap(){
            mustDoRecord = new selectedRecordActivationSpend();
            activationSpendSubGroup = new selectedRecordActivationSpend();
            
        }
        
    }
    //Added for ECM-5439
    public class SelectedRecordActivationSpend{
        @AuraEnabled public string Id{get;set;}
        @AuraEnabled public string Name{get;set;} 
    }
    /*
* Name : calculateMapValues (ECM-4398)
* @description : This method is used to calculate graph values for NSV,GP and GM
* @return : List<GraphPercentValWrapper>
* @param : Map of Pickup option and ContractItem
*/
    public static List<GraphPercentValWrapper> calculateMapValues(Map<String,List<ECM_Contract_Item__c>> pkupOptnConItemMap){
        Map<String, GraphValWrapper> allGraphValMap = new Map<String, GraphValWrapper>();
        List<GraphPercentValWrapper> allGraphValFinalMap = new List<GraphPercentValWrapper>();
        Decimal sumOfAllNSV = 0;
        Decimal sumOfAllGP = 0;
        Decimal sumOfAllGM = 0;
        for(String optnName : pkupOptnConItemMap.keySet()){
            Decimal nsvVal = 0;
            Decimal gpVal = 0;
            Decimal gmVal = 0;
            for(ECM_Contract_Item__c conItem : pkupOptnConItemMap.get(optnName)){
                Decimal nsvLocalVal = conItem.ECM_NSV__c == null? 0: conItem.ECM_NSV__c;
                Decimal gpLocalVal = conItem.ECM_Gross_Profit__c == null? 0:conItem.ECM_Gross_Profit__c;
                Decimal gmLocalVal = conItem.ECM_Gross_margin__c == null? 0:conItem.ECM_Gross_margin__c;
                nsvVal = nsvVal+nsvLocalVal;
                gpVal = gpVal+gpLocalVal;
                gmVal = gmVal+gmLocalVal;
                //Calculating all Sum val
                sumOfAllNSV = sumOfAllNSV+nsvLocalVal;
                sumOfAllGP = sumOfAllGP+gpLocalVal;
                sumOfAllGM = sumOfAllGM+gmLocalVal;
            }
            GraphValWrapper wrapperObj = new GraphValWrapper();
            wrapperObj.nsvVal = nsvVal;
            wrapperObj.gpVal = gpVal;
            wrapperObj.gmVal = gmVal;
            allGraphValMap.put(optnName,wrapperObj);
        }
        for(String strVal : allGraphValMap.keySet()){
            GraphValWrapper wrapperObj =  allGraphValMap.get(strVal);
            GraphPercentValWrapper percentWrapperobj = new GraphPercentValWrapper();
            percentWrapperobj.pkupOptnVal = strVal;
            percentWrapperobj.nsvPercentVal = sumOfAllNSV == 0 ? 0 : Math.abs(((wrapperObj.nsvVal/sumOfAllNSV)*100).setScale(2));
            percentWrapperobj.gpPercentVal = sumOfAllGP == 0 ? 0 :Math.abs(((wrapperObj.gpVal/sumOfAllGP)*100).setScale(2));
            percentWrapperobj.gmPercentVal = sumOfAllGM == 0 ? 0 : Math.abs(((wrapperObj.gmVal/sumOfAllGM)*100).setScale(2));
            allGraphValFinalMap.add(percentWrapperobj);
        }
        return allGraphValFinalMap;
    }
    //This wrapper is used to calculated values for different Pickup Option
    public class GraphValWrapper{
        @AuraEnabled public Decimal nsvVal {get;set;}
        @AuraEnabled public Decimal gpVal {get;set;}
        @AuraEnabled public Decimal gmVal {get;set;}
    }
    //This wrapper is used to calculated % values for different Pickup Option
    public class GraphPercentValWrapper{
        @AuraEnabled public String pkupOptnVal {get;set;}
        @AuraEnabled public Decimal nsvPercentVal {get;set;}
        @AuraEnabled public Decimal gpPercentVal {get;set;}
        @AuraEnabled public Decimal gmPercentVal {get;set;}
    }
    /*
* Name : getTableDetails (ECM-4627)
* @description : This method is used to provide Screen 3 field visibility Logic _SFDC_Ireland MVP
* @return : getTableDetailsWrapper
* @param : Agreement Type Id
*/
    @AuraEnabled
    public static getTableDetailsWrapper getTableDetails(Id agreementTypeId){
        //Variables
        List<ECM_Contract_Type__c> agreementTypeList = new List<ECM_Contract_Type__c>();
        List<String> screen3DisplayValues = new List<String>();
        getTableDetailsWrapper wrapTableDetails = new getTableDetailsWrapper();
        wrapTableDetails.showProductName =  false;
        wrapTableDetails.showBrand =  false;
        wrapTableDetails.showCategory =  false; 
        wrapTableDetails.showBaseVolume =  false;
        wrapTableDetails.showBaseLineVolume =  false;
        wrapTableDetails.showVolumeTarget =  false;
        wrapTableDetails.showRatePerUom =  false;
        wrapTableDetails.showTiering =  false;
        wrapTableDetails.showInvest =  false; 
        wrapTableDetails.showProductGrowthDriver =  false;
        wrapTableDetails.showProductUoM =  false;//ECM-5924
        agreementTypeList  = [SELECT Id,ECM_Category_Contracts__c,ECM_Screen_3_field_configuration__c FROM ECM_Contract_Type__c WHERE Id =:agreementTypeId WITH SECURITY_ENFORCED];
        screen3DisplayValues = agreementTypeList[0].ECM_Screen_3_field_configuration__c.split(';') ;
        if(!screen3DisplayValues.isEmpty()){
            for(String strVal : screen3DisplayValues){
                if(strVal.equalsIgnoreCase('Product Name')){
                    wrapTableDetails.showProductName = true; 
                }else if(strVal.equalsIgnoreCase('Brand')){
                    wrapTableDetails.showBrand = true; 
                }else if(strVal.equalsIgnoreCase('Category')){
                    wrapTableDetails.showCategory = true; 
                }else if(strVal.equalsIgnoreCase('Base volume')){
                    wrapTableDetails.showBaseVolume = true; 
                }else if(strVal.equalsIgnoreCase('Baseline volume')){
                    wrapTableDetails.showBaseLineVolume = true; 
                }else if(strVal.equalsIgnoreCase('Volume target')){
                    wrapTableDetails.showVolumeTarget = true; 
                }else if(strVal.equalsIgnoreCase('Rate per UoM')){
                    wrapTableDetails.showRatePerUom = true; 
                }else if(strVal.equalsIgnoreCase('Tiering')){
                    wrapTableDetails.showTiering = true; 
                }else if(strVal.equalsIgnoreCase('Investment')){
                    wrapTableDetails.showInvest = true; 
                }else if(strVal.equalsIgnoreCase('Product growth strategy')){
                    wrapTableDetails.showProductGrowthDriver = true; 
                }else if(strVal.equalsIgnoreCase('UoM')){//ECM-5924
                    wrapTableDetails.showProductUoM = true; 
                }
                
            }
        }
        System.debug(LoggingLevel.DEBUG,'wrapTableDetails'+wrapTableDetails);
        return wrapTableDetails;
    }
    //This wrapper is used to send the visible 
    //field details to Aura component
    public class GetTableDetailsWrapper{
        @AuraEnabled public Boolean showProductName {get;set;}
        @AuraEnabled public Boolean showBrand {get;set;}
        @AuraEnabled public Boolean showCategory {get;set;} 
        @AuraEnabled public Boolean showBaseVolume {get;set;}
        @AuraEnabled public Boolean showBaseLineVolume {get;set;}
        @AuraEnabled public Boolean showVolumeTarget {get;set;}
        @AuraEnabled public Boolean showRatePerUom {get;set;}
        @AuraEnabled public Boolean showTiering {get;set;}
        @AuraEnabled public Boolean showInvest {get;set;} 
        @AuraEnabled public Boolean showProductGrowthDriver {get;set;}
        @AuraEnabled public Boolean showProductUoM {get;set;}//ECM-5924 
    }
    /*
* Name : getDefPaymentFreqAndBudgeting (ECM-4691 && ECM-4817)
* @description : This method is used to get Default Payment Frequency and Sales Driver Budgeting
* @return : ECM_Contract_Type__c
* @param : Agreement Type Id
*/
    @AuraEnabled
    public static ECM_Contract_Type__c getDefPaymentFreqAndBudgeting(String agreementId){
        //Boolean isDefltPSEnable = false;
        if(String.isNotBlank(agreementId)){
            List<ECM_Contract_Type__c> agremntList = [SELECT Id, Enable_Default_Payment_Frequency__c,ECM_Sales_Driver_Budgeting__c,
                                                      ECM_Hide_Information_Section__c
                                                      FROM ECM_Contract_Type__c
                                                      WHERE Id =: agreementId WITH SECURITY_ENFORCED];
            if(agremntList != null && !agremntList.isEmpty()){
                //isDefltPSEnable = agremntList[0].Enable_Default_Payment_Frequency__c;
                return agremntList[0];
                
                
                
            }
        }
        return null;
    }
    
    public class ProductDetailsWrapper{
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String ProductName {get;set;}
        @AuraEnabled public Decimal setInvestmentAmount {get;set;} 
        @AuraEnabled public Decimal investmentRunning {get;set;} 
        @AuraEnabled public boolean editable {get;set;}
        @AuraEnabled public String alignment {get;set;}
        @AuraEnabled public String isError {get;set;}
    }
    /*
* Name : getproductData ( ECM-4817)
* @description : This method is used to get the product details from the contract Item and Sales Driver item
* @return : List<productDetailsWrapper>
* @param : Contract Id
*/
    @Auraenabled
    public static List<productDetailsWrapper> getproductData(Id contractId){
        List<productDetailsWrapper>productDetailsWrapperList= new List<productDetailsWrapper>();
        List<ECM_Contract_Item__c>contractitemlist=[select id,ECM_Product__c,ECM_Product__r.Product__r.name,ECM_Set_Sales_Driver_Investment__c,
                                                    (select id,ECM_Investment_Amount__c from Sales_Driver_Item_Details__r) 
                                                    from ECM_Contract_Item__c 
                                                    where ECM_Contract__c=:contractId WITH SECURITY_ENFORCED];
        if(!contractitemlist.isempty()){
            decimal totalInvestmentamount;
            decimal totalInvestmentrunning;
            
            for(ECM_Contract_Item__c contractItem:contractitemlist){
                /*if(contractItem.ECM_Set_Sales_Driver_Investment__c==null){
//contractItem.ECM_Set_Sales_Driver_Investment__c=0;
}*/
                productDetailsWrapper pWrap= new productDetailsWrapper();
                pWrap.Id=contractItem.Id;
                pWrap.ProductName=contractItem.ECM_Product__r.Product__r.name;
                pWrap.setInvestmentAmount=contractItem.ECM_Set_Sales_Driver_Investment__c;
                //pWrap.investmentRunning=0;
                pWrap.editable=true;
                pWrap.alignment='left';
                if(contractItem.ECM_Set_Sales_Driver_Investment__c!=null){
                    if(totalInvestmentamount==null){
                        totalInvestmentamount=0;
                    }
                    totalInvestmentamount=totalInvestmentamount+contractItem.ECM_Set_Sales_Driver_Investment__c;
                }
                for(ECM_Sales_Driver_Item_Detail__c sdItem:contractItem.Sales_Driver_Item_Details__r){
                    if(sdItem.ECM_Investment_Amount__c!=null){
                        // sdItem.ECM_Investment_Amount__c=0;
                        if(pWrap.investmentRunning==null){
                            pWrap.investmentRunning=0;
                        }
                        if(totalInvestmentrunning==null){
                            totalInvestmentrunning=0;
                        }
                        pWrap.investmentRunning=pWrap.investmentRunning+sdItem.ECM_Investment_Amount__c;
                        
                        totalInvestmentrunning=totalInvestmentrunning+sdItem.ECM_Investment_Amount__c;
                    }
                }
                if(pWrap.investmentRunning!=null && pWrap.setInvestmentAmount<pWrap.investmentRunning || pWrap.setInvestmentAmount>pWrap.investmentRunning){
                    pWrap.isError='errorCell';
                }else if(pWrap.investmentRunning!=null && pWrap.setInvestmentAmount==pWrap.investmentRunning){
                    pWrap.isError='validCell';     
                }
                productDetailsWrapperList.add(pWrap);
            }
            productDetailsWrapper pWrap= new productDetailsWrapper();
            pWrap.Id=system.label.ECM_Totals;
            pWrap.ProductName=system.label.ECM_Totals;
            pWrap.setInvestmentAmount=totalInvestmentamount;
            pWrap.investmentRunning=totalInvestmentrunning;
            pWrap.editable=false;
            pWrap.alignment='left';
            productDetailsWrapperList.add(pWrap);
            return productDetailsWrapperList;
        }
        return null;
    }
    
    /*
* Name : saveInvestmentAmount ( ECM-4817)
* @description : This method is used to save the set investment amount to the contract Item 
* @param : Json of contract item details
*/
    @AuraEnabled
    public static void saveInvestmentAmount(String contractItemLst){
        
        List<ECM_Contract_Item__c>conItemlist= new List<ECM_Contract_Item__c>();
        //List<productDetailsWrapper>productDetailsWrapperList= new List<productDetailsWrapper>();
        for( productDetailsWrapper wrapper:(List<productDetailsWrapper>)System.JSON.deserialize(contractItemLst, List<productDetailsWrapper>.class)){
            ECM_Contract_Item__c conItem= new ECM_Contract_Item__c(Id=wrapper.Id,ECM_Set_Sales_Driver_Investment__c=wrapper.setInvestmentAmount);
            conItemlist.add(conItem);
        }
        if(!conItemlist.isEmpty() && Schema.sObjectType.ECM_Contract_Item__c.isUpdateable()){
            database.update(conItemlist);
        } 
    }
    /*
* @description : Notification for Contract Approval_SFDC_Approval request for sales manager (ECM-5585)
* @return : void
* @param : Approval Log Id
*/
    @future
    public static void sendPushNotificationForApprovalLog(Id approvalLogId,Id salesManagerId){
        try{
            Map<String, Object> custom = new Map<String, Object>(); 
            ECM_Approval_Log__c approvalLog = [SELECT Id,Name,ECM_Contract__c,ECM_Contract__r.ContractNumber, 
                                               ECM_Contract__r.OwnerId, ECM_Contract__r.Account.RecordType.Name, 
                                               ECM_Contract__r.Account.Name
                                               FROM ECM_Approval_Log__c where Id=:approvalLogId WITH SECURITY_ENFORCED];
            List<String> accountType = approvalLog.ECM_Contract__r.Account.RecordType.Name.split('/');
            String notificationText = Label.ECM_ApprovalLogPushNotificationMsg.replace('****',approvalLog.ECM_Contract__r.ContractNumber).replace('&&&&',accountType[accountType.size()-1]).replace('####',approvalLog.ECM_Contract__r.Account.Name);
            
            custom.put('ApprovalLogId',approvalLog.Id);
            custom.put('ContractId',approvalLog.ECM_Contract__c);
            custom.put('OwnerId',salesManagerId);
            
            EDGE_PushNotificationHelper.pushNotificationMethod(null, notificationText, custom);
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception Caught in sendPushNotificationForApprovalLog method of ECM_CreateContractController at Line: '+ex.getLineNumber()+'\n Error: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG,'Exception : '+ex);
        }
    }
    @AuraEnabled
    public static ASTableDetailWrapper getASTableConfiguration(String agmntId ){
        //String agmntId = 'a3G1l000001LfJJEA0';
        if(String.isNotBlank(agmntId)){
            system.debug(LoggingLevel.DEBUG,'@@agmntId' +agmntId);
            List<ECM_Contract_Type__c> agreementList = new List<ECM_Contract_Type__c>();
            agreementList = [SELECT Id,ECM_Activation_Spend_Table_Configuration__c 
                             FROM ECM_Contract_Type__c
                             WHERE Id =: agmntId WITH SECURITY_ENFORCED];
            ASTableDetailWrapper wrapObj = new ASTableDetailWrapper(); 
            wrapObj.asSubGroup = agreementList[0].ECM_Activation_Spend_Table_Configuration__c.contains('Activation Spend Sub Group')?true:false;         
            wrapObj.actvDescription = agreementList[0].ECM_Activation_Spend_Table_Configuration__c.contains('Activity Type Description')?true:false; 
            wrapObj.deliveryDate = agreementList[0].ECM_Activation_Spend_Table_Configuration__c.contains('Delivery Date')?true:false; 
            wrapObj.mustDo = agreementList[0].ECM_Activation_Spend_Table_Configuration__c.contains('Must Do')?true:false; 
            wrapObj.investment = true;
            wrapObj.prodName = true;
            return wrapObj;              
        }
        return null;
    }
    
    public class ASTableDetailWrapper{
        @AuraEnabled public Boolean asSubGroup {get;set;}
        @AuraEnabled public Boolean actvDescription {get;set;}
        @AuraEnabled public Boolean deliveryDate {get;set;}
        @AuraEnabled public Boolean investment {get;set;}
        @AuraEnabled public Boolean mustDo {get;set;}
        @AuraEnabled public Boolean prodName {get;set;}
    }
    @AuraEnabled
    public static list<Pick_Up_Options__c> getASSubGroup(){
        list<Pick_Up_Options__c> getASSubGroup = new list<Pick_Up_Options__c>();
        if(!Test.isRunningTest()){
            getASSubGroup = [SELECT Id,Name FROM Pick_Up_Options__c 
                             WHERE Recordtype.name ='Activation Spend Sub-Group' WITH SECURITY_ENFORCED];
        }
        return getASSubGroup;
    }
    /*
* @description : Returns the fiscal years between the contract start and end date (ECM-5452)
* @return : List<String>
* @param : Contract record
*/
    @AuraEnabled
    public static list<String> fiscalYearCalculate(Contract contr){
        String fyYear;
        List<String> fiscalYearLst = new List<String>();        
        try{
            if(contr.StartDate!=null && contr.Contract_End_Date__c!=null){
                Date startDate = contr.StartDate;
                Date endDate = contr.Contract_End_Date__c;
                Integer startDateMonth = startDate.month();
                Integer endDateMonth = endDate.month();
                Integer startDateYear = startDate.year();
                Integer endDateYear = endDate.year();
                String fiscalYear = '';
                for(integer i=startDateYear; i<= endDateYear; i++){
                    integer dateYear = i;
                    if(i==startDateYear){
                        if(startDateMonth<7){
                            fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        }
                    }
                    if(i==endDateYear){
                        if(startDateYear == endDateYear){
                            if(startDateMonth<7 && endDateMonth >= 7){
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth >= 7){
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                        else if(startDateYear+1 == endDateYear){
                            if(startDateMonth < 7 && endDateMonth < 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth < 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth < 7 && endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                        else{
                            if(endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            else{
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                    }
                    if(i != startDateYear && i != endDateYear){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
                
                fyYear = fiscalYear.removeEndIgnoreCase('/');
                fiscalYearLst = fyYear.split('/');                
            }            
        }catch(Exception e){
            System.debug(LoggingLevel.DEBUG,'Exception Caught in fiscalYearCalculate method of ECM_CreateContractController at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
        return fiscalYearLst;
    }
    
    @AuraEnabled
    public static List<Supplier_Outlet__c> getSupplierOutlets(String accId)
    {
        try{
            List<Supplier_Outlet__c> returnList = [Select Id,Name,Distributor_Wholesaler__c,Distributor_Wholesaler__r.Name 
                                                   from Supplier_Outlet__c 
                                                   where outlet__c = :accId WITH SECURITY_ENFORCED];
            if(!returnList.isEmpty()){
                return returnList;
            }
            
        }
        catch(exception e){
            system.debug(LoggingLevel.DEBUG,'error'+e.getMessage());
        }
        return null;
        
    }
    @AuraEnabled
    public static Market_Setting__c getAttributes(String accId)
    {
        Set<Id> geoCountry = new Set<Id>();
        try{
            //List<Supplier_Outlet__c> returnList = [Select Id,Name,Distributor_Wholesaler__c,Distributor_Wholesaler__r.Name from Supplier_Outlet__c where outlet__c = :accId ];
            Account accObj;
            accObj= [Select Id,Name,Country__r.Name from Account where id=:accId WITH SECURITY_ENFORCED];
            if(accObj != null){
                geoCountry.add(accObj.Country__c);
                Market_Setting__c marketObj = [select id,ECM_Attribute_Visibility_Screen1__c 
                                               from Market_Setting__c 
                                               where Geography__c IN : geoCountry WITH SECURITY_ENFORCED];  
                return marketObj;
            }
        }
        catch(exception e){
            system.debug(LoggingLevel.DEBUG,'error'+e.getMessage());
        }
        return null;
    }
    /*
* @Jira Key	: CUS-173
* @description : This method is to structure outlet taps info based on contract's Record type and market
* @return		: List<OutletTapsTableWrapper>
* params		: String
*/
    @AuraEnabled
    public static List<Outlet_Contract__c> getOutletTapsTable(Contract conRec){
        List<Outlet_Contract__c> outletConList = new List<Outlet_Contract__c>();
        
        if(conRec.ECM_Agreement_Type__r.ECM_of_Outlets_Tap_Space_Required__c != Null &&
           System.Label.ECM_OutletTapsTable_CountryCode.split(';').contains(conRec.Account.Country_Code__c)){
               outletConList =  [SELECT Id,Name,Outlet__c,Outlet__r.Name,ECM_Total_Outlet_Taps__c,
                                 ECM_No_of_Taps_Diageo_will_Invest__c,Contract__c,
                                 ECM_of_Taps_Diageo_will_invest__c
                                 FROM Outlet_Contract__c 
                                 WHERE Contract__c =:conRec.Id WITH SECURITY_ENFORCED];
           }
        return outletConList;
    }
    //END of CUS-173
    /*
* @Jira Key	: 152811
* @description : This method is to fetch the Content Version Id based on the Market Setting and Record Type Id
* @return		: ID
* params		: String
*/
@AuraEnabled(cacheable=true)
    public static String getPDFGuide(String recID,String marID) 
    {

        List<RecordType> recordTypeList=[Select Name from RecordType where Id=:recID and SobjectType='Contract'  WITH SECURITY_ENFORCED Limit 1];
        String recordTypeName=recordTypeList[0].Name;
        String output=System.Label.ECM_Warning_Message_For_No_PDF;
        String contracts=System.Label.ECM_CVContractsRecType;
        String pdf=System.Label.ECMContentVersionFileTypePDF;
        List<ContentDocumentLink> contentDocumentLinkList = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:marID AND ContentDocument.LatestPublishedVersion.RecordType.Name=:contracts
                                                             AND ContentDocument.LatestPublishedVersion.Content_Type__c=:recordTypeName AND ContentDocument.LatestPublishedVersion.FileType=:pdf WITH SECURITY_ENFORCED
                                                             ORDER BY ContentDocument.LatestPublishedVersion.LastModifiedDate DESC LIMIT 1];//We get the PDF File with the LatestVersion
        if(!contentDocumentLinkList.isEmpty()){
            output = contentDocumentLinkList[0].ContentDocumentId;
            
        }
        /*Set<Id> contentDocumentIDSet=new Set<Id>();
        if(contentDocumentIDs!=null && contentDocumentIDs.size()>0)
        {
           for(ContentDocumentLink contentDocumentID:contentDocumentIDs)
           {
            contentDocumentIDSet.add(contentDocumentID.ContentDocumentId);
           }
           
           Map<String,Id> recordTypeContentDocumentMap=new Map<String,Id>();
           List<ContentVersion> contentVersion =[Select Id,ContentDocumentId,Content_Type__c from ContentVersion where ContentDocumentId in:contentDocumentIDSet and RecordType.Name='Contracts' and Content_Type__c=:recordTypeName WITH SECURITY_ENFORCED  ORDER BY CreatedDate DESC Limit 1];
           if(contentVersion!=null && contentVersion.size()>0)
           {
                output=contentVersion[0].ContentDocumentId;              
           }     
        }*/
        System.debug(LoggingLevel.Debug,'Value of output '+output);
        return output;
    }
}