/*
 * Class Name : EDGE_CSTClaimItemTriggerHelper
 * @description: This is CLaim Item Trigger Helper
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team  		19/05/2021        Initial Development
*/


public with sharing class EDGE_CSTClaimItemTriggerHelper {
    
    /*
	* @description : Filling Tax rate and Currency based on Claim 
	* @return : void
	* @param : List CST_Claim_Item__c
	*/   
   public static void updateCurrencyFromClaim(List <CST_Claim_Item__c> newItems) {
        Set<Id> claimIdSet = new Set<Id>(); 
		List<double> clmTaxRate = new List<double>();	
		Map<string,List<Pick_Up_Options__c>> taxratetoPickUpOptn = new Map<string,List<Pick_Up_Options__c>> ();	
		string key ;		
		string claimItemtrueKey;
	    string claimItemfalseKey;
        Boolean taxCodeMandatory = false;

        List<String> lstOfSalesOrg = new List<String>();

        
        for(CST_Claim_Item__c claimItem : newItems){
            claimIdSet.add(claimItem.CST_Claim__c); 
			//clmTaxRate.add(claimItem.CST_Claim__r.Claim_Tax_Code__r.CST_Tax_Rate__c);			
        }        

		Map<Id,CST_Claim__c> mapOfClaim = new Map<Id,CST_Claim__c>([select id,CurrencyIsoCode,Claim_Tax_Code__r.CST_Tax_Rate__c,CST_Sales_Organisation__c,CST_Sales_Organisation__r.Tax_Code_Mandatory__c from CST_Claim__c where id =:claimIdSet]);

       	for(CST_Claim__c clmObj:mapOfClaim.values()){           
           clmTaxRate.add(clmObj.Claim_Tax_Code__r.CST_Tax_Rate__c);          
           lstOfSalesOrg.add(clmObj.CST_Sales_Organisation__c);
       	}								 
		for(Pick_Up_Options__c pickUpOptn:[Select id, CST_Default_record__c, CST_Tax_Rate__c, CST_Type__c, Sales_Organisation__c from Pick_Up_Options__c 
                                       where CST_Tax_Rate__c IN : clmTaxRate  and Sales_Organisation__c in: lstOfSalesOrg and  CST_Type__c != null and Type__c ='Tax Code']){
			key ='';
            key = pickUpOptn.Sales_Organisation__c +'_'+pickUpOptn.CST_Tax_Rate__c +'_'+pickUpOptn.CST_Type__c+'_'+pickUpOptn.CST_Default_record__c;

			if(taxratetoPickUpOptn.containsKey(key)){
				taxratetoPickUpOptn.get(key).add(pickUpOptn);
			} else{				    
				taxratetoPickUpOptn.put(key, new List<Pick_Up_Options__c>{pickUpOptn});
			} 
	    }       
		for(CST_Claim_Item__c clmItmObj : newItems){
            clmItmObj.CurrencyIsoCode = mapOfClaim.containsKey(clmItmObj.CST_Claim__c)?mapOfClaim.get(clmItmObj.CST_Claim__c).CurrencyIsoCode:null;  

            claimItemtrueKey = mapOfClaim.containskey(clmItmObj.CST_Claim__c)?mapOfClaim.get(clmItmObj.CST_Claim__c).CST_Sales_Organisation__c+'_'+mapOfClaim.get(clmItmObj.CST_Claim__c).Claim_Tax_Code__r.CST_Tax_Rate__c+'_'+clmItmObj.Type__c+'_true':null;
            claimItemfalseKey =mapOfClaim.containskey(clmItmObj.CST_Claim__c)?mapOfClaim.get(clmItmObj.CST_Claim__c).CST_Sales_Organisation__c+'_'+mapOfClaim.get(clmItmObj.CST_Claim__c).Claim_Tax_Code__r.CST_Tax_Rate__c+'_'+clmItmObj.Type__c+'_false':null;

			taxCodeMandatory = mapOfClaim.containskey(clmItmObj.CST_Claim__c)?mapOfClaim.get(clmItmObj.CST_Claim__c).CST_Sales_Organisation__r.Tax_Code_Mandatory__c:false;
            if(clmItmObj.CST_Tax_Code__c == null && taxratetoPickUpOptn.containskey(claimItemtrueKey) && taxratetoPickUpOptn.get(claimItemtrueKey).size()==1){
				clmItmObj.CST_Tax_Code__c = (taxratetoPickUpOptn.get(claimItemtrueKey))[0].id;                
			}
			else if(clmItmObj.CST_Tax_Code__c == null && !taxratetoPickUpOptn.containskey(claimItemtrueKey) && taxratetoPickUpOptn.containskey(claimItemfalseKey) && taxratetoPickUpOptn.get(claimItemfalseKey).size()==1){
				clmItmObj.CST_Tax_Code__c = (taxratetoPickUpOptn.get(claimItemfalseKey))[0].id;								
			}
			else if(clmItmObj.CST_Tax_Code__c == null && taxCodeMandatory){
				clmItmObj.addError('No Valid Tax Rate is available, Please Contact Administrator.');
			}
		
		}
    }
    
    
    /*
	* @description : deletiononOnApproveRejectStatus
	* @return : void
	* @param : List CST_Claim_Item__c
	*/  
    public static void deletiononOnApproveRejectStatus(List<CST_Claim_Item__c> oldItems)
    {
        Set<Id> claimIdSet = new Set<Id>(); 
        string claimStatus;
        for(CST_Claim_Item__c claimItem : oldItems){
            claimIdSet.add(claimItem.CST_Claim__c); 		
        } 
        Map<Id,CST_Claim__c> mapOfClaim = new Map<Id,CST_Claim__c>([select id,CST_Status__c from CST_Claim__c where id =:claimIdSet]);
        for(CST_Claim_Item__c clmItmObj : oldItems){
           claimStatus = mapOfClaim.containsKey(clmItmObj.CST_Claim__c)?mapOfClaim.get(clmItmObj.CST_Claim__c).CST_Status__c:null;  
            if(claimStatus == 'Approved' || claimStatus == 'Rejected'){
                 clmItmObj.addError('Cannot Delete ClaimItem when Claim Status is Approved/Rejected.');
              }  
        }
        
    }
    
}