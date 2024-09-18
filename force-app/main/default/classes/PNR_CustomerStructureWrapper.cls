/**********************************************************************
Name: PNR_CustomerStructureWrapper
=======================================================================
Purpose: This Class is used to create wrapper Data
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      	Jyothsna Nagapudi 04/01/2019        Wrapper for Customer Structure
***********************************************************************/
public class PNR_CustomerStructureWrapper {
    
    @AuraEnabled
    public PNR_Partner_Function__c pFRecord;
    @AuraEnabled
    public Boolean isActive;
    public PNR_CustomerStructureWrapper (PNR_Partner_Function__c pFRecord,Boolean isActive){
        this.pFRecord = pFRecord;
        this.isActive = isActive;
        
    }
}