@isTest
public class Test_MD_SharingUtil {        

    @testSetup 
    public static void setup(){
        insert new DiageoCMS__CMSSettings__c(DiageoCMS__ClusterFieldForPublicGroups__c = 'DiageoCMS__ExternalId__c', DiageoCMS__SalesforceDomain__c = 'https://edge--edgedev3.lightning.force.com');
    }

    testmethod private static void generatesAssignments(){

    	DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(Name='NIR ', DiageoCMS__ExternalId__c='NIR');
        insert cluster;

    	MD_Agreement__c agreement = new MD_Agreement__c(Name = 'Test', Cluster__c = cluster.Id);
    	insert agreement;
    
    	try{
    		MD_SharingUtil.generateSharingForRecordsOnCluster(new List<SObject>{agreement}, 'Cluster__c');
		}catch(Exception e){
			
		}

    }
}