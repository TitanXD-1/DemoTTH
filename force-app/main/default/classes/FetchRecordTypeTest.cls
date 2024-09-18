@isTest
public class FetchRecordTypeTest {

    @isTest
    public static void fetchrecordTypes(){
        List<RecordType> rtList = [SELECT id, Name FROM RecordType WHERE sObjectType = 'Product__c'];
        List<FetchRecordType.RecordTypeWrapper> rtWrapperList = FetchRecordType.getRecordTypeList('Product__c');
        
        String rtName, rtWrapperName;
        Id rtId, rtWrapperId;
        System.assertEquals(rtWrapperList.size(), rtList.size());
        for(RecordType rt : rtList){
            rtName = rt.Name;
            rtId = rt.Id;
            System.debug('rtName '  +rtName);
            for(FetchRecordType.RecordTypeWrapper rtwrapper : rtWrapperList){
                System.debug('rtWrapperName ' + rtwrapper.recordTypeName);
                if(rtName == rtwrapper.recordTypeName){
                    rtWrapperId = rtwrapper.recordTypeId;
                    break;
                }else{
                    rtWrapperId = null;
                }
            }
            System.assertEquals(rtId, rtWrapperId);
        }
    }
    
    @isTest
    public static void getCreatedRecordTest(){
        Account acc = new Account(Name = 'test Account 234');
        insert acc;

        System.assertEquals('test Account 234', FetchRecordType.getCreatedRecordName(String.valueOf(acc.Id), 'Account'));
    }

    
}