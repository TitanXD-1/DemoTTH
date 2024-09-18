/*
* Class Name: CRG_GetContractDetailsController
* Test Class: CRG_GetContractDetailsControllerTest
* Author: 
* Brief Description: This class is to fetch details used in Email for VF components.
* Created Date: 05/02/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0			Saurav Prasad		05/02/2024			Initial Development : 148916 - CRG: Contract Approval email template_SFDC
*/
public with sharing class CRG_GetContractDetailsController {
    public ID targetObjectId { get; set; }    
    public list<string> contHeader { get;set; }
    
    public List<lightningTableWrapper> getContHeaderDetails()
    {
        
        List<lightningTableWrapper> listLgtnTableWraps = new List<lightningTableWrapper>();
        Contract contObj = new Contract();
        try{
            contObj = [SELECT Id, Name, ContractNumber, Account.Name, ECM_Duration__c, Createdby.Name, ECM_Agreement_Type__r.Name, 
                       StartDate, LastModifiedBy.Name, AccountId, Status, OwnerId, RecordTypeId, RecordType.Name, ECM_Overall_Investment_Figure__c, 
                       ECM_Agreement_Type__c, CRG_Refrigeration_Contractor__c, CRG_Outlet_Trade_Affiliation__c, CRG_Type_of_Equipment__c, 
                       CRG_Equipment_Status__c, CRG_Power_provided_for_Surge_20X__c, CRG_Water_provided_for_Surge_20X__c, CRG_Installation_Date__c,
                       CRG_Total_Number_of_Diageo_Taps__c, CRG_Total_Number_of_Brands_in_Outlet__c, CRG_Total_Number_of_Diageo_Brands__c,
                       CRG_Total_Cost_of_Refrigeration_ex_Vat__c, CRG_Total_Investment__c, CRG_Payment_Method__c, CRG_Payment_Frequency__c,
                       CRG_Notes_Comments__c, CRG_Contract_Type__c,ECM_Contract_Owner__c, Account.ECM_Legal_Name__c,Contract_End_Date__c,
                       Account.SAP_Ship_to__c,Account.SAP_Sold_to__c
                       FROM Contract WHERE Id=: targetObjectId WITH SECURITY_ENFORCED ];
            
            System.debug(LOGGINGLEVEL.DEBUG,'contObj @'+contObj);
            
            Map<String, String> labelToApiMap = new Map<String, String>{
                'Contract created by'=>'ECM_Contract_Owner__c',
                    'Customer name'=>'Account.ECM_Legal_Name__c',
                    'Outlet name'=>'Account.Name',
                    'Agreement type'=>'ECM_Agreement_Type__r.Name',
                    'Start date'=>'StartDate',
                    'End date'=>'Contract_End_Date__c',
                    'Contract number'=>'ContractNumber',
                    'Contract Name'=>'Name',
                    'SAP Ship to'=>'Account.SAP_Ship_to__c',
                    'SAP Sold to'=>'Account.SAP_Sold_to__c',
                    'Refrigeration Contractor'=>'CRG_Refrigeration_Contractor__c',
                    'Outlet Trade Affiliation'=>'CRG_Outlet_Trade_Affiliation__c',
                    'Type of Equipment'=>'CRG_Type_of_Equipment__c',
                    'Equipment Status'=>'CRG_Equipment_Status__c',
                    'Power provided for Surge 20X'=>'CRG_Power_provided_for_Surge_20X__c',
                    'Water provided for Surge 20X'=>'CRG_Water_provided_for_Surge_20X__c',
                    'Installation Date'=>'CRG_Installation_Date__c',
                    'Total Number of Diageo Taps'=>'CRG_Total_Number_of_Diageo_Taps__c',
                    'Total Number of Brands in Outlet'=>'CRG_Total_Number_of_Brands_in_Outlet__c',
                    'Total Number of Diageo Brands'=>'CRG_Total_Number_of_Diageo_Brands__c',
                    'Total Cost of Refrigeration (ex Vat)'=>'CRG_Total_Cost_of_Refrigeration_ex_Vat__c',
                    'Diageo Investment (euros)'=>'CRG_Total_Investment__c',
                    'Payment Method'=>'CRG_Payment_Method__c',
                    'Payment Frequency'=>'CRG_Payment_Frequency__c',
                    'Notes/Comments'=>'CRG_Notes_Comments__c'
                    };
                        
                        
                        lightningTableWrapper ltw = new lightningTableWrapper();
            List<ObjValues> objvalList = new List<ObjValues>();
            
            for(string labelName: labelToApiMap.keySet()){
                
                ObjValues objval = new ObjValues();
                objval.header = labelName;
                String tempKey = labelToApiMap.get(labelName);
                System.debug(LOGGINGLEVEL.INFO,'Key @'+tempKey);
                switch on tempKey {
                    when 'Account.ECM_Legal_Name__c' {
                        objval.values = contObj.Account.ECM_Legal_Name__c;
                    }
                    when 'Account.Name'{
                        objval.values = contObj.Account.Name;
                    }
                    when 'ECM_Agreement_Type__r.Name'{
                        objval.values = contObj.ECM_Agreement_Type__r.Name;                   
                    }
                    when 'Account.SAP_Ship_to__c'{
                        objval.values = contObj.Account.SAP_Ship_to__c;
                    }
                    when 'Account.SAP_Sold_to__c'{
                        objval.values = contObj.Account.SAP_Sold_to__c;
                    }
                    when 'CRG_Power_provided_for_Surge_20X__c','CRG_Water_provided_for_Surge_20X__c'{
                        objval.values = Boolean.valueOf(contObj.get(tempKey))?'Yes':'No';
                    }
                    when 'StartDate','Contract_End_Date__c','CRG_Installation_Date__c'{
                        //String tempString = ;
                        Date tempDate = Date.valueOf(contObj.get(tempKey));
                        objval.values = contObj.get(tempKey)!=null?tempDate.format():'';
                    }
                    when else {
                        objval.values = String.valueof(contObj.get(tempKey)!=null?contObj.get(tempKey):''); 
                    }
                }
                
                objvalList.add(objval);
                
            }
            System.debug(LOGGINGLEVEL.DEBUG,'objvalList @'+objvalList);
            ltw.tablerows = objvalList;
            listLgtnTableWraps.add(ltw);
            contHeader = new List<String>(labelToApiMap.keySet());
            
        } 
        catch (Exception contractException) {
            System.debug(LOGGINGLEVEL.DEBUG,'Class:CRG_GetContractDetailsController\nmethod:getContHeaderDetails\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
            
        }
        return listLgtnTableWraps;
        
    }
    
    public class LightningTableWrapper {  
        public List<ObjValues> tablerows {get; set;}
        public lightningTableWrapper(){           
            tablerows = new List<ObjValues>();
        }
    }	
    
    public class ObjValues{
        public string header{get; set;}
        public string values{get; set;}
    }
}